from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify, g
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
from datetime import datetime, date
import os
import json
import pymysql
import pymysql.cursors
from mobile_api import mobile_api

app = Flask(__name__)
app.secret_key = 'your-secret-key-change-this-in-production'

# Register Mobile API Blueprint
app.register_blueprint(mobile_api)

# Initialize database on app startup
init_database_on_startup()

# MySQL Configuration
MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
MYSQL_USER = os.getenv('MYSQL_USER', 'portal')
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', '123456789')
MYSQL_DB = os.getenv('MYSQL_DB', 'student_portal')
MYSQL_PORT = int(os.getenv('MYSQL_PORT', 3306))

# Uploads configuration
ALLOWED_IMAGE_EXTENSIONS = {'.png', '.jpg', '.jpeg', '.gif'}
AVATAR_UPLOAD_FOLDER = os.path.join('static', 'uploads', 'avatars')

# Ensure relations table exists (for parent-child relationships)
def ensure_relations_table():
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS student_relations (
                id INT AUTO_INCREMENT PRIMARY KEY,
                student_id INT NOT NULL,
                user_id INT NOT NULL,
                relation VARCHAR(20) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB
            """
        )
    finally:
        cursor.close()


def ensure_student_status_columns():
    """Ensure students table has status and permanently_deleted columns used for teacher archive/delete."""
    db = get_db()
    cursor = db.cursor()
    try:
        # Add status column if missing
        cursor.execute(
            """
            ALTER TABLE students
            ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'active'
            """
        )
    except Exception:
        db.rollback()
    try:
        # Add permanently_deleted flag if missing
        cursor.execute(
            """
            ALTER TABLE students
            ADD COLUMN IF NOT EXISTS permanently_deleted TINYINT(1) NOT NULL DEFAULT 0
            """
        )
    except Exception:
        db.rollback()
    finally:
        cursor.close()

# Ensure announcements table exists
def ensure_announcements_table():
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS announcements (
                id INT AUTO_INCREMENT PRIMARY KEY,
                title VARCHAR(200) NOT NULL,
                content TEXT NOT NULL,
                target_audience ENUM('all', 'students', 'teachers', 'admin') DEFAULT 'all',
                priority ENUM('low', 'medium', 'high') DEFAULT 'medium',
                posted_by INT NOT NULL,
                is_active BOOLEAN DEFAULT TRUE,
                start_date DATE DEFAULT CURDATE(),
                end_date DATE NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (posted_by) REFERENCES users(id)
            ) ENGINE=InnoDB
            """
        )
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"Error creating announcements table: {e}")
    finally:
        cursor.close()

def ensure_grade_entries_table():
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS grade_entries (
                id INT AUTO_INCREMENT PRIMARY KEY,
                student_id INT NOT NULL,
                subject_id INT NOT NULL,
                term VARCHAR(16) NOT NULL,
                score INT NOT NULL,
                school_year VARCHAR(20) NOT NULL,
                level VARCHAR(8) NULL,
                remarks VARCHAR(255) NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY uq_grade (student_id, subject_id, term, school_year)
            ) ENGINE=InnoDB
            """
        )
    finally:
        cursor.close()

def init_database_on_startup():
    """Initialize database with all required tables on app startup"""
    try:
        print("Starting database initialization...")
        db = get_db()
        cursor = db.cursor()
        
        # Check if users table exists (as a simple check if DB is initialized)
        cursor.execute("SHOW TABLES LIKE 'users'")
        result = cursor.fetchone()
        cursor.close()
        
        if result:
            print("✓ Database already initialized - users table exists")
            return  # Database already initialized
        
        print("Database not initialized, importing schema...")
        
        # Read and execute the SQL schema file
        import os
        sql_file = os.path.join(os.path.dirname(__file__), 'database', 'updated sql.sql')
        
        if not os.path.exists(sql_file):
            print(f"✗ SQL file not found: {sql_file}")
            return
        
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        db = get_db()
        cursor = db.cursor()
        
        # Execute each statement
        statements = sql_content.split(';')
        executed = 0
        errors = 0
        
        for statement in statements:
            statement = statement.strip()
            if statement and not statement.startswith('--') and not statement.startswith('/*'):
                try:
                    cursor.execute(statement)
                    executed += 1
                except Exception as e:
                    errors += 1
                    # Only log critical errors, ignore "table exists" and "duplicate key"
                    if 'already exists' not in str(e) and 'Duplicate entry' not in str(e):
                        print(f"Warning: {str(e)[:100]}")
        
        db.commit()
        cursor.close()
        print(f"✓ Database initialization complete - Executed: {executed}, Warnings: {errors}")
        
    except Exception as e:
        print(f"✗ Database initialization error: {str(e)}")
        import traceback
        traceback.print_exc()

def get_db():
    """Get database connection"""
    if 'db' not in g:
        g.db = pymysql.connect(
            host=MYSQL_HOST,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DB,
            port=MYSQL_PORT,
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=False,
            charset='utf8mb4',
            init_command='SET sql_mode="STRICT_TRANS_TABLES"'
        )
    return g.db

def close_db(e=None):
    """Close database connection"""
    db = g.pop('db', None)
    if db is not None:
        db.close()

app.teardown_appcontext(close_db)

# Login required decorator
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# Role-based access decorator
def role_required(roles):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'user_role' not in session or session['user_role'] not in roles:
                flash('You do not have permission to access this page.', 'danger')
                return redirect(url_for('dashboard'))
            return f(*args, **kwargs)
        return decorated_function
    return decorator

# Routes
@app.route('/')
def index():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))

    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        db = get_db()
        cursor = db.cursor()
        cursor.execute("SELECT * FROM users WHERE username = %s OR student_id = %s", (username, username))
        user = cursor.fetchone()
        cursor.close()
        
        if user and check_password_hash(user['password'], password):
            session['user_id'] = user['id']
            session['username'] = user['username']
            session['user_role'] = user['role']
            session['student_id'] = user.get('student_id')
            role = user['role'] or 'student'
            if role == 'admin':
                flash('Hello Admin! You have successfully logged in.', 'success')
            elif role == 'teacher':
                flash('Hello Teacher! You have successfully logged in.', 'success')
            elif role == 'parent':
                flash('Hello Parent! You have successfully logged in.', 'success')
            else:
                flash('Hello Student! You have successfully logged in.', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password', 'danger')
    
    return render_template('login.html')


@app.route('/profile')
@login_required
def profile():
    role = session.get('user_role')
    if role == 'parent':
        return redirect(url_for('parent_profile'))
    elif role == 'student':
        return redirect(url_for('student_info'))
    else:
        return redirect(url_for('dashboard'))


@app.route('/register', methods=['GET', 'POST'])
def register():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))

    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT id, course_code, course_name FROM courses ORDER BY course_name")
    courses = cursor.fetchall()

    if request.method == 'POST':
        first_name = request.form.get('first_name', '').strip()
        middle_name = request.form.get('middle_name', '').strip() or None
        last_name = request.form.get('last_name', '').strip()
        gender = request.form.get('gender', '').strip() or None
        lrn = request.form.get('lrn', '').strip() or None
        student_type = request.form.get('student_type', '').strip() or 'New Student'
        username = request.form.get('username', '').strip()
        email = request.form.get('email', '').strip() or None
        course_id = request.form.get('course_id')
        year_level = request.form.get('year_level', '').strip()
        section = request.form.get('section', '').strip() or None
        password = request.form.get('password', '')
        confirm_password = request.form.get('confirm_password', '')

        errors = []

        if not all([first_name, last_name, username, password, confirm_password, course_id]):
            errors.append('Please fill out all required fields.')

        if password != confirm_password:
            errors.append('Passwords do not match.')

        if course_id:
            try:
                course_id = int(course_id)
            except ValueError:
                errors.append('Invalid course selected.')
                course_id = None

        if year_level:
            try:
                year_level = int(year_level)
            except ValueError:
                errors.append('Year level must be a number.')
                year_level = None
        else:
            year_level = None

        if not errors:
            # Check if username already exists
            cursor.execute(
                "SELECT id FROM users WHERE username = %s",
                (username,)
            )
            existing = cursor.fetchone()
            if existing:
                errors.append('Username already exists. Please choose another.')

        if errors:
            cursor.close()
            for error in errors:
                flash(error, 'danger')
            return render_template('register.html', courses=courses, form_data=request.form)

        password_hash = generate_password_hash(password)

        def generate_student_id(db_conn, course_id_value):
            cursor2 = db_conn.cursor()
            # Get course code
            cursor2.execute("SELECT course_code FROM courses WHERE id = %s", (course_id_value,))
            course = cursor2.fetchone()
            code = (course['course_code'] if course else 'STD').upper()
            # Format: CODE-SEQUENCE (e.g., STEM-001)
            prefix = f"{code}-"
            # Find last sequence for this prefix
            cursor2.execute(
                "SELECT student_id FROM students WHERE student_id LIKE %s ORDER BY student_id DESC LIMIT 1",
                (prefix + '%',)
            )
            last = cursor2.fetchone()
            if last and last['student_id'] and '-' in last['student_id']:
                try:
                    # Extract numeric part after the last hyphen
                    seq_str = last['student_id'].split('-')[-1]
                    # Ensure it's a number
                    if seq_str.isdigit():
                        seq = int(seq_str) + 1
                    else:
                        seq = 1
                except ValueError:
                    seq = 1
            else:
                seq = 1
            # Return with 3 digit sequence as per "stem 001" request (or 4 if preferred, but 001 implies 3)
            return f"{prefix}{seq:03d}"

        try:
            cursor.execute(
                """
                INSERT INTO users (username, password, email, student_id, role)
                VALUES (%s, %s, %s, %s, 'student')
                """,
                (username, password_hash, email, None)
            )
            user_id = cursor.lastrowid

            # Generate unique student_id
            new_student_id = generate_student_id(db, course_id)

            cursor.execute(
                """
                INSERT INTO students (
                    user_id, student_id, first_name, middle_name, last_name,
                    course_id, year_level, section, gender, lrn, student_type, enrollment_date, status
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, CURDATE(), 'active')
                """,
                (
                    user_id,
                    new_student_id,
                    first_name,
                    middle_name,
                    last_name,
                    course_id,
                    year_level,
                    section,
                    gender,
                    lrn,
                    student_type,
                )
            )
            # Store student_id also in users table for login by ID
            cursor.execute("UPDATE users SET student_id = %s WHERE id = %s", (new_student_id, user_id))
            db.commit()
            flash(f"You're successfully registered as Student. Your Student ID is {new_student_id}.", 'success')
            return redirect(url_for('login'))
        except Exception as e:
            db.rollback()
            print(f"Registration error: {e}") # Debug print
            flash('An error occursorred during registration. Please try again.', 'danger')
        finally:
            cursor.close()

        # If there was an error during registration, re-render the form with data
        return render_template('register.html', courses=courses, form_data=request.form)

    cursor.close()
    return render_template('register.html', courses=courses)


@app.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))

    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        email = request.form.get('email', '').strip()
        new_password = request.form.get('new_password', '')
        confirm_password = request.form.get('confirm_password', '')

        if not all([username, email, new_password, confirm_password]):
            flash('Please fill out all fields.', 'danger')
            return render_template('forgot_password.html', form_data=request.form)

        if new_password != confirm_password:
            flash('Passwords do not match.', 'danger')
            return render_template('forgot_password.html', form_data=request.form)

        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "SELECT id FROM users WHERE (username = %s OR student_id = %s) AND email = %s",
            (username, username, email)
        )
        user = cursor.fetchone()

        if not user:
            cursor.close()
            flash('No matching account found for the provided details.', 'danger')
            return render_template('forgot_password.html', form_data=request.form)

        try:
            password_hash = generate_password_hash(new_password)
            cursor.execute("UPDATE users SET password = %s WHERE id = %s", (password_hash, user['id']))
            db.commit()
            flash('Password updated successfully! You can now log in.', 'success')
            return redirect(url_for('login'))
        except Exception:
            db.rollback()
            flash('An error occursorred while resetting the password. Please try again.', 'danger')
        finally:
            cursor.close()

    return render_template('forgot_password.html')


@app.route('/register/parent', methods=['GET', 'POST'])
def register_parent():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))

    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        email = request.form.get('email', '').strip()
        password = request.form.get('password', '')
        confirm_password = request.form.get('confirm_password', '')
        child_student_id = request.form.get('child_student_id', '').strip() or None

        if not all([username, email, password, confirm_password]):
            flash('Please fill out all required fields.', 'danger')
            return render_template('register_parent.html', form_data=request.form)

        if password != confirm_password:
            flash('Passwords do not match.', 'danger')
            return render_template('register_parent.html', form_data=request.form)

        db = get_db()
        cursor = db.cursor()

        # Check username exists
        cursor.execute("SELECT id FROM users WHERE username = %s", (username,))
        if cursor.fetchone():
            cursor.close()
            flash('Username already taken.', 'danger')
            return render_template('register_parent.html', form_data=request.form)

        try:
            password_hash = generate_password_hash(password)
            cursor.execute(
                "INSERT INTO users (username, password, email, role) VALUES (%s, %s, %s, 'parent')",
                (username, password_hash, email)
            )
            parent_user_id = cursor.lastrowid

            if child_student_id:
                # Link to student if exists and not already linked
                cursor.execute("""
                    UPDATE students 
                    SET parent_user_id = %s 
                    WHERE student_id = %s AND (parent_user_id IS NULL OR parent_user_id = 0)
                """, (parent_user_id, child_student_id))

            db.commit()
            cursor.close()
            flash("You're successfully registered as Parent.", 'success')
            return redirect(url_for('login'))
        except Exception:
            db.rollback()
            cursor.close()
            flash('An error occursorred during registration. Please try again.', 'danger')

    return render_template('register_parent.html')


# ------------------ TEACHER MODULE ------------------

def teacher_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if 'user_role' not in session or session['user_role'] != 'teacher':
            flash('Teacher access only.', 'danger')
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return wrapper

@app.route('/teacher')
@login_required
@teacher_required
def teacher_dashboard():
    db = get_db()
    cursor = db.cursor()
    # Basic counts
    cursor.execute("SELECT COUNT(*) AS total FROM students")
    total_students = (cursor.fetchone() or {}).get('total', 0)
    cursor.execute("SELECT COUNT(*) AS total FROM subjects")
    total_subjects = (cursor.fetchone() or {}).get('total', 0)
    cursor.close()
    return render_template('teacher_dashboard.html', total_students=total_students, total_subjects=total_subjects)


@app.route('/teacher/students')
@login_required
@teacher_required
def teacher_students():
    db = get_db()
    ensure_student_status_columns()
    cursor = db.cursor()

    # Get Teacher's Department
    cursor.execute("SELECT department FROM teachers WHERE user_id=%s", (session.get('user_id'),))
    teacher_record = cursor.fetchone()
    teacher_dept = teacher_record['department'] if teacher_record else ''

    # Filter Students by Department (same logic pattern as grades/attendance)
    # Join users to fetch avatar image used in profiles
    if teacher_dept:
        cursor.execute(
            """
            SELECT s.id, s.student_id, s.first_name, s.last_name, s.year_level, u.avatar
            FROM students s
            JOIN courses c ON s.course_id = c.id
            JOIN users u ON s.user_id = u.id
            WHERE UPPER(c.course_code) = UPPER(%s) AND s.status='active' AND s.permanently_deleted=0
            ORDER BY s.first_name, s.last_name
            """,
            (teacher_dept,),
        )
    else:
        cursor.execute(
            """
            SELECT s.id, s.student_id, s.first_name, s.last_name, s.year_level, u.avatar
            FROM students s
            JOIN users u ON s.user_id = u.id
            WHERE s.status='active' AND s.permanently_deleted=0
            ORDER BY s.first_name, s.last_name
            """
        )
    students = cursor.fetchall()
    cursor.close()

    return render_template('teacher_students.html', students=students, teacher_dept=teacher_dept)


@app.route('/teacher/students/<int:student_id>')
@login_required
@teacher_required
def teacher_view_student(student_id):
    """Read-only view of a student's full profile for teachers, reusing student_info template."""
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        """
        SELECT s.*, c.course_name, u.avatar
        FROM students s
        LEFT JOIN courses c ON s.course_id = c.id
        LEFT JOIN users u ON s.user_id = u.id
        WHERE s.id=%s
        """,
        (student_id,),
    )
    student = cursor.fetchone()
    cursor.close()
    if not student:
        flash('Student not found.', 'danger')
        return redirect(url_for('teacher_students'))

    # Render existing student_info template in read-only mode
    return render_template('student_info.html', student=student, children=None)


