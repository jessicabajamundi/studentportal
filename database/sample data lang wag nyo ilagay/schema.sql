-- Database Schema Dump

-- Table structure for table `attendance`
DROP TABLE IF EXISTS `attendance`;
CREATE TABLE `attendance` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `subject_id` int DEFAULT NULL,
  `date` date NOT NULL,
  `status` enum('present','absent','late','excused') COLLATE utf8mb4_general_ci NOT NULL,
  `remarks` text COLLATE utf8mb4_general_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  KEY `subject_id` (`subject_id`),
  CONSTRAINT `attendance_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `attendance_ibfk_2` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `courses`
DROP TABLE IF EXISTS `courses`;
CREATE TABLE `courses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `course_code` varchar(10) COLLATE utf8mb4_general_ci NOT NULL,
  `course_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `course_code` (`course_code`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `grade_entries`
DROP TABLE IF EXISTS `grade_entries`;
CREATE TABLE `grade_entries` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `subject_id` int NOT NULL,
  `term` varchar(16) COLLATE utf8mb4_general_ci NOT NULL,
  `score` int NOT NULL,
  `school_year` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `level` varchar(8) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `remarks` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_grade` (`student_id`,`subject_id`,`term`,`school_year`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `grades`
DROP TABLE IF EXISTS `grades`;
CREATE TABLE `grades` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `subject_id` int NOT NULL,
  `grade` varchar(2) COLLATE utf8mb4_general_ci NOT NULL,
  `units` decimal(3,1) DEFAULT '3.0',
  `semester` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `school_year` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `remarks` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  KEY `subject_id` (`subject_id`),
  CONSTRAINT `grades_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `grades_ibfk_2` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `exam_schedules`
DROP TABLE IF EXISTS `exam_schedules`;
CREATE TABLE `exam_schedules` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `exam_type` enum('midterm','final','quiz','assignment','project') COLLATE utf8mb4_general_ci NOT NULL,
  `subject_id` int NOT NULL,
  `course_id` int DEFAULT NULL,
  `exam_date` date NOT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `room` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `total_points` int DEFAULT NULL,
  `created_by` int NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT TRUE,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `subject_id` (`subject_id`),
  KEY `course_id` (`course_id`),
  KEY `created_by` (`created_by`),
  KEY `exam_date` (`exam_date`),
  CONSTRAINT `exam_schedules_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `exam_schedules_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE SET NULL,
  CONSTRAINT `exam_schedules_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `school_events`
DROP TABLE IF EXISTS `school_events`;
CREATE TABLE `school_events` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `event_type` enum('holiday','exam','activity','meeting','deadline','other') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'other',
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `location` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `target_audience` enum('all','students','teachers','admin','specific') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'all',
  `is_active` tinyint(1) NOT NULL DEFAULT TRUE,
  `reminder_days_before` int DEFAULT 3,
  `created_by` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `start_date` (`start_date`),
  KEY `event_type` (`event_type`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `school_events_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `event_reminders`
DROP TABLE IF EXISTS `event_reminders`;
CREATE TABLE `event_reminders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `event_id` int NOT NULL,
  `event_type` enum('exam','school_event') COLLATE utf8mb4_general_ci NOT NULL,
  `reminder_date` date NOT NULL,
  `is_sent` tinyint(1) NOT NULL DEFAULT FALSE,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `event_id` (`event_id`),
  KEY `reminder_date` (`reminder_date`),
  CONSTRAINT `event_reminders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  UNIQUE KEY `uq_user_event` (`user_id`, `event_id`, `event_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `schedules`
DROP TABLE IF EXISTS `schedules`;
CREATE TABLE `schedules` (
  `id` int NOT NULL AUTO_INCREMENT,
  `subject_id` int NOT NULL,
  `course_id` int NOT NULL,
  `teacher_id` int DEFAULT NULL,
  `day_of_week` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') COLLATE utf8mb4_general_ci NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `room` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `subject_id` (`subject_id`),
  KEY `course_id` (`course_id`),
  KEY `teacher_id` (`teacher_id`),
  CONSTRAINT `schedules_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `schedules_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `schedules_ibfk_3` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `student_relations`
DROP TABLE IF EXISTS `student_relations`;
CREATE TABLE `student_relations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `user_id` int NOT NULL,
  `relation` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `students`
DROP TABLE IF EXISTS `students`;
CREATE TABLE `students` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `student_id` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `first_name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `middle_name` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `last_name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `date_of_birth` date DEFAULT NULL,
  `gender` enum('Male','Female','Other') COLLATE utf8mb4_general_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_general_ci,
  `course_id` int DEFAULT NULL,
  `year_level` int DEFAULT '1',
  `section` varchar(10) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `parent_user_id` int DEFAULT NULL,
  `emergency_contact` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `emergency_phone` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `enrollment_date` date DEFAULT NULL,
  `status` enum('active','inactive','graduated') COLLATE utf8mb4_general_ci DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `avatar` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `extension_name` varchar(10) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `blood_group` varchar(5) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `guardian_name` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `guardian_relation` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `guardian_email` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `guardian_address` text COLLATE utf8mb4_general_ci,
  `father_first_name` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `father_middle_name` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `father_last_name` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `mother_first_name` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `mother_middle_name` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `mother_last_name` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `lrn` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `branch` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `satellite` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `college` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `current_semester` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `student_type` varchar(20) COLLATE utf8mb4_general_ci DEFAULT 'New Student',
  PRIMARY KEY (`id`),
  UNIQUE KEY `student_id` (`student_id`),
  KEY `user_id` (`user_id`),
  KEY `course_id` (`course_id`),
  KEY `parent_user_id` (`parent_user_id`),
  CONSTRAINT `students_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `students_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`),
  CONSTRAINT `students_ibfk_3` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `subjects`
DROP TABLE IF EXISTS `subjects`;
CREATE TABLE `subjects` (
  `id` int NOT NULL AUTO_INCREMENT,
  `subject_code` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `subject_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `course_id` int DEFAULT NULL,
  `units` decimal(3,1) DEFAULT '3.0',
  `description` text COLLATE utf8mb4_general_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `subject_code` (`subject_code`),
  KEY `course_id` (`course_id`),
  CONSTRAINT `subjects_ibfk_1` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `teachers`
DROP TABLE IF EXISTS `teachers`;
CREATE TABLE `teachers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `first_name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `last_name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `department` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `teachers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `users`
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `student_id` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `role` enum('student','parent','admin','teacher') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'student',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `avatar` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `phone` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `student_id` (`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `announcements`
DROP TABLE IF EXISTS `announcements`;
CREATE TABLE `announcements` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `content` text COLLATE utf8mb4_general_ci NOT NULL,
  `posted_by` int NOT NULL,
  `target_audience` enum('all','students','teachers','admin') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'all',
  `priority` enum('low','medium','high') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'medium',
  `is_active` tinyint(1) NOT NULL DEFAULT TRUE,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `posted_by` (`posted_by`),
  CONSTRAINT `announcements_ibfk_1` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `exam_schedules`
DROP TABLE IF EXISTS `exam_schedules`;
CREATE TABLE `exam_schedules` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `exam_type` enum('midterm','final','quiz','assignment','project') COLLATE utf8mb4_general_ci NOT NULL,
  `subject_id` int NOT NULL,
  `course_id` int DEFAULT NULL,
  `exam_date` date NOT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `room` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `total_points` int DEFAULT NULL,
  `created_by` int NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT TRUE,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `subject_id` (`subject_id`),
  KEY `course_id` (`course_id`),
  KEY `created_by` (`created_by`),
  KEY `exam_date` (`exam_date`),
  CONSTRAINT `exam_schedules_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `exam_schedules_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE SET NULL,
  CONSTRAINT `exam_schedules_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `school_events`
DROP TABLE IF EXISTS `school_events`;
CREATE TABLE `school_events` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `event_type` enum('holiday','exam','activity','meeting','deadline','other') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'other',
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `location` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `target_audience` enum('all','students','teachers','admin','specific') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'all',
  `is_active` tinyint(1) NOT NULL DEFAULT TRUE,
  `reminder_days_before` int DEFAULT 3,
  `created_by` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `start_date` (`start_date`),
  KEY `event_type` (`event_type`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `school_events_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `event_reminders`
DROP TABLE IF EXISTS `event_reminders`;
CREATE TABLE `event_reminders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `event_id` int NOT NULL,
  `event_type` enum('exam','school_event') COLLATE utf8mb4_general_ci NOT NULL,
  `reminder_date` date NOT NULL,
  `is_sent` tinyint(1) NOT NULL DEFAULT FALSE,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `event_id` (`event_id`),
  KEY `reminder_date` (`reminder_date`),
  CONSTRAINT `event_reminders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  UNIQUE KEY `uq_user_event` (`user_id`, `event_id`, `event_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

