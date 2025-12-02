"""
Mobile API Endpoints for Student Portal Android App
This module provides REST API endpoints for the Android application
"""
from flask import Blueprint, request, jsonify
from werkzeug.security import check_password_hash
import pymysql
import pymysql.cursors

mobile_api = Blueprint('mobile_api', __name__, url_prefix='/api/mobile')

# MySQL Configuration
MYSQL_HOST = 'localhost'
MYSQL_USER = 'portal'
MYSQL_PASSWORD = '123456789'
MYSQL_DB = 'student_portal'
MYSQL_PORT = 3308

def get_mobile_db():
    """Get database connection for mobile API"""
    return pymysql.connect(
        host=MYSQL_HOST,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DB,
        port=MYSQL_PORT,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=False,
        charset='utf8mb4'
    )

@mobile_api.route('/login', methods=['POST'])
def mobile_login():
    """
    Mobile Login Endpoint
    POST /api/mobile/login
    Body: {"username": "...", "password": "..."}
    Returns: User info with token
    """
    try:
        data = request.get_json()
        username = data.get('username', '').strip()
        password = data.get('password', '')
        
        if not username or not password:
            return jsonify({'success': False, 'message': 'Username and password required'}), 400
        
        db = get_mobile_db()
        cur = db.cursor()
        
        # Check user by username or student_id
        cur.execute(
            "SELECT * FROM users WHERE username = %s OR student_id = %s",
            (username, username)
        )
        user = cur.fetchone()
        
        if not user or not check_password_hash(user['password'], password):
            cur.close()
            db.close()
            return jsonify({'success': False, 'message': 'Invalid credentials'}), 401
        
        # Get additional info based on role
        user_data = {
            'id': user['id'],
            'username': user['username'],
            'email': user.get('email'),
            'role': user['role'],
            'student_id': user.get('student_id')
        }
        
        if user['role'] == 'student':
            cur.execute("""
                SELECT s.*, c.course_name, c.course_code 
                FROM students s 
                LEFT JOIN courses c ON s.course_id = c.id 
                WHERE s.user_id = %s
            """, (user['id'],))
            student_info = cur.fetchone()
            if student_info:
                user_data['student_info'] = {
                    'student_id': student_info['student_id'],
                    'first_name': student_info['first_name'],
                    'middle_name': student_info.get('middle_name'),
                    'last_name': student_info['last_name'],
                    'course_name': student_info.get('course_name'),
                    'course_code': student_info.get('course_code'),
                    'year_level': student_info.get('year_level'),
                    'section': student_info.get('section'),
                    'gender': student_info.get('gender'),
                    'status': student_info.get('status')
                }
        
        elif user['role'] == 'teacher':
            cur.execute("""
                SELECT * FROM teachers WHERE user_id = %s
            """, (user['id'],))
            teacher_info = cur.fetchone()
            if teacher_info:
                user_data['teacher_info'] = {
                    'first_name': teacher_info['first_name'],
                    'last_name': teacher_info['last_name'],
                    'department': teacher_info.get('department'),
                    'email': teacher_info.get('email')
                }
        
        cur.close()
        db.close()
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'data': user_data
        }), 200
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@mobile_api.route('/student/grades/<int:user_id>', methods=['GET'])
def get_student_grades(user_id):
    """
    Get student grades
    GET /api/mobile/student/grades/<user_id>
    """
    try:
        db = get_mobile_db()
        cur = db.cursor()
        
        # Get student internal ID
        cur.execute("SELECT id FROM students WHERE user_id = %s", (user_id,))
        student = cur.fetchone()
        
        if not student:
            cur.close()
            db.close()
            return jsonify({'success': False, 'message': 'Student not found'}), 404
        
        student_id = student['id']
        
        # Get grades
        cur.execute("""
            SELECT ge.*, sub.subject_name, sub.subject_code
            FROM grade_entries ge
            JOIN subjects sub ON ge.subject_id = sub.id
            WHERE ge.student_id = %s
            ORDER BY ge.created_at DESC
        """, (student_id,))
        
        grades = cur.fetchall()
        
        cur.close()
        db.close()
        
        return jsonify({
            'success': True,
            'data': grades
        }), 200
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@mobile_api.route('/student/schedule/<int:user_id>', methods=['GET'])
def get_student_schedule(user_id):
    """
    Get student schedule
    GET /api/mobile/student/schedule/<user_id>
    """
    try:
        db = get_mobile_db()
        cur = db.cursor()
        
        # Get student course
        cur.execute("""
            SELECT s.course_id, c.course_code 
            FROM students s 
            LEFT JOIN courses c ON s.course_id = c.id 
            WHERE s.user_id = %s
        """, (user_id,))
        
        student = cur.fetchone()
        
        if not student:
            cur.close()
            db.close()
            return jsonify({'success': False, 'message': 'Student not found'}), 404
        
        # Get schedules for student's course
        cur.execute("""
            SELECT sch.*, sub.subject_name, sub.subject_code, 
                   t.first_name as teacher_first_name, t.last_name as teacher_last_name
            FROM schedules sch
            JOIN subjects sub ON sch.subject_id = sub.id
            LEFT JOIN teachers t ON sch.teacher_id = t.id
            WHERE sch.course_id = %s
            ORDER BY 
                FIELD(sch.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                sch.start_time
        """, (student['course_id'],))
        
        schedules = cur.fetchall()
        
        cur.close()
        db.close()
        
        return jsonify({
            'success': True,
            'data': schedules
        }), 200
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@mobile_api.route('/student/attendance/<int:user_id>', methods=['GET'])
def get_student_attendance(user_id):
    """
    Get student attendance
    GET /api/mobile/student/attendance/<user_id>
    """
    try:
        db = get_mobile_db()
        cur = db.cursor()
        
        # Get student internal ID
        cur.execute("SELECT id FROM students WHERE user_id = %s", (user_id,))
        student = cur.fetchone()
        
        if not student:
            cur.close()
            db.close()
            return jsonify({'success': False, 'message': 'Student not found'}), 404
        
        student_id = student['id']
        
        # Get attendance records
        cur.execute("""
            SELECT a.*, sub.subject_name, sub.subject_code
            FROM attendance a
            JOIN subjects sub ON a.subject_id = sub.id
            WHERE a.student_id = %s
            ORDER BY a.date DESC
            LIMIT 50
        """, (student_id,))
        
        attendance = cur.fetchall()
        
        cur.close()
        db.close()
        
        return jsonify({
            'success': True,
            'data': attendance
        }), 200
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@mobile_api.route('/teacher/students', methods=['GET'])
def get_teacher_students():
    """
    Get students for teacher's department
    GET /api/mobile/teacher/students?user_id=<user_id>
    """
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({'success': False, 'message': 'User ID required'}), 400
        
        db = get_mobile_db()
        cur = db.cursor()
        
        # Get teacher department
        cur.execute("SELECT department FROM teachers WHERE user_id = %s", (user_id,))
        teacher = cur.fetchone()
        
        if not teacher:
            cur.close()
            db.close()
            return jsonify({'success': False, 'message': 'Teacher not found'}), 404
        
        department = teacher.get('department')
        
        # Get students in teacher's department
        if department:
            cur.execute("""
                SELECT s.*, c.course_name, c.course_code
                FROM students s
                JOIN courses c ON s.course_id = c.id
                WHERE UPPER(c.course_code) = UPPER(%s)
                ORDER BY s.first_name, s.last_name
            """, (department,))
        else:
            cur.execute("""
                SELECT s.*, c.course_name, c.course_code
                FROM students s
                LEFT JOIN courses c ON s.course_id = c.id
                ORDER BY s.first_name, s.last_name
            """)
        
        students = cur.fetchall()
        
        cur.close()
        db.close()
        
        return jsonify({
            'success': True,
            'data': students
        }), 200
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@mobile_api.route('/teacher/subjects', methods=['GET'])
def get_teacher_subjects():
    """
    Get subjects for teacher's department
    GET /api/mobile/teacher/subjects?user_id=<user_id>
    """
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({'success': False, 'message': 'User ID required'}), 400
        
        db = get_mobile_db()
        cur = db.cursor()
        
        # Get teacher department
        cur.execute("SELECT department FROM teachers WHERE user_id = %s", (user_id,))
        teacher = cur.fetchone()
        
        if not teacher:
            cur.close()
            db.close()
            return jsonify({'success': False, 'message': 'Teacher not found'}), 404
        
        department = teacher.get('department')
        
        # Get subjects in teacher's department
        if department:
            cur.execute("""
                SELECT s.*, c.course_name, c.course_code
                FROM subjects s
                JOIN courses c ON s.course_id = c.id
                WHERE UPPER(c.course_code) = UPPER(%s)
                ORDER BY s.subject_name
            """, (department,))
        else:
            cur.execute("""
                SELECT s.*, c.course_name, c.course_code
                FROM subjects s
                LEFT JOIN courses c ON s.course_id = c.id
                ORDER BY s.subject_name
            """)
        
        subjects = cur.fetchall()
        
        cur.close()
        db.close()
        
        return jsonify({
            'success': True,
            'data': subjects
        }), 200
        
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@mobile_api.route('/test', methods=['GET'])
def test_api():
    """Test endpoint to verify API is working"""
    return jsonify({
        'success': True,
        'message': 'Mobile API is working!',
        'version': '1.0.0'
    }), 200