@app.route('/teacher/students/<int:student_id>/archive', methods=['POST'])
@login_required
@teacher_required
def teacher_archive_student(student_id):
    """Mark student as archived (stopped studying) but keep record."""
    db = get_db()
    cursor = db.cursor()
    try:
        ensure_student_status_columns()
        reason = request.form.get('reason_type') or None
        cursor.execute(
            "UPDATE students SET status='inactive', archive_reason=%s WHERE id=%s AND permanently_deleted=0",
            (reason, student_id),
        )
        db.commit()
        flash('Student moved to archived list.', 'info')
    except Exception:
        db.rollback()
        flash('Failed to archive student.', 'danger')
    finally:
        cursor.close()
    return redirect(url_for('teacher_students'))


@app.route('/teacher/students/archived')
@login_required
@teacher_required
def teacher_archived_students():
    """List of archived students for the teacher, including those marked permanently_deleted."""
    db = get_db()
    ensure_student_status_columns()
    cursor = db.cursor()
    # Filter by teacher department same as teacher_students
    cursor.execute("SELECT department FROM teachers WHERE user_id=%s", (session.get('user_id'),))
    teacher_record = cursor.fetchone()
    teacher_dept = teacher_record['department'] if teacher_record else ''

    if teacher_dept:
        cursor.execute(
            """
            SELECT s.id, s.student_id, s.first_name, s.last_name, s.year_level, s.status, s.permanently_deleted, s.archive_reason, u.avatar
            FROM students s
            JOIN courses c ON s.course_id = c.id
            JOIN users u ON s.user_id = u.id
            WHERE UPPER(c.course_code) = UPPER(%s) AND s.status='inactive'
            ORDER BY s.first_name, s.last_name
            """,
            (teacher_dept,),
        )
    else:
        cursor.execute(
            """
            SELECT s.id, s.student_id, s.first_name, s.last_name, s.year_level, s.status, s.permanently_deleted, s.archive_reason, u.avatar
            FROM students s
            JOIN users u ON s.user_id = u.id
            WHERE s.status='inactive'
            ORDER BY s.first_name, s.last_name
            """,
        )
    students = cursor.fetchall()
    cursor.close()
    return render_template('teacher_students_archived.html', students=students, teacher_dept=teacher_dept)


@app.route('/teacher/students/<int:student_id>/delete', methods=['POST'])
@login_required
@teacher_required
def teacher_delete_student(student_id):
    """Soft delete from active list: mark permanently_deleted=1 and archived."""
    db = get_db()
    cursor = db.cursor()
    try:
        ensure_student_status_columns()
        cursor.execute(
            "UPDATE students SET status='inactive', permanently_deleted=1 WHERE id=%s",
            (student_id,),
        )
        db.commit()
        flash('Student marked as permanently deleted and moved to archived.', 'warning')
    except Exception:
        db.rollback()
        flash('Failed to delete student.', 'danger')
    finally:
        cursor.close()
    return redirect(url_for('teacher_students'))


@app.route('/teacher/students/<int:student_id>/hard-delete', methods=['POST'])
@login_required
@teacher_required
def teacher_hard_delete_student(student_id):
    """Hard delete a student record from the archived list."""
    db = get_db()
    cursor = db.cursor()
    try:
        # Optionally also remove linked user; here we only delete from students
        cursor.execute("DELETE FROM students WHERE id=%s", (student_id,))
        db.commit()
        flash('Student record permanently removed.', 'success')
    except Exception:
        db.rollback()
        flash('Failed to permanently delete student.', 'danger')
    finally:
        cursor.close()
    return redirect(url_for('teacher_archived_students'))


@app.route('/teacher/students/<int:student_id>/restore', methods=['POST'])
@login_required
@teacher_required
def teacher_restore_student(student_id):
    """Restore an archived student back to active list, clearing archive_reason and delete flag."""
    db = get_db()
    cursor = db.cursor()
    try:
        ensure_student_status_columns()
        cursor.execute(
            "UPDATE students SET status='active', permanently_deleted=0, archive_reason=NULL WHERE id=%s",
            (student_id,),
        )
        db.commit()
        flash('Student restored to active list.', 'success')
    except Exception:
        db.rollback()
        flash('Failed to restore student.', 'danger')
    finally:
        cursor.close()
    return redirect(url_for('teacher_archived_students'))

@app.route('/teacher/grades', methods=['GET','POST'])
@login_required
@teacher_required
def teacher_grades():
    db = get_db()
    cursor = db.cursor()
    ensure_grade_entries_table()

    # Get Teacher's Department
    cursor.execute("SELECT department FROM teachers WHERE user_id=%s", (session.get('user_id'),))
    teacher_record = cursor.fetchone()
    teacher_dept = teacher_record['department'] if teacher_record else ''

    # Filter Subjects by Department (Course Code)
    # If teacher has no department, show all (or maybe none? let's show all for safety or handle empty)
    if teacher_dept:
        cursor.execute("""
            SELECT s.id, s.subject_code, s.subject_name 
            FROM subjects s
            JOIN courses c ON s.course_id = c.id
            WHERE UPPER(c.course_code) = UPPER(%s)
            ORDER BY s.subject_name
        """, (teacher_dept,))
    else:
        cursor.execute("SELECT id, subject_code, subject_name FROM subjects ORDER BY subject_name")
    subjects = cursor.fetchall()

    # Filter Students by Department
    if teacher_dept:
        cursor.execute("""
            SELECT s.student_id, s.first_name, s.last_name, s.year_level
            FROM students s 
            JOIN courses c ON s.course_id=c.id
            WHERE UPPER(c.course_code) = UPPER(%s)
            ORDER BY s.first_name, s.last_name
        """, (teacher_dept,))
    else:
        cursor.execute("""
            SELECT s.student_id, s.first_name, s.last_name, s.year_level
            FROM students s 
            ORDER BY s.first_name, s.last_name
        """)
    students = cursor.fetchall()

    # Debug: Show filtering results
    flash(f'Your Department: {teacher_dept or "None"} | Found {len(students)} students and {len(subjects)} subjects', 'info')

    message = None

    if request.method == 'POST':
        student_id_text = request.form.get('student_id','').strip()
        subject_id = request.form.get('subject_id')
        term = request.form.get('term','').strip() or 'Final'
        score_raw = request.form.get('score')
        school_year = request.form.get('school_year','').strip() or ''
        remarks = request.form.get('remarks','').strip() or None

        try:
            score = int(score_raw)
            if score < 60 or score > 100:
                raise ValueError('Score out of range')
            # Resolve student and level
            cursor.execute("""
                SELECT s.id, c.course_code
                FROM students s LEFT JOIN courses c ON s.course_id=c.id
                WHERE s.student_id=%s
            """, (student_id_text,))
            stu = cursor.fetchone()
            if not stu:
                raise Exception('Student not found')
            level = 'JHS' if 'JHS' in ((stu.get('course_code') or '').upper()) else 'SHS'
            # Upsert term grade
            cursor.execute("""
                INSERT INTO grade_entries (student_id, subject_id, term, score, school_year, level, remarks)
                VALUES (%s,%s,%s,%s,%s,%s,%s)
                ON DUPLICATE KEY UPDATE score=VALUES(score), remarks=VALUES(remarks), level=VALUES(level)
            """, (stu['id'], subject_id, term, score, school_year, level, remarks))
            db.commit()
            message = ('success','Grade saved successfully')
        except Exception:
            db.rollback()
            message = ('danger','Failed to save grade')


    # Recent numeric entries - filtered by teacher's department
    if teacher_dept:
        cursor.execute("""
            SELECT ge.id, u.username AS student_username, s.first_name, s.last_name, sub.subject_name, ge.term, ge.score, ge.created_at
            FROM grade_entries ge
            JOIN students s ON ge.student_id=s.id
            JOIN users u ON s.user_id=u.id
            JOIN subjects sub ON ge.subject_id=sub.id
            JOIN courses c ON s.course_id=c.id
            WHERE UPPER(c.course_code) = UPPER(%s)
            ORDER BY ge.created_at DESC LIMIT 20
        """, (teacher_dept,))
    else:
        cursor.execute("""
            SELECT ge.id, u.username AS student_username, s.first_name, s.last_name, sub.subject_name, ge.term, ge.score, ge.created_at
            FROM grade_entries ge
            JOIN students s ON ge.student_id=s.id
            JOIN users u ON s.user_id=u.id
            JOIN subjects sub ON ge.subject_id=sub.id
            ORDER BY ge.created_at DESC LIMIT 20
        """)
    recent = cursor.fetchall()
    cursor.close()
    return render_template('teacher_grades.html', subjects=subjects, students=students, message=message, recent=recent, teacher_dept=teacher_dept)


@app.route('/api/student/level')
@login_required
def api_student_level():
    student_id_input = request.args.get('student_id','').strip()
    if not student_id_input:
        return jsonify({'level': None})
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        """
        SELECT c.course_code FROM students s LEFT JOIN courses c ON s.course_id=c.id
        WHERE s.student_id=%s
        """,
        (student_id_input,)
    )
    row = cursor.fetchone()
    cursor.close()
    course_code = (row.get('course_code') if row else '') or ''
    level = 'JHS' if 'JHS' in course_code.upper() else 'SHS'
    return jsonify({'level': level})

