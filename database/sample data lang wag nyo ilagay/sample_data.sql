-- Sample Data for Student Portal System
-- Run this after creating the database schema
-- Make sure to update password hashes using setup_admin.py

USE student_portal;

-- Cache course IDs for reuse
SET @jhs7_id = (SELECT id FROM courses WHERE course_code = 'JHS7');
SET @jhs8_id = (SELECT id FROM courses WHERE course_code = 'JHS8');
SET @jhs9_id = (SELECT id FROM courses WHERE course_code = 'JHS9');
SET @jhs10_id = (SELECT id FROM courses WHERE course_code = 'JHS10');
SET @ict_id = (SELECT id FROM courses WHERE course_code = 'ICT');
SET @stem_id = (SELECT id FROM courses WHERE course_code = 'STEM');
SET @abm_id = (SELECT id FROM courses WHERE course_code = 'ABM');
SET @humss_id = (SELECT id FROM courses WHERE course_code = 'HUMSS');

-- Junior High School subjects
INSERT INTO subjects (subject_code, subject_name, course_id, units) VALUES
('JHS7-MATH', 'Mathematics', @jhs7_id, 3.0),
('JHS7-ENG', 'English', @jhs7_id, 3.0),
('JHS7-SCI', 'Science', @jhs7_id, 3.0),
('JHS7-FIL', 'Filipino', @jhs7_id, 3.0),
('JHS7-MAP', 'MAPEH', @jhs7_id, 3.0),
('JHS8-MATH', 'Mathematics', @jhs8_id, 3.0),
('JHS8-ENG', 'English', @jhs8_id, 3.0),
('JHS8-SCI', 'Science', @jhs8_id, 3.0),
('JHS8-FIL', 'Filipino', @jhs8_id, 3.0),
('JHS8-MAP', 'MAPEH', @jhs8_id, 3.0),
('JHS9-MATH', 'Mathematics', @jhs9_id, 3.0),
('JHS9-ENG', 'English', @jhs9_id, 3.0),
('JHS9-SCI', 'Science', @jhs9_id, 3.0),
('JHS9-FIL', 'Filipino', @jhs9_id, 3.0),
('JHS9-MAP', 'MAPEH', @jhs9_id, 3.0),
('JHS10-MATH', 'Mathematics', @jhs10_id, 3.0),
('JHS10-ENG', 'English', @jhs10_id, 3.0),
('JHS10-SCI', 'Science', @jhs10_id, 3.0),
('JHS10-FIL', 'Filipino', @jhs10_id, 3.0),
('JHS10-MAP', 'MAPEH', @jhs10_id, 3.0);

-- Senior High School subjects (ICT strand)
INSERT INTO subjects (subject_code, subject_name, course_id, units) VALUES
('ICT101', 'Computer Systems Servicing', @ict_id, 3.0),
('ICT102', 'Programming Fundamentals', @ict_id, 3.0),
('ICT103', 'Networking Basics', @ict_id, 3.0),
('ICT104', 'Multimedia Technologies', @ict_id, 3.0);

-- STEM subjects
INSERT INTO subjects (subject_code, subject_name, course_id, units) VALUES
('STEM101', 'General Mathematics', @stem_id, 3.0),
('STEM102', 'Statistics and Probability', @stem_id, 3.0),
('STEM103', 'Pre-Calculus', @stem_id, 3.0),
('STEM104', 'Basic Calculus', @stem_id, 3.0),
('STEM105', 'General Physics 1', @stem_id, 3.0),
('STEM106', 'General Physics 2', @stem_id, 3.0),
('STEM107', 'General Chemistry 1', @stem_id, 3.0),
('STEM108', 'General Chemistry 2', @stem_id, 3.0),
('STEM109', 'Biology 1', @stem_id, 3.0),
('STEM110', 'Biology 2', @stem_id, 3.0);

-- ABM subjects
INSERT INTO subjects (subject_code, subject_name, course_id, units) VALUES
('ABM101', 'Fundamentals of Accountancy, Business and Management 1', @abm_id, 3.0),
('ABM102', 'Fundamentals of Accountancy, Business and Management 2', @abm_id, 3.0),
('ABM103', 'Business Math', @abm_id, 3.0),
('ABM104', 'Business Finance', @abm_id, 3.0),
('ABM105', 'Organization and Management', @abm_id, 3.0),
('ABM106', 'Principles of Marketing', @abm_id, 3.0),
('ABM107', 'Applied Economics', @abm_id, 3.0),
('ABM108', 'Business Ethics and Social Responsibility', @abm_id, 3.0);

