-- 1. SELECT with JOIN and WHERE
-- Retrieve all students in the 'STEM' course with their year level and section.
SELECT 
    s.student_id, 
    s.first_name, 
    s.last_name, 
    c.course_code, 
    s.year_level, 
    s.section
FROM 
    students s
JOIN 
    courses c ON s.course_id = c.id
WHERE 
    c.course_code = 'STEM'
ORDER BY 
    s.last_name;

-- 2. INSERT (Adding a new record)
-- Register a new student into the system.
INSERT INTO students (
    user_id, student_id, first_name, last_name, email, 
    course_id, year_level, section, gender, student_type
) VALUES (
    101, 'STEM-2024-001', 'Juan', 'Dela Cruz', 'juan.delacruz@example.com', 
    1, 11, 'A', 'Male', 'Regular'
);

-- 3. UPDATE (Modifying data)
-- Update the section of a student who moved from Section A to Section B.
UPDATE students 
SET section = 'B' 
WHERE student_id = 'STEM-2024-001';

-- 4. DELETE (Removing records)
-- Remove a schedule entry for a specific subject on a specific day.
DELETE FROM schedules 
WHERE subject_id = 5 AND day_of_week = 'Friday';

-- 5. AGGREGATES (COUNT, AVG)
-- Calculate the average grade for a specific subject and count the number of students.
SELECT 
    s.subject_name,
    COUNT(g.id) as total_students,
    AVG(g.grade) as average_grade
FROM 
    grades g
JOIN 
    subjects s ON g.subject_id = s.id
WHERE 
    s.subject_code = 'MATH101'
GROUP BY 
    s.subject_name;

-- BONUS: Summary Report Query
-- Count number of students per course/program.
SELECT 
    c.course_name, 
    COUNT(s.id) as student_count
FROM 
    courses c
LEFT JOIN 
    students s ON c.id = s.course_id
GROUP BY 
    c.course_name;