@app.route('/teacher/attendance', methods=['GET','POST'])
@login_required
@teacher_required
def teacher_attendance():
    db = get_db()
    cursor = db.cursor()

    # Get Teacher's Department
    cursor.execute("SELECT department FROM teachers WHERE user_id=%s", (session.get('user_id'),))
    teacher_record = cursor.fetchone()
    teacher_dept = teacher_record['department'] if teacher_record else ''

    # Filter Subjects by Department
    if teacher_dept:
        cursor.execute("""
            SELECT s.id, s.subject_code, s.subject_name 
            FROM subjects s
            JOIN courses c ON s.course_id = c.id
            WHERE UPPER(c.course_code) = UPPER(%s)
            ORDER BY s.subject_name
        """, (teacher_dept,))
    else:
        cursor.execute("SELECT id, subject_code, subject_name FROM subjects ORDER BY subject_name")
    subjects = cursor.fetchall()

    # Filter Students by Department
    if teacher_dept:
        cursor.execute("""
            SELECT s.id, s.student_id, s.first_name, s.last_name, s.year_level
            FROM students s 
            JOIN courses c ON s.course_id=c.id
            WHERE UPPER(c.course_code) = UPPER(%s)
            ORDER BY s.first_name, s.last_name
        """, (teacher_dept,))
    else:
        cursor.execute("""
            SELECT s.id, s.student_id, s.first_name, s.last_name, s.year_level
            FROM students s 
            ORDER BY s.first_name, s.last_name
        """)
    students = cursor.fetchall()

    # Clear any existing messages on GET request to prevent showing old success messages on refresh
    message = None
    today_str = date.today().isoformat()
    
    if request.method == 'GET':
        # Clear any flash messages from previous attendance saves
        session.pop('_flashes', None)
    
    if request.method == 'POST':
        subject_id = request.form.get('subject_id')
        date_str = request.form.get('date')
        
        # Validate required fields
        if not subject_id:
            message = ('danger','Please select a subject')
        else:
            try:
                att_date = datetime.strptime(date_str, '%Y-%m-%d').date() if date_str else date.today()
                attendance_count = 0
                
                # Debug: Print all form data
                print("DEBUG - Form data received:")
                for key, value in request.form.items():
                    print(f"  {key}: {value}")
                
                # Process each student's attendance
                for student in students:
                    student_id = student['id']
                    status = request.form.get(f'status_{student_id}')
                    remarks = request.form.get(f'remarks_{student_id}', '')
                    
                    print(f"DEBUG - Student {student_id}: status={status}, remarks={remarks}")
                    
                    # Only process if status was actually submitted
                    if status:
                        cursor.execute("""
                            INSERT INTO attendance (student_id, subject_id, date, status, remarks)
                            VALUES (%s,%s,%s,%s,%s)
                            ON DUPLICATE KEY UPDATE status=VALUES(status), remarks=VALUES(remarks)
                        """, (student_id, subject_id, att_date, status, remarks))
                        attendance_count += 1
                
                db.commit()
                message = ('success',f'Attendance recorded for {attendance_count} students')
            except Exception as e:
                db.rollback()
                message = ('danger',f'Failed to record attendance: {str(e)}')
    cursor.close()
    return render_template('teacher_attendance.html', subjects=subjects, students=students, message=message, current_date=today_str, teacher_dept=teacher_dept)

@app.route('/teacher/schedule', methods=['GET','POST'])
@login_required
@teacher_required
def teacher_schedule():
    db = get_db()
    cursor = db.cursor()

    # Get Teacher's Department
    cursor.execute("SELECT department FROM teachers WHERE user_id=%s", (session.get('user_id'),))
    teacher_record = cursor.fetchone()
    teacher_dept = teacher_record['department'] if teacher_record else ''

    # Filter Courses by Department
    if teacher_dept:
        cursor.execute("""
            SELECT id, course_code, course_name 
            FROM courses 
            WHERE UPPER(course_code) = UPPER(%s)
            ORDER BY course_name
        """, (teacher_dept,))
    else:
        cursor.execute("SELECT id, course_code, course_name FROM courses ORDER BY course_name")
    courses = cursor.fetchall()

    # Filter Subjects by Department
    if teacher_dept:
        cursor.execute("""
            SELECT s.id, s.subject_code, s.subject_name 
            FROM subjects s
            JOIN courses c ON s.course_id = c.id
            WHERE UPPER(c.course_code) = UPPER(%s)
            ORDER BY s.subject_name
        """, (teacher_dept,))
    else:
        cursor.execute("SELECT id, subject_code, subject_name FROM subjects ORDER BY subject_name")
    subjects = cursor.fetchall()

    message = None
    if request.method == 'POST':
        course_id = request.form.get('course_id')
        subject_id = request.form.get('subject_id')
        day_of_week = request.form.get('day_of_week')
        start_time = request.form.get('start_time')
        end_time = request.form.get('end_time')
        modality = request.form.get('modality')  # 'f2f' or 'online'
        room = request.form.get('room') if modality == 'f2f' else None
        meeting_link = request.form.get('meeting_link') if modality == 'online' else None
        try:
            # Store meeting_link inside room field with prefix if online (no schema change)
            stored_room = room if modality == 'f2f' else (f"ONLINE:{meeting_link}" if meeting_link else 'ONLINE')
            # Resolve teacher_id from current user (if exists)
            teacher_id = None
            cursor.execute("SELECT id FROM teachers WHERE user_id=%s", (session.get('user_id'),))
            t = cursor.fetchone()
            if t:
                teacher_id = t['id']
            cursor.execute("""
                INSERT INTO schedules (subject_id, course_id, teacher_id, day_of_week, start_time, end_time, room)
                VALUES (%s,%s,%s,%s,%s,%s,%s)
            """, (subject_id, course_id, teacher_id, day_of_week, start_time, end_time, stored_room))
            db.commit()
            message = ('success','Schedule created')
        except Exception:
            db.rollback()
            message = ('danger','Failed to create schedule')


    # Recent schedules - filtered by teacher's department
    cursor = db.cursor()
    if teacher_dept:
        cursor.execute("""
            SELECT sch.*, sub.subject_name, c.course_code
            FROM schedules sch
            JOIN subjects sub ON sch.subject_id=sub.id
            JOIN courses c ON sch.course_id=c.id
            WHERE UPPER(c.course_code) = UPPER(%s)
            ORDER BY sch.created_at DESC LIMIT 20
        """, (teacher_dept,))
    else:
        cursor.execute("""
            SELECT sch.*, sub.subject_name, c.course_code
            FROM schedules sch
            JOIN subjects sub ON sch.subject_id=sub.id
            JOIN courses c ON sch.course_id=c.id
            ORDER BY sch.created_at DESC LIMIT 20
        """)
    recent = cursor.fetchall()
    cursor.close()
    return render_template('teacher_schedule.html', courses=courses, subjects=subjects, message=message, recent=recent)


@app.route('/api/teacher/schedule/events')
@login_required
@teacher_required
def api_teacher_schedule_events():
    db = get_db()
    cursor = db.cursor()
    # Resolve current teacher_id
    cursor.execute("SELECT id FROM teachers WHERE user_id=%s", (session.get('user_id'),))
    t = cursor.fetchone()
    teacher_id = (t or {}).get('id')
    # Fetch schedules created by this teacher
    cursor.execute(
        """
        SELECT sch.day_of_week, sch.start_time, sch.end_time, sch.room,
               sub.subject_name, c.course_code
        FROM schedules sch
        JOIN subjects sub ON sch.subject_id=sub.id
        LEFT JOIN courses c ON sch.course_id=c.id
        WHERE (sch.teacher_id=%s OR %s IS NULL)
        ORDER BY sch.day_of_week, sch.start_time
        """,
        (teacher_id, teacher_id)
    )
    rows = cursor.fetchall() or []
    cursor.close()

    def dow_to_num(d):
        m = {
            'sunday': 0, 'monday': 1, 'tuesday': 2, 'wednesday': 3,
            'thursday': 4, 'friday': 5, 'saturday': 6,
        }
        return m.get((d or '').strip().lower())

    events = []
    for r in rows:
        dow = dow_to_num(r.get('day_of_week'))
        if dow is None:
            continue
        title_bits = [str(r.get('subject_name') or 'Class')]
        if r.get('course_code'):
            title_bits.append(str(r['course_code']))
        events.append({
            'title': ' - '.join(title_bits),
            'daysOfWeek': [dow],
            'startTime': str(r.get('start_time')),
            'endTime': str(r.get('end_time')),
            'extendedProps': {
                'room': r.get('room')
            }
        })
    return jsonify(events)


# ------------------ ADMIN: MANAGE TEACHERS ------------------
def ensure_teachers_archived_column():
    """Ensure the teachers table has the 'archived' column."""
    # Helper function: not a route
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute("SHOW COLUMNS FROM teachers LIKE 'archived'")
        if not cursor.fetchone():
            cursor.execute("ALTER TABLE teachers ADD COLUMN archived TINYINT DEFAULT 0")
            db.commit()
    finally:
        cursor.close()

@app.route('/admin/teachers', methods=['GET','POST'])
@login_required
@role_required(['admin'])
def admin_teachers():
    ensure_teachers_archived_column()
    db = get_db()
    cursor = db.cursor()

    if request.method == 'POST':
        username = request.form.get('username','').strip()
        email = request.form.get('email','').strip() or None
        password = request.form.get('password','')
        first_name = request.form.get('first_name','').strip()
        last_name = request.form.get('last_name','').strip()
        department = request.form.get('department','').strip() or None

        if not all([username, password, first_name, last_name]):
            flash('Please fill out required fields.', 'danger')
        else:
            try:
                # Auto-capitalize first and last names
                first_name = first_name.strip().title()
                last_name = last_name.strip().title()
                
                cursor.execute("SELECT id FROM users WHERE username=%s", (username,))
                if cursor.fetchone():
                    flash('Username already exists.', 'danger')
                else:
                    pwd_hash = generate_password_hash(password)
                    cursor.execute("""
                        INSERT INTO users (username, password, email, role)
                        VALUES (%s,%s,%s,'teacher')
                    """, (username, pwd_hash, email))
                    user_id = cursor.lastrowid
                    cursor.execute("""
                        INSERT INTO teachers (user_id, first_name, last_name, email, department)
                        VALUES (%s,%s,%s,%s,%s)
                    """, (user_id, first_name, last_name, email, department))
                    db.commit()
                    flash('Teacher account created.', 'success')
            except Exception:
                db.rollback()
                flash('Failed to create teacher.', 'danger')


    # Fetch departments (course codes) for dropdown
    cursor.execute("""
        SELECT DISTINCT course_code, course_name 
        FROM courses 
        WHERE course_code IS NOT NULL AND course_code != ''
        ORDER BY course_code
    """)
    departments = cursor.fetchall()

    # List teachers (excluding archived)
    cursor.execute("""
        SELECT t.id, t.first_name, t.last_name, t.email, t.department, u.username, u.avatar
        FROM teachers t LEFT JOIN users u ON t.user_id=u.id
        WHERE (t.archived IS NULL OR t.archived = 0)
        ORDER BY t.first_name, t.last_name
    """)
    teachers = cursor.fetchall()
    cursor.close()
    return render_template('admin_teachers.html', teachers=teachers, departments=departments)


@app.route('/admin/students')
@login_required
@role_required(['admin'])
def admin_students():
    """Admin view all students."""
    db = get_db()
    cursor = db.cursor()
    
    try:
        cursor.execute("""
            SELECT s.*, c.course_code, c.course_name 
            FROM students s 
            LEFT JOIN courses c ON s.course_id = c.id 
            ORDER BY s.last_name, s.first_name
        """)
        students = cursor.fetchall()
    finally:
        cursor.close()
    
    return render_template('admin_students.html', students=students)


# ------------------ MOBILE API ENDPOINTS ------------------

@app.route('/api/login', methods=['POST'])
def api_login():
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'message': 'No data provided'}), 400
    
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({'success': False, 'message': 'Missing credentials'}), 400

    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM users WHERE username = %s OR student_id = %s", (username, username))
    user = cursor.fetchone()
    
    if user and check_password_hash(user['password'], password):
        # Fetch specific role data
        role_data = {}
        if user['role'] == 'student':
            cursor.execute("SELECT * FROM students WHERE user_id = %s", (user['id'],))
            stu = cursor.fetchone()
            if stu:
                role_data = {
                    'first_name': stu['first_name'],
                    'last_name': stu['last_name'],
                    'student_id': stu['student_id'],
                    'course_id': stu['course_id'],
                    'year_level': stu['year_level']
                }
        
        cursor.close()
        return jsonify({
            'success': True,
            'user': {
                'id': user['id'],
                'username': user['username'],
                'role': user['role'],
                'student_id': user.get('student_id'),
                **role_data
            }
        })
    
    cursor.close()
    return jsonify({'success': False, 'message': 'Invalid credentials'}), 401

@app.route('/api/student/dashboard')
def api_student_dashboard():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Unauthorized'}), 401
        
    db = get_db()
    cursor = db.cursor()
    
    # Get Student Info
    cursor.execute("""
        SELECT s.*, c.course_code, c.course_name 
        FROM students s 
        LEFT JOIN courses c ON s.course_id = c.id 
        WHERE s.user_id = %s
    """, (user_id,))
    student = cursor.fetchone()
    
    if not student:
        cursor.close()
        return jsonify({'error': 'Student not found'}), 404

    # Get recent grades
    cursor.execute("""
        SELECT sub.subject_name, ge.score, ge.term
        FROM grade_entries ge
        JOIN subjects sub ON ge.subject_id = sub.id
        WHERE ge.student_id = %s
        ORDER BY ge.created_at DESC LIMIT 5
    """, (student['id'],))
    recent_grades = cursor.fetchall()

    cursor.close()
    
    return jsonify({
        'student': student,
        'recent_grades': recent_grades
    })

@app.route('/api/student/grades')
def api_student_grades():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Unauthorized'}), 401

    db = get_db()
    cursor = db.cursor()
    
    # Get Student Internal ID
    cursor.execute("SELECT id FROM students WHERE user_id = %s", (user_id,))
    student = cursor.fetchone()
    if not student:
        cursor.close()
        return jsonify({'error': 'Student not found'}), 404

    cursor.execute("""
        SELECT sub.subject_code, sub.subject_name, ge.score, ge.term, ge.remarks, ge.school_year
        FROM grade_entries ge
        JOIN subjects sub ON ge.subject_id = sub.id
        WHERE ge.student_id = %s
        ORDER BY ge.school_year DESC, ge.term DESC
    """, (student['id'],))
    grades = cursor.fetchall()
    
    cursor.close()
    return jsonify(grades)