-- HUMSS subjects
INSERT INTO subjects (subject_code, subject_name, course_id, units) VALUES
('HUMSS101', 'Creative Writing', @humss_id, 3.0),
('HUMSS102', 'Creative Nonfiction', @humss_id, 3.0),
('HUMSS103', 'World Religions and Belief Systems', @humss_id, 3.0),
('HUMSS104', 'Introduction to World Religions and Belief Systems', @humss_id, 3.0),
('HUMSS105', 'Disciplines and Ideas in the Social Sciences', @humss_id, 3.0),
('HUMSS106', 'Disciplines and Ideas in Applied Social Sciences', @humss_id, 3.0),
('HUMSS107', 'Philippine Politics and Governance', @humss_id, 3.0),
('HUMSS108', 'Community Engagement, Solidarity, and Citizenship', @humss_id, 3.0);

-- Insert sample teachers
INSERT INTO teachers (first_name, last_name, email, department) VALUES
('Maria', 'Santos', 'maria.santos@school.edu', 'Mathematics'),
('Juan', 'Cruz', 'juan.cruz@school.edu', 'Science'),
('Ana', 'Reyes', 'ana.reyes@school.edu', 'English'),
('Carlos', 'Garcia', 'carlos.garcia@school.edu', 'Social Studies'),
('Liza', 'Torres', 'liza.torres@school.edu', 'Business');

-- Insert sample schedules (Example for STEM - Monday)
INSERT INTO schedules (subject_id, course_id, teacher_id, day_of_week, start_time, end_time, room)
SELECT s.id, c.id, 1, 'Monday', '08:00:00', '09:30:00', 'Room 101'
FROM subjects s
JOIN courses c ON c.id = s.course_id
WHERE s.subject_code = 'STEM101';

INSERT INTO schedules (subject_id, course_id, teacher_id, day_of_week, start_time, end_time, room)
SELECT s.id, c.id, 1, 'Monday', '09:30:00', '11:00:00', 'Room 101'
FROM subjects s
JOIN courses c ON c.id = s.course_id
WHERE s.subject_code = 'STEM102';

INSERT INTO schedules (subject_id, course_id, teacher_id, day_of_week, start_time, end_time, room)
SELECT s.id, c.id, 2, 'Monday', '13:00:00', '14:30:00', 'Lab 201'
FROM subjects s
JOIN courses c ON c.id = s.course_id
WHERE s.subject_code = 'STEM105';

INSERT INTO schedules (subject_id, course_id, teacher_id, day_of_week, start_time, end_time, room)
SELECT s.id, c.id, 2, 'Monday', '14:30:00', '16:00:00', 'Lab 201'
FROM subjects s
JOIN courses c ON c.id = s.course_id
WHERE s.subject_code = 'STEM107';

-- Insert sample events
INSERT INTO events (title, description, event_date, event_time, course_id, event_type) VALUES
('Midterm Examinations', 'Midterm exams for all courses', '2024-03-15', '08:00:00', NULL, 'exam'),
('Science Fair', 'Annual Science Fair Competition', '2024-04-20', '09:00:00', (SELECT id FROM courses WHERE course_code = 'STEM'), 'activity'),
('Business Plan Competition', 'ABM Business Plan Presentation', '2024-04-25', '13:00:00', (SELECT id FROM courses WHERE course_code = 'ABM'), 'activity'),
('Cultural Day', 'HUMSS Cultural Presentation', '2024-05-10', '10:00:00', (SELECT id FROM courses WHERE course_code = 'HUMSS'), 'activity'),
('Enrollment Period', 'Online enrollment for next semester', '2024-06-01', NULL, NULL, 'deadline');

-- Note: To create sample students, you need to:
-- 1. First create users with proper password hashes
-- 2. Then create student records linked to those users
-- Use the setup_admin.py script or create users manually with proper password hashing

