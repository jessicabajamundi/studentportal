# Student Portal Management System - Database Project

## 1. Introduction / System Overview
The **Student Portal Management System** is a comprehensive web-based application designed to streamline the management of student academic records. It serves three main user roles: **Students**, **Teachers**, and **Parents**.

The system facilitates:
- **Student Management**: Registration, profile management, and enrollment.
- **Grade Management**: Teachers can record grades, and students/parents can view them.
- **Attendance Tracking**: Daily attendance monitoring.
- **Schedule Management**: Class scheduling and viewing.

This database project focuses on the backend data structure that supports these features, ensuring data integrity, efficient retrieval, and secure storage of sensitive educational information.

## 2. Entity Relationship Diagram (ERD)
*Note: You can generate the visual ERD using MySQL Workbench by importing the `schema.sql` file.*

### Key Entities and Relationships:
1.  **Users**: Stores login credentials and roles (student, teacher, parent, admin).
2.  **Students**: Links to `Users`. Belongs to a `Course`. Has many `Grades` and `Attendance` records.
3.  **Teachers**: Links to `Users`. Manages `Subjects` and `Schedules`.
4.  **Courses**: Represents academic programs (e.g., STEM, ABM). Has many `Students`.
5.  **Subjects**: The individual classes taught. Linked to `Courses`.
6.  **Grades**: Records the academic performance of a `Student` in a `Subject`.
7.  **Attendance**: Records the daily presence of a `Student` in a `Subject`.
8.  **Schedules**: Defines when `Subjects` are taught.

## 3. Database Schema (Tables)

### `users`
- `id` (PK): Unique identifier
- `username`: Login name
- `password`: Hashed password
- `role`: Enum('student', 'teacher', 'parent', 'admin')

### `students`
- `id` (PK)
- `user_id` (FK): Links to `users`
- `student_id`: Unique school ID (e.g., STEM-001)
- `course_id` (FK): Links to `courses`
- `year_level`, `section`: Academic details

### `teachers`
- `id` (PK)
- `user_id` (FK): Links to `users`
- `department`: Academic department

### `courses`
- `id` (PK)
- `course_code`: Short code (e.g., STEM)
- `course_name`: Full name

### `subjects`
- `id` (PK)
- `course_id` (FK): Links to `courses`
- `subject_code`, `subject_name`

### `grades`
- `id` (PK)
- `student_id` (FK)
- `subject_id` (FK)
- `grade`: Numerical or Letter grade

## 4. Sample SQL Queries

### A. SELECT with JOIN and WHERE
*Retrieve all students in the 'STEM' course.*
```sql
SELECT s.first_name, s.last_name, c.course_code 
FROM students s
JOIN courses c ON s.course_id = c.id
WHERE c.course_code = 'STEM';
```

### B. INSERT (Adding a Record)
*Register a new student.*
```sql
INSERT INTO students (user_id, student_id, first_name, last_name, course_id, year_level) 
VALUES (101, 'STEM-2024-001', 'Juan', 'Dela Cruz', 1, 11);
```

### C. UPDATE (Modifying Data)
*Update a student's section.*
```sql
UPDATE students SET section = 'B' WHERE student_id = 'STEM-2024-001';
```

### D. DELETE (Removing Records)
*Remove a specific schedule.*
```sql
DELETE FROM schedules WHERE subject_id = 5 AND day_of_week = 'Friday';
```

### E. AGGREGATES (Summary Report)
*Count number of students per course.*
```sql
SELECT c.course_name, COUNT(s.id) as student_count
FROM courses c
LEFT JOIN students s ON c.id = s.course_id
GROUP BY c.course_name;
```

## 5. Summary / Conclusion
The implemented database effectively normalizes data into related tables, reducing redundancy and ensuring data integrity. The use of Foreign Keys maintains relationships between students, courses, and their academic records. The system is scalable and can support additional features like detailed analytics and historical data tracking in the future.