@app.route('/api/student/schedule')
def api_student_schedule():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Unauthorized'}), 401

    db = get_db()
    cursor = db.cursor()
    
    # Get Student Course
    cursor.execute("SELECT course_id FROM students WHERE user_id = %s", (user_id,))
    student = cursor.fetchone()
    if not student:
        cursor.close()
        return jsonify({'error': 'Student not found'}), 404

    # Get Schedules for this course
    cursor.execute("""
        SELECT sch.day_of_week, sch.start_time, sch.end_time, sch.room, 
               sub.subject_code, sub.subject_name,
               t.first_name as teacher_fname, t.last_name as teacher_lname
        FROM schedules sch
        JOIN subjects sub ON sch.subject_id = sub.id
        LEFT JOIN teachers t ON sch.teacher_id = t.id
        WHERE sch.course_id = %s
        ORDER BY FIELD(sch.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), sch.start_time
    """, (student['course_id'],))
    schedules = cursor.fetchall()
    
    # Convert time objects to string
    for s in schedules:
        s['start_time'] = str(s['start_time'])
        s['end_time'] = str(s['end_time'])
    
    cursor.close()
    return jsonify(schedules)



@app.route('/logout')
def logout():
    role = session.get('user_role', 'student')
    if role == 'admin':
        msg = "You're successfully logged out as Admin."
    elif role == 'teacher':
        msg = "You're successfully logged out as Teacher."
    elif role == 'parent':
        msg = "You're successfully logged out as Parent."
    else:
        msg = "You're successfully logged out as Student."
    session.clear()
    flash(msg, 'info')
    return redirect(url_for('login'))

@app.route('/setup-announcements')
def setup_announcements():
    """Setup sample announcements (run once)"""
    db = get_db()
    cursor = db.cursor()
    
    # Ensure announcements table exists
    ensure_announcements_table()
    
    try:
        # Check if announcements already exist
        cursor.execute("SELECT COUNT(*) as count FROM announcements")
        count = cursor.fetchone()['count']
        
        if count > 0:
            return f"Announcements table already has {count} records."
        
        # Get admin user ID
        cursor.execute("SELECT id FROM users WHERE role = 'admin' LIMIT 1")
        admin_user = cursor.fetchone()
        posted_by = admin_user['id'] if admin_user else 1
        
        # Sample announcements
        announcements = [
            ('Welcome Back Students!', 
             'We are excited to start the new school year. Please check your schedules and attend your classes regularly. Remember to bring your requirements and be on time.',
             'students', 'high', posted_by),
            ('Midterm Exams Announcement', 
             'Midterm examinations will begin next week. Please prepare well and review your lessons. Check the examination schedule posted on the bulletin board.',
             'students', 'high', posted_by),
            ('New Library Hours', 
             'The library will be open from 8 AM to 8 PM Monday to Friday. Weekends from 9 AM to 5 PM. Please take advantage of our resources and study areas.',
             'all', 'medium', posted_by),
            ('School Festival Next Month', 
             'Join us for our annual school festival next month. Lots of activities, games, and prizes await! Sign up for events at the student council office.',
             'all', 'medium', posted_by),
            ('Teacher Meeting Schedule', 
             'Monthly teacher meeting is scheduled for this Friday at 3 PM in the conference room. Please prepare your reports and attendance updates.',
             'teachers', 'medium', posted_by)
        ]
        
        # Insert announcements
        for ann in announcements:
            cursor.execute("""
                INSERT INTO announcements (title, content, target_audience, priority, posted_by)
                VALUES (%s, %s, %s, %s, %s)
            """, ann)
        
        db.commit()
        return f"Successfully added {len(announcements)} sample announcements!"
        
    except Exception as e:
        db.rollback()
        return f"Error: {e}"
    finally:
        cursor.close()

@app.route('/announcements', methods=['GET', 'POST'])
@login_required
def manage_announcements():
    """Manage announcements for teachers and admins"""
    if session['user_role'] not in ['teacher', 'admin']:
        flash('Access denied.', 'danger')
        return redirect(url_for('dashboard'))
    
    db = get_db()
    cursor = db.cursor()
    
    # Ensure announcements table exists
    ensure_announcements_table()
    
    if request.method == 'POST':
        title = request.form.get('title', '').strip()
        content = request.form.get('content', '').strip()
        target_audience = request.form.get('target_audience', 'all')
        priority = request.form.get('priority', 'medium')
        
        if title and content:
            try:
                cursor.execute("""
                    INSERT INTO announcements (title, content, target_audience, priority, posted_by)
                    VALUES (%s, %s, %s, %s, %s)
                """, (title, content, target_audience, priority, session['user_id']))
                db.commit()
                flash('Announcement posted successfully!', 'success')
            except Exception as e:
                db.rollback()
                flash('Error posting announcement.', 'danger')
        else:
            flash('Please fill in all required fields.', 'danger')
    
    # Get all announcements
    cursor.execute("""
        SELECT a.*, u.username as posted_by_name
        FROM announcements a
        JOIN users u ON a.posted_by = u.id
        ORDER BY a.created_at DESC
    """)
    announcements = cursor.fetchall()
    cursor.close()
    
    return render_template('manage_announcements.html', announcements=announcements)

@app.route('/announcements/<int:announcement_id>/delete', methods=['POST'])
@login_required
def delete_announcement(announcement_id):
    """Delete an announcement"""
    if session['user_role'] not in ['teacher', 'admin']:
        flash('Access denied.', 'danger')
        return redirect(url_for('dashboard'))
    
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute("DELETE FROM announcements WHERE id = %s", (announcement_id,))
        db.commit()
        flash('Announcement deleted successfully!', 'success')
    except Exception:
        db.rollback()
        flash('Error deleting announcement.', 'danger')
    finally:
        cursor.close()
    
    return redirect(url_for('manage_announcements'))

# Chart data generation functions
def generate_student_chart_data(student_id):
    """Generate chart data for student dashboard"""
    db = get_db()
    cursor = db.cursor()
    
    try:
        # Grade Distribution
        cursor.execute("""
            SELECT 
                CASE 
                    WHEN CAST(ge.score AS DECIMAL) >= 90 THEN 'A (90-100)'
                    WHEN CAST(ge.score AS DECIMAL) >= 80 THEN 'B (80-89)'
                    WHEN CAST(ge.score AS DECIMAL) >= 75 THEN 'C (75-79)'
                    WHEN CAST(ge.score AS DECIMAL) >= 70 THEN 'D (70-74)'
                    ELSE 'F (Below 70)'
                END as grade_range,
                COUNT(*) as count
            FROM grade_entries ge
            WHERE ge.student_id = %s
            GROUP BY grade_range
            ORDER BY 
                CASE grade_range
                    WHEN 'A (90-100)' THEN 1
                    WHEN 'B (80-89)' THEN 2
                    WHEN 'C (75-79)' THEN 3
                    WHEN 'D (70-74)' THEN 4
                    WHEN 'F (Below 70)' THEN 5
                END
        """, (student_id,))
        grade_dist = cursor.fetchall()
        
        # Subject Performance
        cursor.execute("""
            SELECT sub.subject_name, AVG(CAST(ge.score AS DECIMAL)) as avg_score
            FROM grade_entries ge
            JOIN subjects sub ON ge.subject_id = sub.id
            WHERE ge.student_id = %s
            GROUP BY sub.subject_name
            ORDER BY avg_score DESC
            LIMIT 6
        """, (student_id,))
        subject_perf = cursor.fetchall()
        
        # Attendance Trend (last 30 days)
        cursor.execute("""
            SELECT DATE(date) as att_date, 
                   SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present,
                   COUNT(*) as total
            FROM attendance
            WHERE student_id = %s 
            AND date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            GROUP BY DATE(date)
            ORDER BY att_date
            LIMIT 30
        """, (student_id,))
        attendance_data = cursor.fetchall()
        
        # Grade Progress Over Time
        cursor.execute("""
            SELECT DATE(created_at) as grade_date, 
                   AVG(CAST(score AS DECIMAL)) as avg_grade
            FROM grade_entries
            WHERE student_id = %s
            GROUP BY DATE(created_at)
            ORDER BY grade_date
            LIMIT 20
        """, (student_id,))
        grade_progress = cursor.fetchall()
        
        # Format data for JSON
        chart_data = {
            'grade_distribution': {
                'labels': [row['grade_range'] for row in grade_dist] if grade_dist else ['No Data'],
                'values': [int(row['count']) for row in grade_dist] if grade_dist else [1]
            },
            'subject_performance': {
                'labels': [row['subject_name'] for row in subject_perf] if subject_perf else ['No Data'],
                'values': [round(float(row['avg_score']), 1) for row in subject_perf] if subject_perf else [0]
            },
            'attendance_trend': {
                'labels': [row['att_date'].strftime('%m/%d') for row in attendance_data] if attendance_data else ['No Data'],
                'values': [round((int(row['present']) / int(row['total'])) * 100, 1) if int(row['total']) > 0 else 0 for row in attendance_data] if attendance_data else [100]
            },
            'grade_progress': {
                'labels': [row['grade_date'].strftime('%m/%d') for row in grade_progress] if grade_progress else ['No Data'],
                'values': [round(float(row['avg_grade']), 1) for row in grade_progress] if grade_progress else [85]
            }
        }
        
        return json.dumps(chart_data)
        
    finally:
        cursor.close()

def generate_parent_chart_data(children):
    """Generate chart data for parent dashboard (summary of all children)"""
    if not children:
        return json.dumps({})
    
    db = get_db()
    cursor = db.cursor()
    
    try:
        child_ids = [child['id'] for child in children]
        
        # Overall grade distribution for all children
        cursor.execute("""
            SELECT 
                CASE 
                    WHEN CAST(ge.score AS DECIMAL) >= 90 THEN 'A (90-100)'
                    WHEN CAST(ge.score AS DECIMAL) >= 80 THEN 'B (80-89)'
                    WHEN CAST(ge.score AS DECIMAL) >= 75 THEN 'C (75-79)'
                    WHEN CAST(ge.score AS DECIMAL) >= 70 THEN 'D (70-74)'
                    ELSE 'F (Below 70)'
                END as grade_range,
                COUNT(*) as count
            FROM grade_entries ge
            WHERE ge.student_id IN %s
            GROUP BY grade_range
            ORDER BY 
                CASE grade_range
                    WHEN 'A (90-100)' THEN 1
                    WHEN 'B (80-89)' THEN 2
                    WHEN 'C (75-79)' THEN 3
                    WHEN 'D (70-74)' THEN 4
                    WHEN 'F (Below 70)' THEN 5
                END
        """, (tuple(child_ids),))
        grade_dist = cursor.fetchall()
        
        # Children's average performance
        children_performance = []
        for child in children:
            cursor.execute("""
                SELECT AVG(CAST(ge.score AS DECIMAL)) as avg_score
                FROM grade_entries ge
                WHERE ge.student_id = %s
            """, (child['id'],))
            result = cursor.fetchone()
            avg_score = float(result['avg_score']) if result and result['avg_score'] else 0
            children_performance.append({
                'name': f"{child['first_name']} {child['last_name']}",
                'score': round(avg_score, 1)
            })
        
        # Format data for JSON
        chart_data = {
            'grade_distribution': {
                'labels': [row['grade_range'] for row in grade_dist] if grade_dist else ['No Data'],
                'values': [int(row['count']) for row in grade_dist] if grade_dist else [1]
            },
            'children_performance': {
                'labels': [child['name'] for child in children_performance],
                'values': [child['score'] for child in children_performance]
            }
        }
        
        return json.dumps(chart_data)
        
    finally:
        cursor.close()

@app.route('/dashboard')
@login_required
def dashboard():
    db = get_db()
    cursor = db.cursor()
    
    # Ensure announcements table exists
    ensure_announcements_table()
    
    if session['user_role'] == 'student':
        # Get student info
        cursor.execute("""
            SELECT s.*, c.course_name 
            FROM students s 
            LEFT JOIN courses c ON s.course_id = c.id 
            WHERE s.user_id = %s
        """, (session['user_id'],))
        student = cursor.fetchone()
        
        # Get announcements for students
        cursor.execute("""
            SELECT a.*, u.username as posted_by_name
            FROM announcements a
            JOIN users u ON a.posted_by = u.id
            WHERE a.is_active = TRUE 
            AND (a.target_audience = 'all' OR a.target_audience = 'students')
            AND (a.start_date <= CURDATE() AND (a.end_date IS NULL OR a.end_date >= CURDATE()))
            ORDER BY a.priority DESC, a.created_at DESC
            LIMIT 5
        """)
        announcements = cursor.fetchall()
        
        # Get recent grades from both grades and grade_entries tables
        cursor.execute("""
            (SELECT CAST(g.grade AS CHAR) COLLATE utf8mb4_general_ci as score, 
                    CAST(sub.subject_name AS CHAR) COLLATE utf8mb4_general_ci as subject_name, 
                    'Letter Grade' as grade_type, 
                    g.semester as term, g.school_year, g.created_at
             FROM grades g 
             JOIN subjects sub ON g.subject_id = sub.id 
             WHERE g.student_id = %s)
            UNION ALL
            (SELECT CAST(ge.score AS CHAR) COLLATE utf8mb4_general_ci as score, 
                    CAST(sub.subject_name AS CHAR) COLLATE utf8mb4_general_ci as subject_name, 
                    'Numeric Grade' as grade_type,
                    ge.term, ge.school_year, ge.created_at
             FROM grade_entries ge
             JOIN subjects sub ON ge.subject_id = sub.id 
             WHERE ge.student_id = %s)
            ORDER BY created_at DESC 
            LIMIT 5
        """, (student['id'], student['id']))
        recent_grades = cursor.fetchall()
        
        # Get attendance summary
        cursor.execute("""
            SELECT 
                COUNT(*) as total_days,
                SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present,
                SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent,
                SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END) as late
            FROM attendance 
            WHERE student_id = %s
        """, (student['id'],))
        attendance_summary = cursor.fetchone()
        
        cursor.close()
        
        # Generate chart data for students
        chart_data = generate_student_chart_data(student['id'])
        
        return render_template('dashboard.html', student=student, recent_grades=recent_grades, 
                             attendance_summary=attendance_summary, announcements=announcements, chart_data=chart_data)
    
    elif session['user_role'] == 'parent':
        # Get children
        cursor.execute("""
            SELECT s.*, c.course_name 
            FROM students s 
            LEFT JOIN courses c ON s.course_id = c.id 
            WHERE s.parent_user_id = %s
        """, (session['user_id'],))
        children = cursor.fetchall()
        cursor.close()
        
        # Generate chart data for parents (summary of all children)
        chart_data = generate_parent_chart_data(children)
        
        return render_template('dashboard.html', children=children, chart_data=chart_data)
    
    elif session['user_role'] == 'admin':
        # Get statistics
        cursor.execute("SELECT COUNT(*) as total FROM students")
        total_students = cursor.fetchone()['total']
        
        cursor.execute("SELECT COUNT(*) as total FROM users")
        total_users = cursor.fetchone()['total']
        
        cursor.execute("SELECT COUNT(*) as total FROM courses")
        total_courses = cursor.fetchone()['total']
        
        cursor.execute("SELECT COUNT(*) as total FROM teachers WHERE archived = 0")
        total_teachers = cursor.fetchone()['total']
        
        cursor.execute("SELECT COUNT(*) as total FROM teachers WHERE archived = 1")
        archived_teachers = cursor.fetchone()['total']
        # Admin analytics: students per course
        cursor.execute("""
            SELECT COALESCE(c.course_code, 'N/A') AS label, COUNT(*) AS value
            FROM students s
            LEFT JOIN courses c ON s.course_id = c.id
            GROUP BY label
            ORDER BY value DESC
        """)
        students_per_course = cursor.fetchall() or []

        # Admin analytics: users per role
        cursor.execute("""
            SELECT role AS label, COUNT(*) AS value
            FROM users
            GROUP BY role
            ORDER BY value DESC
        """)
        users_per_role = cursor.fetchall() or []

        admin_chart_json = json.dumps({
            'students_per_course': {
                'labels': [str(row['label']) for row in students_per_course],
                'values': [int(row['value'] or 0) for row in students_per_course],
            },
            'users_per_role': {
                'labels': [str(row['label']) for row in users_per_role],
                'values': [int(row['value'] or 0) for row in users_per_role],
            },
        })

        cursor.close()
        return render_template(
            'dashboard.html',
            total_students=total_students,
            total_users=total_users,
            total_courses=total_courses,
            total_teachers=total_teachers,
            archived_teachers=archived_teachers,
            admin_chart_json=admin_chart_json,
            last_updates={
                'teachers': 'Today',
                'courses': 'Today', 
                'students': 'Today',
                'archived': 'Today',
                'users': 'Today'
            }
        )

    elif session['user_role'] == 'teacher':
        # Get Teacher's Department
        cursor.execute("SELECT department FROM teachers WHERE user_id=%s", (session.get('user_id'),))
        teacher_record = cursor.fetchone()
        teacher_dept = teacher_record['department'] if teacher_record else ''

        # Count students in department
        if teacher_dept:
            cursor.execute("""
                SELECT COUNT(*) AS c 
                FROM students s 
                JOIN courses c ON s.course_id = c.id 
                WHERE UPPER(c.course_code) = UPPER(%s)
            """, (teacher_dept,))
        else:
            cursor.execute("SELECT COUNT(*) AS c FROM students")
        total_students = (cursor.fetchone() or {}).get('c', 0)

        # Count subjects in department
        if teacher_dept:
            cursor.execute("""
                SELECT COUNT(*) AS c 
                FROM subjects s 
                JOIN courses c ON s.course_id = c.id 
                WHERE UPPER(c.course_code) = UPPER(%s)
            """, (teacher_dept,))
        else:
            cursor.execute("SELECT COUNT(*) AS c FROM subjects")
        total_subjects = (cursor.fetchone() or {}).get('c', 0)

        # Chart Data: Students by Year Level (more useful for single-dept teacher)
        if teacher_dept:
            cursor.execute("""
                SELECT s.year_level AS label, COUNT(*) AS value
                FROM students s 
                JOIN courses c ON s.course_id = c.id 
                WHERE UPPER(c.course_code) = UPPER(%s)
                GROUP BY s.year_level 
                ORDER BY s.year_level
            """, (teacher_dept,))
            chart_title = f"Students by Year Level ({teacher_dept})"
        else:
            # Fallback to course distribution if no dept
            cursor.execute("""
                SELECT COALESCE(c.course_code,'N/A') AS label, COUNT(*) AS value
                FROM students s LEFT JOIN courses c ON s.course_id=c.id
                GROUP BY label ORDER BY value DESC LIMIT 8
            """)
            chart_title = "Students by Program"
        
        chart_data = cursor.fetchall() or []

        # Prepare JSON-safe chart data
        labels = [f"Grade {row['label']}" if str(row['label']).isdigit() else str(row['label']) for row in chart_data]
        values = [int(row['value'] or 0) for row in chart_data]

        chart_json = json.dumps({
            'labels': labels,
            'values': values,
        })

        cursor.close()
        return render_template(
            'dashboard.html',
            teacher_totals={
                'students': total_students,
                'subjects': total_subjects,
            },
            teacher_chart_json=chart_json,
            chart_title=chart_title
        )
    
    cursor.close()
    return render_template('dashboard.html')

# Parent profile
@app.route('/parent/profile', methods=['GET','POST'])
@login_required
def parent_profile():
    if session.get('user_role') != 'parent':
        return redirect(url_for('dashboard'))

    ensure_relations_table()
    db = get_db()
    cursor = db.cursor()

    # Update parent basic info
    if request.method == 'POST' and request.form.get('form') == 'profile':
        phone = request.form.get('phone') or None
        address = request.form.get('address') or None
        email = request.form.get('email') or None
        try:
            try:
                cursor.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(50)")
                cursor.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS address VARCHAR(255)")
            except Exception:
                pass
            cursor.execute("UPDATE users SET phone=%s, address=%s, email=%s WHERE id=%s", (phone, address, email, session.get('user_id')))
            db.commit()
            flash('Profile updated.', 'success')
        except Exception:
            db.rollback()
            flash('Failed to update profile.', 'danger')

    # Manage relations add/update
    if request.method == 'POST' and request.form.get('form') == 'relation-add':
        student_id_str = request.form.get('student_id')
        relation = request.form.get('relation')
        try:
            cursor.execute("SELECT id FROM students WHERE student_id=%s OR id=%s", (student_id_str, student_id_str))
            stu = cursor.fetchone()
            if not stu:
                raise Exception('Student not found')
            # Upsert: delete then insert
            cursor.execute("DELETE FROM student_relations WHERE user_id=%s AND student_id=%s", (session.get('user_id'), stu['id']))
            cursor.execute("INSERT INTO student_relations (student_id, user_id, relation) VALUES (%s,%s,%s)", (stu['id'], session.get('user_id'), relation))
            db.commit()
            flash('Relationship saved.', 'success')
        except Exception:
            db.rollback()
            flash('Failed to save relationship.', 'danger')

    # Load parent info (ensure optional columns exist first)
    try:
        cursor.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar VARCHAR(255)")
        cursor.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(50)")
        cursor.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS address VARCHAR(255)")
    except Exception:
        pass
    cursor.execute("SELECT id, username, email, COALESCE(avatar,'') AS avatar, COALESCE(phone,'') AS phone, COALESCE(address,'') AS address FROM users WHERE id=%s", (session.get('user_id'),))
    me = cursor.fetchone()

    # Load children via legacy and new relations
    cursor.execute(
        """
        SELECT s.id, s.first_name, s.last_name, s.student_id,
               COALESCE(r.relation, CASE WHEN s.parent_user_id=%s THEN 'Parent' ELSE NULL END) AS relation
        FROM students s
        LEFT JOIN student_relations r ON r.student_id=s.id AND r.user_id=%s
        WHERE s.parent_user_id=%s OR r.user_id=%s
        ORDER BY s.first_name, s.last_name
        """,
        (session.get('user_id'), session.get('user_id'), session.get('user_id'), session.get('user_id'))
    )
    children = cursor.fetchall()
    cursor.close()
    return render_template('parent_profile.html', me=me, children=children)

def _ensure_avatar_column(cursor):
    try:
        cursor.execute("ALTER TABLE students ADD COLUMN IF NOT EXISTS avatar VARCHAR(255)")
    except Exception:
        pass

def _allowed_image(filename):
    _, ext = os.path.splitext(filename.lower())
    return ext in ALLOWED_IMAGE_EXTENSIONS

@app.route('/student/avatar', methods=['POST'])
@login_required
def upload_avatar():
    role = session.get('user_role')
    if role not in ['student','parent']:
        flash('Permission denied.', 'danger')
        return redirect(url_for('dashboard'))

    if 'avatar' not in request.files:
        flash('No file uploaded.', 'danger')
        return redirect(url_for('student_info'))

    file = request.files['avatar']
    if not file or file.filename == '':
        flash('No selected file.', 'danger')
        return redirect(url_for('student_info'))

    if not _allowed_image(file.filename):
        flash('Invalid image type. Allowed: PNG, JPG, JPEG, GIF.', 'danger')
        return redirect(url_for('student_info'))

    # Ensure folder exists
    os.makedirs(AVATAR_UPLOAD_FOLDER, exist_ok=True)

    # Build safe filename
    safe_name = f"user_{session.get('user_id')}_{int(datetime.now().timestamp())}{os.path.splitext(file.filename)[1].lower()}"
    save_path = os.path.join(AVATAR_UPLOAD_FOLDER, safe_name)
    file.save(save_path)

    # Store relative path for template url
    relative_path = save_path.replace('\\', '/')

    db = get_db()
    cursor = db.cursor()
    try:
        if role == 'student':
            _ensure_avatar_column(cursor)
            cursor.execute("UPDATE students SET avatar=%s WHERE user_id=%s", (relative_path, session.get('user_id')))
        else:
            try:
                cursor.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar VARCHAR(255)")
            except Exception:
                pass
            cursor.execute("UPDATE users SET avatar=%s WHERE id=%s", (relative_path, session.get('user_id')))
        db.commit()
        session['avatar'] = relative_path
        flash('Profile image updated.', 'success')
    except Exception:
        db.rollback()
        flash('Failed to update profile image.', 'danger')
    finally:
        cursor.close()
    return redirect(url_for('student_info'))

# Make avatar available across templates
@app.context_processor
def inject_avatar():
    if session.get('user_id') and not session.get('avatar'):
        try:
            db = get_db()
            cursor = db.cursor()
            if session.get('user_role') == 'student':
                cursor.execute("SELECT avatar FROM students WHERE user_id=%s", (session.get('user_id'),))
                row = cursor.fetchone()
            elif session.get('user_role') == 'parent':
                # ensure users.avatar column exists
                try:
                    cursor.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar VARCHAR(255)")
                except Exception:
                    pass
                cursor.execute("SELECT avatar FROM users WHERE id=%s", (session.get('user_id'),))
                row = cursor.fetchone()
            cursor.close()
            if row and row.get('avatar'):
                session['avatar'] = row['avatar']
        except Exception:
            pass
    return {}

# Calendar events API for attendance
@app.route('/api/attendance/events')
@login_required
def attendance_events_api():
    db = get_db()
    cursor = db.cursor()
    try:
        student_internal_id = None
        # Determine which student to show
        if session.get('user_role') == 'student':
            cursor.execute("SELECT id FROM students WHERE user_id=%s", (session.get('user_id'),))
            row = cursor.fetchone()
            if row:
                student_internal_id = row['id']
        elif session.get('user_role') == 'parent':
            requested = request.args.get('student_id')
            if requested:
                # Check via legacy link or new relations
                cursor.execute(
                    """
                    SELECT s.id FROM students s
                    LEFT JOIN student_relations r ON r.student_id=s.id AND r.user_id=%s
                    WHERE s.id=%s AND (s.parent_user_id=%s OR r.user_id=%s)
                    """,
                    (session.get('user_id'), requested, session.get('user_id'), session.get('user_id'))
                )
                row = cursor.fetchone()
                if row:
                    student_internal_id = row['id']
            if not student_internal_id:
                # Pick first child via either legacy or relations
                cursor.execute(
                    """
                    SELECT s.id FROM students s
                    LEFT JOIN student_relations r ON r.student_id=s.id AND r.user_id=%s
                    WHERE s.parent_user_id=%s OR r.user_id=%s
                    ORDER BY s.id LIMIT 1
                    """,
                    (session.get('user_id'), session.get('user_id'), session.get('user_id'))
                )
                row = cursor.fetchone()
                if row:
                    student_internal_id = row['id']

        if not student_internal_id:
            return jsonify([])

        cursor.execute(
            """
            SELECT a.date, a.status, a.remarks, sub.subject_name
            FROM attendance a
            LEFT JOIN subjects sub ON a.subject_id=sub.id
            WHERE a.student_id=%s
            ORDER BY a.date ASC
            """,
            (student_internal_id,)
        )
        rows = cursor.fetchall() or []

        def status_color(s):
            m = {
                'present': '#10b981',
                'absent': '#ef4444',
                'late': '#f59e0b',
                'excused': '#3b82f6',
            }
            return m.get((s or '').lower(), '#6b7280')

        events = []
        for r in rows:
            title_bits = [str(r.get('status', '')).title()]
            if r.get('subject_name'):
                title_bits.append(str(r['subject_name']))
            if r.get('remarks'):
                title_bits.append(f"({r['remarks']})")
            events.append({
                'title': ' - '.join(title_bits),
                'start': r['date'].isoformat() if hasattr(r['date'], 'isoformat') else str(r['date']),
                'allDay': True,
                'color': status_color(r.get('status')),
            })

        return jsonify(events)
    finally:
        cursor.close()

@app.route('/api/calendar/events')
@login_required
def calendar_events():
    """API endpoint for calendar events"""
    if session['user_role'] not in ['student', 'parent']:
        return jsonify({'error': 'Unauthorized'}), 403
    
    db = get_db()
    cursor = db.cursor()
    
    try:
        events = []
        
        if session['user_role'] == 'student':
            cursor.execute("""
                SELECT s.course_id FROM students s WHERE s.user_id = %s
            """, (session['user_id'],))
            student = cursor.fetchone()
            
            if student:
                # Get exam schedules
                cursor.execute("""
                    SELECT es.*, sub.subject_name, sub.subject_code,
                           'exam' as event_type, es.exam_date as start_date
                    FROM exam_schedules es
                    JOIN subjects sub ON es.subject_id = sub.id
                    WHERE (es.course_id = %s OR es.course_id IS NULL)
                    AND es.is_active = TRUE
                    AND es.exam_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
                    AND es.exam_date <= DATE_ADD(CURDATE(), INTERVAL 6 MONTH)
                """, (student['course_id'],))
                exam_events = cursor.fetchall()
                
                for event in exam_events:
                    events.append({
                        'id': f"exam_{event['id']}",
                        'title': f"{event['exam_type'].title()}: {event['exam_title']}",
                        'start': event['start_date'].isoformat(),
                        'color': '#dc3545',
                        'extendedProps': {
                            'type': 'exam',
                            'exam_type': event['exam_type'],
                            'subject': event['subject_name'],
                            'room': event['room'],
                            'description': event['description']
                        }
                    })
                
                # Get school events
                cursor.execute("""
                    SELECT se.*, 'school_event' as event_type, se.start_date
                    FROM school_events se
                    WHERE se.is_active = TRUE
                    AND (se.target_audience = 'all' OR se.target_audience = 'students')
                    AND se.start_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
                    AND se.start_date <= DATE_ADD(CURDATE(), INTERVAL 6 MONTH)
                """)
                school_events = cursor.fetchall()
                
                for event in school_events:
                    color_map = {
                        'holiday': '#28a745',
                        'activity': '#17a2b8',
                        'meeting': '#6c757d',
                        'deadline': '#fd7e14',
                        'other': '#6f42c1'
                    }
                    
                    events.append({
                        'id': f"event_{event['id']}",
                        'title': event['title'],
                        'start': event['start_date'].isoformat(),
                        'end': event['end_date'].isoformat() if event['end_date'] else None,
                        'color': color_map.get(event['event_type'], '#6f42c1'),
                        'extendedProps': {
                            'type': 'school_event',
                            'event_type': event['event_type'],
                            'location': event['location'],
                            'description': event['description']
                        }
                    })
        
        elif session['user_role'] == 'parent':
            # For parents, get events for all their children
            cursor.execute("""
                SELECT DISTINCT s.course_id FROM students s WHERE s.parent_user_id = %s
            """, (session['user_id'],))
            children_courses = cursor.fetchall()
            
            course_ids = [child['course_id'] for child in children_courses]
            if course_ids:
                # Get exam schedules for all children
                cursor.execute(f"""
                    SELECT es.*, sub.subject_name, sub.subject_code,
                           'exam' as event_type, es.exam_date as start_date
                    FROM exam_schedules es
                    JOIN subjects sub ON es.subject_id = sub.id
                    WHERE (es.course_id IN ({','.join(['%s'] * len(course_ids))}) OR es.course_id IS NULL)
                    AND es.is_active = TRUE
                    AND es.exam_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
                    AND es.exam_date <= DATE_ADD(CURDATE(), INTERVAL 6 MONTH)
                """, course_ids)
                exam_events = cursor.fetchall()
                
                for event in exam_events:
                    events.append({
                        'id': f"exam_{event['id']}",
                        'title': f"{event['exam_type'].title()}: {event['exam_title']}",
                        'start': event['start_date'].isoformat(),
                        'color': '#dc3545',
                        'extendedProps': {
                            'type': 'exam',
                            'exam_type': event['exam_type'],
                            'subject': event['subject_name'],
                            'room': event['room'],
                            'description': event['description']
                        }
                    })
        
        return jsonify(events)
    
    finally:
        cursor.close()

@app.route('/api/reminders/create', methods=['POST'])
@login_required
def create_reminder():
    """Create event reminder"""
    if session['user_role'] not in ['student', 'parent']:
        return jsonify({'error': 'Unauthorized'}), 403
    
    data = request.get_json()
    event_id = data.get('event_id')
    event_type = data.get('event_type')
    reminder_date = data.get('reminder_date')
    
    if not all([event_id, event_type, reminder_date]):
        return jsonify({'error': 'Missing required fields'}), 400
    
    db = get_db()
    cursor = db.cursor()
    
    try:
        # Check if reminder already exists
        cursor.execute("""
            SELECT id FROM event_reminders 
            WHERE user_id = %s AND event_id = %s AND event_type = %s
        """, (session['user_id'], event_id, event_type))
        existing = cursor.fetchone()
        
        if existing:
            return jsonify({'error': 'Reminder already exists'}), 409
        
        # Create reminder
        cursor.execute("""
            INSERT INTO event_reminders (user_id, event_id, event_type, reminder_date)
            VALUES (%s, %s, %s, %s)
        """, (session['user_id'], event_id, event_type, reminder_date))
        
        db.commit()
        return jsonify({'success': True, 'message': 'Reminder created successfully'})
    
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    
    finally:
        cursor.close()

def calculate_attendance_analytics(student_id, cursor):
    """Calculate comprehensive attendance analytics"""
    # Get all attendance records
    cursor.execute("""
        SELECT a.*, sub.subject_name 
        FROM attendance a 
        LEFT JOIN subjects sub ON a.subject_id = sub.id 
        WHERE a.student_id = %s 
        ORDER BY a.date DESC
    """, (student_id,))
    attendance_records = cursor.fetchall()
    
    if not attendance_records:
        return {}
    
    # Calculate basic summary
    summary = {
        'total_days': len(attendance_records),
        'present': sum(1 for a in attendance_records if a['status'] == 'present'),
        'absent': sum(1 for a in attendance_records if a['status'] == 'absent'),
        'late': sum(1 for a in attendance_records if a['status'] == 'late'),
        'excused': sum(1 for a in attendance_records if a['status'] == 'excused')
    }
    
    # Calculate attendance rate
    summary['attendance_rate'] = round((summary['present'] + summary['excused']) / summary['total_days'] * 100, 1) if summary['total_days'] > 0 else 0
    
    # Monthly trends
    monthly_trends = {}
    for record in attendance_records:
        month_key = record['date'].strftime('%Y-%m')
        if month_key not in monthly_trends:
            monthly_trends[month_key] = {'present': 0, 'absent': 0, 'late': 0, 'excused': 0, 'total': 0}
        
        monthly_trends[month_key][record['status']] += 1
        monthly_trends[month_key]['total'] += 1
    
    # Calculate monthly rates
    for month, data in monthly_trends.items():
        data['attendance_rate'] = round((data['present'] + data['excused']) / data['total'] * 100, 1) if data['total'] > 0 else 0
    
    # Subject-wise attendance
    subject_attendance = {}
    for record in attendance_records:
        subject = record['subject_name'] or 'General'
        if subject not in subject_attendance:
            subject_attendance[subject] = {'present': 0, 'absent': 0, 'late': 0, 'excused': 0, 'total': 0}
        
        subject_attendance[subject][record['status']] += 1
        subject_attendance[subject]['total'] += 1
    
    # Calculate subject rates
    for subject, data in subject_attendance.items():
        data['attendance_rate'] = round((data['present'] + data['excused']) / data['total'] * 100, 1) if data['total'] > 0 else 0
    
    # Absence patterns
    recent_absences = [a for a in attendance_records if a['status'] == 'absent'][:5]
    consecutive_absences = calculate_consecutive_absences(attendance_records)
    
    # Attendance alerts
    alerts = []
    if summary['attendance_rate'] < 75:
        alerts.append({
            'type': 'danger',
            'message': f'Low attendance rate: {summary["attendance_rate"]}%'
        })
    
    if consecutive_absences >= 3:
        alerts.append({
            'type': 'warning',
            'message': f'{consecutive_absences} consecutive absences detected'
        })
    
    if summary['late'] > summary['present'] * 0.2:  # More than 20% tardiness
        alerts.append({
            'type': 'info',
            'message': 'High tardiness rate detected'
        })
    
    return {
        'summary': summary,
        'monthly_trends': dict(sorted(monthly_trends.items(), reverse=True)[:6]),  # Last 6 months
        'subject_attendance': subject_attendance,
        'recent_absences': recent_absences,
        'consecutive_absences': consecutive_absences,
        'alerts': alerts
    }

def calculate_consecutive_absences(attendance_records):
    """Calculate consecutive absences"""
    if not attendance_records:
        return 0
    
    consecutive = 0
    max_consecutive = 0
    
    for record in sorted(attendance_records, key=lambda x: x['date'], reverse=True):
        if record['status'] == 'absent':
            consecutive += 1
            max_consecutive = max(max_consecutive, consecutive)
        else:
            consecutive = 0
    
    return max_consecutive

@app.route('/api/attendance/notifications')
@login_required
def attendance_notifications():
    """API endpoint for attendance notifications"""
    if session['user_role'] not in ['student', 'parent']:
        return jsonify({'error': 'Unauthorized'}), 403
    
    db = get_db()
    cursor = db.cursor()
    
    try:
        if session['user_role'] == 'student':
            cursor.execute("""
                SELECT s.id FROM students s WHERE s.user_id = %s
            """, (session['user_id'],))
            student = cursor.fetchone()
            
            if student:
                analytics = calculate_attendance_analytics(student['id'], cursor)
                return jsonify({
                    'notifications': analytics.get('alerts', []),
                    'attendance_rate': analytics['summary']['attendance_rate']
                })
        
        elif session['user_role'] == 'parent':
            cursor.execute("""
                SELECT s.id, s.first_name, s.last_name FROM students s WHERE s.parent_user_id = %s
            """, (session['user_id'],))
            children = cursor.fetchall()
            
            notifications = []
            for child in children:
                child_analytics = calculate_attendance_analytics(child['id'], cursor)
                for alert in child_analytics.get('alerts', []):
                    alert['student_name'] = f"{child['first_name']} {child['last_name']}"
                    notifications.append(alert)
            
            return jsonify({'notifications': notifications})
    
    finally:
        cursor.close()
    
    return jsonify({'notifications': []})

def calculate_grade_analytics(student_id, cursor):
    """Calculate comprehensive grade analytics for numeric grades"""
    # Get all grades with subject info
    cursor.execute("""
        SELECT ge.*, sub.subject_name, sub.subject_code, sub.units
        FROM grade_entries ge
        JOIN subjects sub ON ge.subject_id = sub.id
        WHERE ge.student_id = %s
        ORDER BY ge.school_year, ge.term
    """, (student_id,))
    grades = cursor.fetchall()
    
    if not grades:
        return {}
    
    # Calculate GPA by term
    term_gpa = {}
    subject_performance = {}
    grade_trends = []
    
    for grade in grades:
        term = f"{grade['school_year']} - {grade['term']}"
        
        if term not in term_gpa:
            term_gpa[term] = {'total_score': 0, 'count': 0, 'subjects': []}
        
        term_gpa[term]['total_score'] += grade['score']
        term_gpa[term]['count'] += 1
        term_gpa[term]['subjects'].append({
            'name': grade['subject_name'],
            'score': grade['score'],
            'code': grade['subject_code']
        })
        
        # Track subject performance
        subject = grade['subject_name']
        if subject not in subject_performance:
            subject_performance[subject] = []
        subject_performance[subject].append(grade['score'])
    
    # Calculate average GPA
    total_score = sum(t['total_score'] for t in term_gpa.values())
    total_count = sum(t['count'] for t in term_gpa.values())
    overall_gpa = total_score / total_count if total_count > 0 else 0
    
    # Calculate grade trends
    for term in sorted(term_gpa.keys()):
        avg_score = term_gpa[term]['total_score'] / term_gpa[term]['count']
        grade_trends.append({
            'term': term,
            'average': round(avg_score, 2),
            'subject_count': term_gpa[term]['count']
        })
    
    # Class standing calculation
    total_scores = [g['score'] for g in grades]
    average_score = sum(total_scores) / len(total_scores) if total_scores else 0
    
    return {
        'overall_gpa': round(overall_gpa, 2),
        'term_gpa': term_gpa,
        'grade_trends': grade_trends,
        'subject_performance': subject_performance,
        'average_score': round(average_score, 2),
        'total_subjects': len(set(g['subject_name'] for g in grades)),
        'highest_grade': max(total_scores) if total_scores else 0,
        'lowest_grade': min(total_scores) if total_scores else 0,
        'grade_distribution': calculate_grade_distribution(total_scores)
    }

def calculate_legacy_grade_analytics(grades, cursor):
    """Calculate analytics for legacy letter grades"""
    if not grades:
        return {}
    
    grade_points = {'A': 4.0, 'B': 3.0, 'C': 2.0, 'D': 1.0, 'F': 0.0}
    total_points = 0
    total_units = 0
    
    for grade in grades:
        if grade['grade'] in grade_points:
            total_points += grade_points[grade['grade']] * grade['units']
            total_units += grade['units']
    
    gpa = (total_points / total_units) if total_units > 0 else 0
    
    # Grade distribution
    grade_counts = {}
    for grade in grades:
        letter = grade['grade']
        grade_counts[letter] = grade_counts.get(letter, 0) + 1
    
    return {
        'gpa': round(gpa, 2),
        'total_units': total_units,
        'grade_counts': grade_counts,
        'total_subjects': len(grades),
        'average_grade': calculate_average_letter_grade(grades)
    }

def calculate_grade_distribution(scores):
    """Calculate grade distribution for numeric scores"""
    if not scores:
        return {}
    
    distribution = {
        'excellent (90-100)': 0,
        'good (85-89)': 0,
        'satisfactory (80-84)': 0,
        'fair (75-79)': 0,
        'needs_improvement (below 75)': 0
    }
    
    for score in scores:
        if score >= 90:
            distribution['excellent (90-100)'] += 1
        elif score >= 85:
            distribution['good (85-89)'] += 1
        elif score >= 80:
            distribution['satisfactory (80-84)'] += 1
        elif score >= 75:
            distribution['fair (75-79)'] += 1
        else:
            distribution['needs_improvement (below 75)'] += 1
    
    return distribution

def calculate_average_letter_grade(grades):
    """Calculate average letter grade"""
    grade_points = {'A': 4.0, 'B': 3.0, 'C': 2.0, 'D': 1.0, 'F': 0.0}
    total_points = sum(grade_points.get(g['grade'], 0) for g in grades)
    avg_points = total_points / len(grades) if grades else 0
    
    if avg_points >= 3.5:
        return 'A'
    elif avg_points >= 2.5:
        return 'B'
    elif avg_points >= 1.5:
        return 'C'
    elif avg_points >= 0.5:
        return 'D'
    else:
        return 'F'

# Student Information System
@app.route('/student/info')
@login_required
def student_info():
    db = get_db()
    cursor = db.cursor()
    
    if session['user_role'] == 'student':
        cursor.execute("""
            SELECT s.*, c.course_name, u.email, u.username
            FROM students s 
            LEFT JOIN courses c ON s.course_id = c.id 
            LEFT JOIN users u ON s.user_id = u.id
            WHERE s.user_id = %s
        """, (session['user_id'],))
        student = cursor.fetchone()
        cursor.close()
        return render_template('student_info.html', student=student)
    
    elif session['user_role'] == 'parent':
        cursor.execute("""
            SELECT s.*, c.course_name, u.email, u.username
            FROM students s 
            LEFT JOIN courses c ON s.course_id = c.id 
            LEFT JOIN users u ON s.user_id = u.id
            WHERE s.parent_user_id = %s
        """, (session['user_id'],))
        children = cursor.fetchall()
        cursor.close()
        return render_template('student_info.html', students=children)
    
    elif session['user_role'] in ['teacher', 'admin']:
        # Get search parameters
        search_query = request.args.get('search', '')
        course_filter = request.args.get('course', '')
        year_filter = request.args.get('year', '')
        
        # Build base query
        query = """
            SELECT s.*, c.course_name, u.email, u.username
            FROM students s 
            LEFT JOIN courses c ON s.course_id = c.id 
            LEFT JOIN users u ON s.user_id = u.id
            WHERE 1=1
        """
        params = []
        
        # Add search conditions
        if search_query:
            query += " AND (s.first_name LIKE %s OR s.last_name LIKE %s OR s.student_id LIKE %s)"
            search_term = f"%{search_query}%"
            params.extend([search_term, search_term, search_term])
        
        if course_filter:
            query += " AND s.course_id = %s"
            params.append(course_filter)
            
        if year_filter:
            query += " AND s.year_level = %s"
            params.append(year_filter)
        
        # Add order by
        query += " ORDER BY s.last_name, s.first_name"
        
        cursor.execute(query, params)
        students = cursor.fetchall()
        
        # Get filter options
        cursor.execute("SELECT id, course_name FROM courses ORDER BY course_name")
        courses = cursor.fetchall()
        
        cursor.close()
        return render_template('student_info.html', students=students, courses=courses, 
                             search_query=search_query, course_filter=course_filter, 
                             year_filter=year_filter)

@app.route('/api/student/search')
@login_required
def api_student_search():
    """API endpoint for student search with autocomplete"""
    if session['user_role'] not in ['teacher', 'admin']:
        return jsonify({'error': 'Unauthorized'}), 403
    
    search_query = request.args.get('q', '')
    if len(search_query) < 2:
        return jsonify([])
    
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute("""
        SELECT s.id, s.first_name, s.last_name, s.student_id, c.course_name
        FROM students s 
        LEFT JOIN courses c ON s.course_id = c.id 
        WHERE (s.first_name LIKE %s OR s.last_name LIKE %s OR s.student_id LIKE %s)
        AND s.status = 'active'
        ORDER BY s.last_name, s.first_name
        LIMIT 10
    """, (f"%{search_query}%", f"%{search_query}%", f"%{search_query}%"))
    
    students = cursor.fetchall()
    cursor.close()
    
    return jsonify(students)

@app.route('/student/update', methods=['POST'])
@login_required
def update_student_info():
    if session['user_role'] not in ['student', 'admin']:
        flash('Permission denied', 'danger')
        return redirect(url_for('student_info'))
    
    db = get_db()
    cursor = db.cursor()
    
    if session['user_role'] == 'student':
        student_id = request.form.get('student_id')
        
        # Academic (Editable)
        lrn = request.form.get('lrn')
        branch = request.form.get('branch')
        satellite = request.form.get('satellite')
        college = request.form.get('college')
        current_semester = request.form.get('current_semester')
        
        # Personal
        extension_name = request.form.get('extension_name')
        phone = request.form.get('phone')
        blood_group = request.form.get('blood_group')
        address = request.form.get('address')
        
        # Guardian
        guardian_name = request.form.get('guardian_name')
        guardian_relation = request.form.get('guardian_relation')
        guardian_email = request.form.get('guardian_email')
        guardian_address = request.form.get('guardian_address')
        
        # Parents
        father_first = request.form.get('father_first_name')
        father_middle = request.form.get('father_middle_name')
        father_last = request.form.get('father_last_name')
        mother_first = request.form.get('mother_first_name')
        mother_middle = request.form.get('mother_middle_name')
        mother_last = request.form.get('mother_last_name')
        
        cursor.execute("""
            UPDATE students 
            SET 
                lrn=%s, branch=%s, satellite=%s, college=%s, current_semester=%s,
                extension_name=%s, phone=%s, blood_group=%s, address=%s,
                guardian_name=%s, guardian_relation=%s, guardian_email=%s, guardian_address=%s,
                father_first_name=%s, father_middle_name=%s, father_last_name=%s,
                mother_first_name=%s, mother_middle_name=%s, mother_last_name=%s
            WHERE id = %s AND user_id = %s
        """, (
            lrn, branch, satellite, college, current_semester,
            extension_name, phone, blood_group, address,
            guardian_name, guardian_relation, guardian_email, guardian_address,
            father_first, father_middle, father_last,
            mother_first, mother_middle, mother_last,
            student_id, session['user_id']
        ))
        db.commit()
        flash('Student information updated successfully', 'success')
    
    cursor.close()
    return redirect(url_for('student_info'))

# Grades and Report Card
@app.route('/grades')
@login_required
def grades():
    db = get_db()
    cursor = db.cursor()
    
    if session['user_role'] == 'student':
        cursor.execute("""
            SELECT s.id AS id FROM students s WHERE s.user_id = %s
        """, (session['user_id'],))
        student = cursor.fetchone()
        
        if student:
            # Try numeric term grades first
            cursor.execute(
                """
                SELECT ge.*, sub.subject_name, sub.subject_code
                FROM grade_entries ge
                JOIN subjects sub ON ge.subject_id=sub.id
                WHERE ge.student_id=%s
                ORDER BY sub.subject_name, FIELD(ge.term,'Q1','Q2','Q3','Final'), ge.created_at
                """,
                (student['id'],)
            )
            grade_entries = cursor.fetchall()

            if grade_entries:
                # Calculate grade analytics
                analytics = calculate_grade_analytics(student['id'], cursor)
                cursor.close()
                return render_template('grades.html', grade_entries=grade_entries, analytics=analytics)
            
            # Fallback to legacy letter grades if present
            cursor.execute("""
                SELECT g.*, sub.subject_name, sub.subject_code, sub.units
                FROM grades g 
                JOIN subjects sub ON g.subject_id = sub.id 
                WHERE g.student_id = %s 
                ORDER BY sub.subject_name
            """, (student['id'],))
            grades = cursor.fetchall()
            
            # Calculate GPA and analytics
            analytics = calculate_legacy_grade_analytics(grades, cursor)
            cursor.close()
            return render_template('grades.html', grades=grades, analytics=analytics)
    
    elif session['user_role'] == 'parent':
        cursor.execute("""
            SELECT DISTINCT s.id, s.first_name, s.last_name
            FROM students s
            LEFT JOIN student_relations r ON r.student_id=s.id AND r.user_id=%s
            WHERE s.parent_user_id = %s OR r.user_id = %s
            ORDER BY s.first_name, s.last_name
        """, (session['user_id'], session['user_id'], session['user_id']))
        children = cursor.fetchall()
        cursor.close()
        return render_template('grades.html', children=children)
    
    cursor.close()
    return redirect(url_for('dashboard'))

@app.route('/grades/<int:student_id>')
@login_required
def view_child_grades(student_id):
    if session['user_role'] != 'parent':
        return redirect(url_for('grades'))
    
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        SELECT s.id FROM students s 
        LEFT JOIN student_relations r ON r.student_id=s.id AND r.user_id=%s
        WHERE s.id = %s AND (s.parent_user_id = %s OR r.user_id = %s)
    """, (session['user_id'], student_id, session['user_id'], session['user_id']))
    student = cursor.fetchone()
    
    if student:
        # Prefer numeric entries
        cursor.execute(
            """
            SELECT ge.*, sub.subject_name, sub.subject_code
            FROM grade_entries ge
            JOIN subjects sub ON ge.subject_id=sub.id
            WHERE ge.student_id=%s
            ORDER BY sub.subject_name, FIELD(ge.term,'Q1','Q2','Q3','Final'), ge.created_at
            """,
            (student_id,)
        )
        grade_entries = cursor.fetchall()
        if grade_entries:
            cursor.close()
            return render_template('grades.html', grade_entries=grade_entries, viewing_child=True)

        # Fallback to legacy grades
        cursor.execute("""
            SELECT g.*, sub.subject_name, sub.subject_code, sub.units
            FROM grades g 
            JOIN subjects sub ON g.subject_id = sub.id 
            WHERE g.student_id = %s 
            ORDER BY sub.subject_name
        """, (student_id,))
        grades = cursor.fetchall()
        total_points = 0
        total_units = 0
        grade_points = {'A': 4.0, 'B': 3.0, 'C': 2.0, 'D': 1.0, 'F': 0.0}
        for grade in grades:
            if grade['grade'] in grade_points:
                total_points += grade_points[grade['grade']] * grade['units']
                total_units += grade['units']
        gpa = (total_points / total_units) if total_units > 0 else 0
        cursor.close()
        return render_template('grades.html', grades=grades, gpa=round(gpa, 2), viewing_child=True)
    
    cursor.close()
    return redirect(url_for('grades'))

# Attendance Monitoring
@app.route('/attendance')
@login_required
def attendance():
    db = get_db()
    cursor = db.cursor()
    
    if session['user_role'] == 'student':
        cursor.execute("""
            SELECT s.id AS id FROM students s WHERE s.user_id = %s
        """, (session['user_id'],))
        student = cursor.fetchone()
        
        if student:
            cursor.execute("""
                SELECT a.*, sub.subject_name 
                FROM attendance a 
                LEFT JOIN subjects sub ON a.subject_id = sub.id 
                WHERE a.student_id = %s 
                ORDER BY a.date DESC 
                LIMIT 30
            """, (student['id'],))
            attendance_records = cursor.fetchall()
            
            # Get comprehensive analytics
            analytics = calculate_attendance_analytics(student['id'], cursor)
            
            cursor.close()
            return render_template('attendance.html', attendance_records=attendance_records, analytics=analytics)
    
    elif session['user_role'] == 'parent':
        cursor.execute("""
            SELECT s.id, s.first_name, s.last_name FROM students s WHERE s.parent_user_id = %s
        """, (session['user_id'],))
        children = cursor.fetchall()
        cursor.close()
        return render_template('attendance.html', children=children)
    
    cursor.close()
    return redirect(url_for('dashboard'))

@app.route('/attendance/<int:student_id>')
@login_required
def view_child_attendance(student_id):
    if session['user_role'] != 'parent':
        return redirect(url_for('attendance'))
    
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        SELECT s.id FROM students s 
        WHERE s.id = %s AND s.parent_user_id = %s
    """, (student_id, session['user_id']))
    student = cursor.fetchone()
    
    if student:
        cursor.execute("""
            SELECT a.*, sub.subject_name 
            FROM attendance a 
            LEFT JOIN subjects sub ON a.subject_id = sub.id 
            WHERE a.student_id = %s 
            ORDER BY a.date DESC 
            LIMIT 30
        """, (student_id,))
        attendance_records = cursor.fetchall()
        
        cursor.execute("""
            SELECT 
                COUNT(*) as total_days,
                SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present,
                SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent,
                SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END) as late
            FROM attendance 
            WHERE student_id = %s
        """, (student_id,))
        summary = cursor.fetchone()
        
        cursor.close()
        return render_template('attendance.html', attendance_records=attendance_records, summary=summary, viewing_child=True)
    
    cursor.close()
    return redirect(url_for('attendance'))

# Class Schedule and Calendar
@app.route('/schedule')
@login_required
def schedule():
    db = get_db()
    cursor = db.cursor()
    
    if session['user_role'] == 'student':
        cursor.execute("""
            SELECT s.id as student_id, s.course_id FROM students s WHERE s.user_id = %s
        """, (session['user_id'],))
        student = cursor.fetchone()
        
        if student:
            # Get regular class schedules
            cursor.execute("""
                SELECT sch.*, sub.subject_name, sub.subject_code, t.first_name as teacher_first, t.last_name as teacher_last
                FROM schedules sch
                JOIN subjects sub ON sch.subject_id = sub.id
                LEFT JOIN teachers t ON sch.teacher_id = t.id
                WHERE sch.course_id = %s
                ORDER BY sch.day_of_week, sch.start_time
            """, (student['course_id'],))
            schedules = cursor.fetchall()
            
            # Get exam schedules for student's course
            cursor.execute("""
                SELECT es.*, sub.subject_name, sub.subject_code
                FROM exam_schedules es
                JOIN subjects sub ON es.subject_id = sub.id
                WHERE (es.course_id = %s OR es.course_id IS NULL)
                AND es.is_active = TRUE
                AND es.exam_date >= CURDATE()
                ORDER BY es.exam_date ASC
            """, (student['course_id'],))
            exam_schedules = cursor.fetchall()
            
            # Get school events for students
            cursor.execute("""
                SELECT se.*
                FROM school_events se
                WHERE se.is_active = TRUE
                AND (se.target_audience = 'all' OR se.target_audience = 'students')
                AND (se.start_date >= CURDATE() OR (se.start_date <= CURDATE() AND (se.end_date IS NULL OR se.end_date >= CURDATE())))
                ORDER BY se.start_date ASC
                LIMIT 20
            """)
            events = cursor.fetchall()
            
            # Get upcoming reminders for student
            cursor.execute("""
                SELECT er.*, 
                       CASE er.event_type
                           WHEN 'exam' THEN (SELECT exam_title FROM exam_schedules WHERE id = er.event_id)
                           WHEN 'school_event' THEN (SELECT title FROM school_events WHERE id = er.event_id)
                       END as event_title
                FROM event_reminders er
                WHERE er.user_id = %s AND er.is_sent = FALSE AND er.reminder_date >= CURDATE()
                ORDER BY er.reminder_date ASC
            """, (session['user_id'],))
            reminders = cursor.fetchall()
            
            cursor.close()
            return render_template('schedule.html', schedules=schedules, exam_schedules=exam_schedules, 
                                 events=events, reminders=reminders)
    
    elif session['user_role'] == 'parent':
        cursor.execute("""
            SELECT DISTINCT s.id, s.first_name, s.last_name, s.course_id
            FROM students s
            LEFT JOIN student_relations r ON r.student_id=s.id AND r.user_id=%s
            WHERE s.parent_user_id=%s OR r.user_id=%s
            ORDER BY s.first_name, s.last_name
        """, (session['user_id'], session['user_id'], session['user_id']))
        children = cursor.fetchall()
        cursor.close()
        return render_template('schedule.html', children=children)
    
    cursor.close()
    return redirect(url_for('dashboard'))

# Enrollment and Registration
@app.route('/enrollment')
@login_required
def enrollment():
    if session['user_role'] != 'student':
        flash('This page is only for students', 'danger')
        return redirect(url_for('dashboard'))
    
    db = get_db()
    cursor = db.cursor()
    
    # Get student info
    cursor.execute("""
        SELECT s.*, c.course_name FROM students s 
        LEFT JOIN courses c ON s.course_id = c.id 
        WHERE s.user_id = %s
    """, (session['user_id'],))
    student = cursor.fetchone()
    
    if not student:
        cursor.close()
        flash('Student record not found', 'danger')
        return redirect(url_for('dashboard'))
    
    # Get available subjects for the course
    cursor.execute("""
        SELECT sub.*, sch.day_of_week, sch.start_time, sch.end_time, sch.room
        FROM subjects sub
        LEFT JOIN schedules sch ON sub.id = sch.subject_id AND sch.course_id = %s
        WHERE sub.course_id = %s
        ORDER BY sub.subject_name
    """, (student['course_id'], student['course_id']))
    available_subjects = cursor.fetchall()
    
    # Get enrolled subjects
    cursor.execute("""
        SELECT e.*, sub.subject_name, sub.subject_code, sub.units
        FROM enrollments e
        JOIN subjects sub ON e.subject_id = sub.id
        WHERE e.student_id = %s AND e.status = 'enrolled'
    """, (student['id'],))
    enrolled_subjects = cursor.fetchall()
    
    cursor.close()
    return render_template('enrollment.html', student=student, available_subjects=available_subjects, enrolled_subjects=enrolled_subjects)

@app.route('/enrollment/enroll', methods=['POST'])
@login_required
def enroll_subject():
    if session['user_role'] != 'student':
        return jsonify({'success': False, 'message': 'Permission denied'})
    
    subject_id = request.json.get('subject_id')
    
    db = get_db()
    cursor = db.cursor()
    
    # Get student
    cursor.execute("SELECT id FROM students WHERE user_id = %s", (session['user_id'],))
    student = cursor.fetchone()
    
    if not student:
        cursor.close()
        return jsonify({'success': False, 'message': 'Student not found'})
    
    # Check if already enrolled
    cursor.execute("SELECT * FROM enrollments WHERE student_id = %s AND subject_id = %s AND status = 'enrolled'", 
                (student['id'], subject_id))
    existing = cursor.fetchone()
    
    if existing:
        cursor.close()
        return jsonify({'success': False, 'message': 'Already enrolled in this subject'})
    
    # Enroll
    cursor.execute("""
        INSERT INTO enrollments (student_id, subject_id, status, enrolled_at) 
        VALUES (%s, %s, 'enrolled', NOW())
    """, (student['id'], subject_id))
    db.commit()
    cursor.close()
    
    return jsonify({'success': True, 'message': 'Successfully enrolled'})

@app.route('/enrollment/drop', methods=['POST'])
@login_required
def drop_subject():
    if session['user_role'] != 'student':
        return jsonify({'success': False, 'message': 'Permission denied'})
    
    enrollment_id = request.json.get('enrollment_id')
    
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        UPDATE enrollments 
        SET status = 'dropped', dropped_at = NOW() 
        WHERE id = %s AND student_id IN (SELECT id FROM students WHERE user_id = %s)
    """, (enrollment_id, session['user_id']))
    db.commit()
    cursor.close()
    
    return jsonify({'success': True, 'message': 'Subject dropped successfully'})

@app.route('/admin/teachers/<int:teacher_id>/archive', methods=['POST'])
@login_required
@role_required(['admin'])
def admin_archive_teacher(teacher_id):
    """Archive a teacher (soft delete)."""
    if session.get('user_role') != 'admin':
        flash('Permission denied.', 'danger')
        return redirect(url_for('admin_teachers'))
    
    db = get_db()
    cursor = db.cursor()
    try:
        # Archive the teacher by setting archived flag
        cursor.execute("UPDATE teachers SET archived = 1 WHERE id = %s", (teacher_id,))
        db.commit()
        flash('Teacher archived successfully.', 'success')
    except Exception:
        db.rollback()
        flash('Failed to archive teacher.', 'danger')
    finally:
        cursor.close()
    return redirect(url_for('admin_teachers'))

@app.route('/admin/teachers/<int:teacher_id>/delete', methods=['POST'])
@login_required
@role_required(['admin'])
def admin_delete_teacher(teacher_id):
    """Permanently delete a teacher."""
    if session.get('user_role') != 'admin':
        flash('Permission denied.', 'danger')
        return redirect(url_for('admin_teachers'))
    
    db = get_db()
    cursor = db.cursor()
    try:
        # Get the user_id associated with the teacher
        cursor.execute("SELECT user_id FROM teachers WHERE id = %s", (teacher_id,))
        teacher = cursor.fetchone()
        if not teacher:
            flash('Teacher not found.', 'danger')
            return redirect(url_for('admin_teachers'))
        
        # Delete the teacher record
        cursor.execute("DELETE FROM teachers WHERE id = %s", (teacher_id,))
        
        # Optionally also delete the user account
        if teacher['user_id']:
            cursor.execute("DELETE FROM users WHERE id = %s", (teacher['user_id'],))
        
        db.commit()
        flash('Teacher deleted permanently.', 'success')
    except Exception:
        db.rollback()
        flash('Failed to delete teacher.', 'danger')
    finally:
        cursor.close()
    return redirect(url_for('admin_teachers'))

@app.route('/admin/teachers/archived')
@login_required
@role_required(['admin'])
def admin_archived_teachers():
    """View archived teachers with option to restore."""
    db = get_db()
    cursor = db.cursor()
    
    # Fetch archived teachers
    cursor.execute("""
        SELECT t.id, t.first_name, t.last_name, t.email, t.department, u.username, u.avatar
        FROM teachers t LEFT JOIN users u ON t.user_id=u.id
        WHERE t.archived = 1
        ORDER BY t.first_name, t.last_name
    """)
    archived_teachers = cursor.fetchall()
    cursor.close()
    
    return render_template('admin_teachers_archived.html', teachers=archived_teachers)

@app.route('/admin/teachers/<int:teacher_id>/restore', methods=['POST'])
@login_required
@role_required(['admin'])
def admin_restore_teacher(teacher_id):
    """Restore an archived teacher."""
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute("UPDATE teachers SET archived = 0 WHERE id = %s", (teacher_id,))
        db.commit()
        flash('Teacher restored successfully.', 'success')
    except Exception:
        db.rollback()
        flash('Failed to restore teacher.', 'danger')
    finally:
        cursor.close()
    return redirect(url_for('admin_archived_teachers'))

@app.route('/admin/courses', methods=['GET','POST'])
@login_required
@role_required(['admin'])
def admin_courses():
    """Manage courses: add, edit, delete."""
    db = get_db()
    cursor = db.cursor()
    
    if request.method == 'POST':
        course_code = request.form.get('course_code','').strip()
        course_name = request.form.get('course_name','').strip()
        description = request.form.get('description','').strip() or None
        action = request.form.get('action')
        course_id = request.form.get('course_id')
        
        if action == 'add':
            if course_code and course_name:
                try:
                    cursor.execute("SELECT id FROM courses WHERE course_code=%s", (course_code,))
                    if cursor.fetchone():
                        flash('Course code already exists.', 'danger')
                    else:
                        cursor.execute("""
                            INSERT INTO courses (course_code, course_name, description)
                            VALUES (%s,%s,%s)
                        """, (course_code, course_name, description))
                        db.commit()
                        flash('Course added successfully.', 'success')
                except Exception:
                    db.rollback()
                    flash('Failed to add course.', 'danger')
            else:
                flash('Course code and name are required.', 'danger')
        
        elif action == 'edit' and course_id:
            if course_code and course_name:
                try:
                    cursor.execute("""
                        UPDATE courses 
                        SET course_code=%s, course_name=%s, description=%s
                        WHERE id=%s
                    """, (course_code, course_name, description, course_id))
                    db.commit()
                    flash('Course updated successfully.', 'success')
                except Exception:
                    db.rollback()
                    flash('Failed to update course.', 'danger')
            else:
                flash('Course code and name are required.', 'danger')
        
        elif action == 'delete' and course_id:
            try:
                # Check if course is being used
                cursor.execute("SELECT COUNT(*) as count FROM subjects WHERE course_id=%s", (course_id,))
                if cursor.fetchone()['count'] > 0:
                    flash('Cannot delete: course is being used by subjects.', 'danger')
                else:
                    cursor.execute("DELETE FROM courses WHERE id=%s", (course_id,))
                    db.commit()
                    flash('Course deleted successfully.', 'success')
            except Exception:
                db.rollback()
                flash('Failed to delete course.', 'danger')
    
    # Fetch all courses
    cursor.execute("SELECT * FROM courses ORDER BY course_code")
    courses = cursor.fetchall()
    cursor.close()
    
    return render_template('admin_courses.html', courses=courses)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')


