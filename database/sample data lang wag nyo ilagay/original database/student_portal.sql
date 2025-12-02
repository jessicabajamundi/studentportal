CREATE DATABASE IF NOT EXISTS student_portal
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE student_portal;

CREATE USER 'portal'@'localhost' IDENTIFIED BY '123456789';
CREATE DATABASE IF NOT EXISTS student_portal
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON student_portal.* TO 'portal'@'localhost';
FLUSH PRIVILEGES;

CREATE USER 'portal'@'localhost' IDENTIFIED BY '123456789';
CREATE DATABASE IF NOT EXISTS student_portal
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON student_portal.* TO 'portal'@'localhost';
FLUSH PRIVILEGES;

SELECT user, host, plugin FROM mysql.user WHERE user='root';

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

CREATE DATABASE IF NOT EXISTS student_portal
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE student_portal;


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `student_portal`
--

-- --------------------------------------------------------

--
-- Table structure for table `attendance`
--

CREATE TABLE `attendance` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `date` date NOT NULL,
  `status` enum('present','absent','late','excused') NOT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `attendance`
--

INSERT INTO `attendance` (`id`, `student_id`, `subject_id`, `date`, `status`, `remarks`, `created_at`) VALUES
(1, 1, 28, '2025-11-13', 'present', 'be on time', '2025-11-13 12:07:27');

-- --------------------------------------------------------

--
-- Table structure for table `courses`
--

CREATE TABLE `courses` (
  `id` int(11) NOT NULL,
  `course_code` varchar(10) NOT NULL,
  `course_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `courses`
--

INSERT INTO `courses` (`id`, `course_code`, `course_name`, `description`, `created_at`) VALUES
(1, 'STEM', 'Science, Technology, Engineering, and Mathematics', 'STEM strand focuses on science, technology, engineering, and mathematics', '2025-11-07 07:35:43'),
(2, 'ABM', 'Accountancy, Business and Management', 'ABM strand focuses on business, finance, and management', '2025-11-07 07:35:43'),
(3, 'HUMSS', 'Humanities and Social Sciences', 'HUMSS strand focuses on humanities, social sciences, and liberal arts', '2025-11-07 07:35:43'),
(12, 'JHS7', 'Junior High School Grade 7', 'Grade 7 level (Junior High School)', '2025-11-07 12:42:55'),
(13, 'JHS8', 'Junior High School Grade 8', 'Grade 8 level (Junior High School)', '2025-11-07 12:42:55'),
(14, 'JHS9', 'Junior High School Grade 9', 'Grade 9 level (Junior High School)', '2025-11-07 12:42:55'),
(15, 'JHS10', 'Junior High School Grade 10', 'Grade 10 level (Junior High School)', '2025-11-07 12:42:55');

-- --------------------------------------------------------

--
-- Table structure for table `enrollments`
--
-- Error reading structure for table student_portal.enrollments: #1932 - Table &#039;student_portal.enrollments&#039; doesn&#039;t exist in engine
-- Error reading data for table student_portal.enrollments: #1064 - You have an error in your SQL syntax; check the manual that corresponds to your MariaDB server version for the right syntax to use near &#039;FROM `student_portal`.`enrollments`&#039; at line 1

-- --------------------------------------------------------

--
-- Table structure for table `events`
--

CREATE TABLE `events` (
  `id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `event_date` date NOT NULL,
  `event_time` time DEFAULT NULL,
  `course_id` int(11) DEFAULT NULL,
  `event_type` enum('exam','holiday','activity','deadline','other') DEFAULT 'other',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `grades`
--

CREATE TABLE `grades` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `subject_id` int(11) NOT NULL,
  `grade` varchar(2) NOT NULL,
  `units` decimal(3,1) DEFAULT 3.0,
  `semester` varchar(20) DEFAULT NULL,
  `school_year` varchar(20) DEFAULT NULL,
  `remarks` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `grade_entries`
--

CREATE TABLE `grade_entries` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `subject_id` int(11) NOT NULL,
  `term` varchar(16) NOT NULL,
  `score` int(11) NOT NULL,
  `school_year` varchar(20) NOT NULL,
  `level` varchar(8) DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `grade_entries`
--

INSERT INTO `grade_entries` (`id`, `student_id`, `subject_id`, `term`, `score`, `school_year`, `level`, `remarks`, `created_at`) VALUES
(1, 1, 28, 'Q1', 93, '2025-2025', 'SHS', 'good', '2025-11-13 11:47:08');

-- --------------------------------------------------------

--
-- Table structure for table `schedules`
--

CREATE TABLE `schedules` (
  `id` int(11) NOT NULL,
  `subject_id` int(11) NOT NULL,
  `course_id` int(11) NOT NULL,
  `teacher_id` int(11) DEFAULT NULL,
  `day_of_week` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `room` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `schedules`
--

INSERT INTO `schedules` (`id`, `subject_id`, `course_id`, `teacher_id`, `day_of_week`, `start_time`, `end_time`, `room`, `created_at`) VALUES
(1, 28, 1, 1, 'Tuesday', '11:00:00', '12:00:00', '101', '2025-11-13 11:40:54');

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

CREATE TABLE `students` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `student_id` varchar(20) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) NOT NULL,
  `date_of_birth` date DEFAULT NULL,
  `gender` enum('Male','Female','Other') DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `course_id` int(11) DEFAULT NULL,
  `year_level` int(11) DEFAULT 1,
  `section` varchar(10) DEFAULT NULL,
  `parent_user_id` int(11) DEFAULT NULL,
  `emergency_contact` varchar(100) DEFAULT NULL,
  `emergency_phone` varchar(20) DEFAULT NULL,
  `enrollment_date` date DEFAULT NULL,
  `status` enum('active','inactive','graduated') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `avatar` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`id`, `user_id`, `student_id`, `first_name`, `middle_name`, `last_name`, `date_of_birth`, `gender`, `phone`, `address`, `course_id`, `year_level`, `section`, `parent_user_id`, `emergency_contact`, `emergency_phone`, `enrollment_date`, `status`, `created_at`, `updated_at`, `avatar`) VALUES
(1, 1, '231-2244', 'matthew', 'meracap', 'evangelista', NULL, NULL, NULL, NULL, 1, 1, 'E', 2, NULL, NULL, '2025-11-07', 'active', '2025-11-07 08:09:21', '2025-11-13 10:11:29', 'static/uploads/avatars/user_1_1763028689.png');

-- --------------------------------------------------------

--
-- Table structure for table `student_relations`
--

CREATE TABLE `student_relations` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `relation` varchar(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `student_relations`
--

INSERT INTO `student_relations` (`id`, `student_id`, `user_id`, `relation`, `created_at`) VALUES
(1, 1, 5, 'Father', '2025-11-13 11:31:05');

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

CREATE TABLE `subjects` (
  `id` int(11) NOT NULL,
  `subject_code` varchar(20) NOT NULL,
  `subject_name` varchar(100) NOT NULL,
  `course_id` int(11) DEFAULT NULL,
  `units` decimal(3,1) DEFAULT 3.0,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subjects`
--

INSERT INTO `subjects` (`id`, `subject_code`, `subject_name`, `course_id`, `units`, `description`, `created_at`) VALUES
(1, 'JHS7-MATH', 'Mathematics', 12, 3.0, NULL, '2025-11-13 11:22:34'),
(2, 'JHS7-ENG', 'English', 12, 3.0, NULL, '2025-11-13 11:22:34'),
(3, 'JHS7-SCI', 'Science', 12, 3.0, NULL, '2025-11-13 11:22:34'),
(4, 'JHS7-FIL', 'Filipino', 12, 3.0, NULL, '2025-11-13 11:22:34'),
(5, 'JHS7-MAP', 'MAPEH', 12, 3.0, NULL, '2025-11-13 11:22:34'),
(6, 'JHS8-MATH', 'Mathematics', 13, 3.0, NULL, '2025-11-13 11:22:34'),
(7, 'JHS8-ENG', 'English', 13, 3.0, NULL, '2025-11-13 11:22:34'),
(8, 'JHS8-SCI', 'Science', 13, 3.0, NULL, '2025-11-13 11:22:34'),
(9, 'JHS8-FIL', 'Filipino', 13, 3.0, NULL, '2025-11-13 11:22:34'),
(10, 'JHS8-MAP', 'MAPEH', 13, 3.0, NULL, '2025-11-13 11:22:34'),
(11, 'JHS9-MATH', 'Mathematics', 14, 3.0, NULL, '2025-11-13 11:22:34'),
(12, 'JHS9-ENG', 'English', 14, 3.0, NULL, '2025-11-13 11:22:34'),
(13, 'JHS9-SCI', 'Science', 14, 3.0, NULL, '2025-11-13 11:22:34'),
(14, 'JHS9-FIL', 'Filipino', 14, 3.0, NULL, '2025-11-13 11:22:34'),
(15, 'JHS9-MAP', 'MAPEH', 14, 3.0, NULL, '2025-11-13 11:22:34'),
(16, 'JHS10-MATH', 'Mathematics', 15, 3.0, NULL, '2025-11-13 11:22:34'),
(17, 'JHS10-ENG', 'English', 15, 3.0, NULL, '2025-11-13 11:22:34'),
(18, 'JHS10-SCI', 'Science', 15, 3.0, NULL, '2025-11-13 11:22:34'),
(19, 'JHS10-FIL', 'Filipino', 15, 3.0, NULL, '2025-11-13 11:22:34'),
(20, 'JHS10-MAP', 'MAPEH', 15, 3.0, NULL, '2025-11-13 11:22:34'),
(21, 'ICT101', 'Computer Systems Servicing', NULL, 3.0, NULL, '2025-11-13 11:22:34'),
(22, 'ICT102', 'Programming Fundamentals', NULL, 3.0, NULL, '2025-11-13 11:22:34'),
(23, 'ICT103', 'Networking Basics', NULL, 3.0, NULL, '2025-11-13 11:22:34'),
(24, 'ICT104', 'Multimedia Technologies', NULL, 3.0, NULL, '2025-11-13 11:22:34'),
(25, 'STEM101', 'General Mathematics', 1, 3.0, NULL, '2025-11-13 11:22:34'),
(26, 'STEM102', 'Statistics and Probability', 1, 3.0, NULL, '2025-11-13 11:22:34'),
(27, 'STEM103', 'Pre-Calculus', 1, 3.0, NULL, '2025-11-13 11:22:34'),
(28, 'STEM104', 'Basic Calculus', 1, 3.0, NULL, '2025-11-13 11:22:34'),
(29, 'STEM105', 'General Physics 1', 1, 3.0, NULL, '2025-11-13 11:22:34'),
(30, 'STEM106', 'General Physics 2', 1, 3.0, NULL, '2025-11-13 11:22:34'),
(31, 'STEM107', 'General Chemistry 1', 1, 3.0, NULL, '2025-11-13 11:22:34'),
(32, 'STEM108', 'General Chemistry 2', 1, 3.0, NULL, '2025-11-13 11:22:34'),
(33, 'STEM109', 'Biology 1', 1, 3.0, NULL, '2025-11-13 11:22:34'),
(34, 'STEM110', 'Biology 2', 1, 3.0, NULL, '2025-11-13 11:22:34'),
(35, 'ABM101', 'Fundamentals of Accountancy, Business and Management 1', 2, 3.0, NULL, '2025-11-13 11:22:34'),
(36, 'ABM102', 'Fundamentals of Accountancy, Business and Management 2', 2, 3.0, NULL, '2025-11-13 11:22:34'),
(37, 'ABM103', 'Business Math', 2, 3.0, NULL, '2025-11-13 11:22:34'),
(38, 'ABM104', 'Business Finance', 2, 3.0, NULL, '2025-11-13 11:22:34'),
(39, 'ABM105', 'Organization and Management', 2, 3.0, NULL, '2025-11-13 11:22:34'),
(40, 'ABM106', 'Principles of Marketing', 2, 3.0, NULL, '2025-11-13 11:22:34'),
(41, 'ABM107', 'Applied Economics', 2, 3.0, NULL, '2025-11-13 11:22:34'),
(42, 'ABM108', 'Business Ethics and Social Responsibility', 2, 3.0, NULL, '2025-11-13 11:22:34'),
(43, 'HUMSS101', 'Creative Writing', 3, 3.0, NULL, '2025-11-13 11:22:34'),
(44, 'HUMSS102', 'Creative Nonfiction', 3, 3.0, NULL, '2025-11-13 11:22:34'),
(45, 'HUMSS103', 'World Religions and Belief Systems', 3, 3.0, NULL, '2025-11-13 11:22:34'),
(46, 'HUMSS104', 'Introduction to World Religions and Belief Systems', 3, 3.0, NULL, '2025-11-13 11:22:34'),
(47, 'HUMSS105', 'Disciplines and Ideas in the Social Sciences', 3, 3.0, NULL, '2025-11-13 11:22:34'),
(48, 'HUMSS106', 'Disciplines and Ideas in Applied Social Sciences', 3, 3.0, NULL, '2025-11-13 11:22:34'),
(49, 'HUMSS107', 'Philippine Politics and Governance', 3, 3.0, NULL, '2025-11-13 11:22:34'),
(50, 'HUMSS108', 'Community Engagement, Solidarity, and Citizenship', 3, 3.0, NULL, '2025-11-13 11:22:34');

-- --------------------------------------------------------

--
-- Table structure for table `teachers`
--

CREATE TABLE `teachers` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `department` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `teachers`
--

INSERT INTO `teachers` (`id`, `user_id`, `first_name`, `last_name`, `email`, `phone`, `department`, `created_at`) VALUES
(1, 4, 'teacher1', 'test', 'teacher1@gmail.com', NULL, 'STEM', '2025-11-07 11:41:26'),
(2, NULL, 'Maria', 'Santos', 'maria.santos@school.edu', NULL, 'Mathematics', '2025-11-13 11:22:34'),
(3, NULL, 'Juan', 'Cruz', 'juan.cruz@school.edu', NULL, 'Science', '2025-11-13 11:22:34'),
(4, NULL, 'Ana', 'Reyes', 'ana.reyes@school.edu', NULL, 'English', '2025-11-13 11:22:34'),
(5, NULL, 'Carlos', 'Garcia', 'carlos.garcia@school.edu', NULL, 'Social Studies', '2025-11-13 11:22:34'),
(6, NULL, 'Liza', 'Torres', 'liza.torres@school.edu', NULL, 'Business', '2025-11-13 11:22:34');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `student_id` varchar(20) DEFAULT NULL,
  `role` enum('student','parent','admin','teacher') NOT NULL DEFAULT 'student',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `avatar` varchar(255) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `email`, `student_id`, `role`, `created_at`, `updated_at`, `avatar`, `phone`, `address`) VALUES
(1, 'matthew1234', 'scrypt:32768:8:1$c77kQxePXaJpX2T2$1f7e50b7c1bf20ce588b961c0ae01cb291a149b74fb3b80710be5e9a1c3435e461680f7aacc7a1b22c131f70d1a41fecd5982cb71760d901378c37472ac7e5e8', '17matthewevangelista@gmail.com', '231-2244', 'student', '2025-11-07 08:09:21', '2025-11-07 08:09:21', NULL, NULL, NULL),
(2, 'marilynevangelista1', 'scrypt:32768:8:1$M55DjbNRALFworCc$2867c29fd19c80b6470d9331a26c3ad57c1e9faacae23d62210c5b8c0d6cd8e7db8a0b4ccea0e8f0c57e9a3abf18a421911699938cfd6196be9f57b5c1423b20', 'marilynevangelista123@gmail.com', NULL, 'parent', '2025-11-07 10:53:51', '2025-11-07 10:53:51', NULL, NULL, NULL),
(3, 'admin', 'scrypt:32768:8:1$iqe5nYRZGe9YFDGY$e6019fd1d4379df04dfe30461bb399b5ea443836c2e7c0b69e2787e3c1e5addbc0f8659e5b3fbd20583a0b767ea19d751eb84815bb5879210acf1ebe969ce012', '17matthewevangelista', NULL, 'admin', '2025-11-07 11:39:31', '2025-11-07 11:39:31', NULL, NULL, NULL),
(4, 'teacher1', 'scrypt:32768:8:1$dQvNkunntYHr7qfX$a6dbe83f5de292d16076937a02bbc16bd26bcc963bf27960fb94d941023fdee04f0de161f03469f5fd6a84238b60bc0835a5cf6b4b37b1a9e80ff00676d815a8', 'teacher1@gmail.com', NULL, 'teacher', '2025-11-07 11:41:26', '2025-11-07 11:41:26', NULL, NULL, NULL),
(5, 'jonathan1', 'scrypt:32768:8:1$QdIVEbWNbYsSY4Mn$55a14c73ecf86172d84a7a21dd44b9eab607133b581faa649e6490baa1dac523c4bb1be7198cded6988a81206d6b715650cfd7cc4cf2898215554e11ab5ce54d', 'jonathanevangelista@gmail.com', NULL, 'parent', '2025-11-13 11:12:56', '2025-11-13 11:30:35', 'static/uploads/avatars/user_5_1763033435.jpg', NULL, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `attendance`
--
ALTER TABLE `attendance`
  ADD PRIMARY KEY (`id`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `subject_id` (`subject_id`);

--
-- Indexes for table `courses`
--
ALTER TABLE `courses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `course_code` (`course_code`);

--
-- Indexes for table `events`
--
ALTER TABLE `events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `course_id` (`course_id`);

--
-- Indexes for table `grades`
--
ALTER TABLE `grades`
  ADD PRIMARY KEY (`id`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `subject_id` (`subject_id`);

--
-- Indexes for table `grade_entries`
--
ALTER TABLE `grade_entries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_grade` (`student_id`,`subject_id`,`term`,`school_year`);

--
-- Indexes for table `schedules`
--
ALTER TABLE `schedules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `subject_id` (`subject_id`),
  ADD KEY `course_id` (`course_id`),
  ADD KEY `teacher_id` (`teacher_id`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `student_id` (`student_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `course_id` (`course_id`),
  ADD KEY `parent_user_id` (`parent_user_id`);

--
-- Indexes for table `student_relations`
--
ALTER TABLE `student_relations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `subjects`
--
ALTER TABLE `subjects`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `subject_code` (`subject_code`),
  ADD KEY `course_id` (`course_id`);

--
-- Indexes for table `teachers`
--
ALTER TABLE `teachers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `student_id` (`student_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `attendance`
--
ALTER TABLE `attendance`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `courses`
--
ALTER TABLE `courses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `events`
--
ALTER TABLE `events`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `grades`
--
ALTER TABLE `grades`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `grade_entries`
--
ALTER TABLE `grade_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `schedules`
--
ALTER TABLE `schedules`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `students`
--
ALTER TABLE `students`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `student_relations`
--
ALTER TABLE `student_relations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `subjects`
--
ALTER TABLE `subjects`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT for table `teachers`
--
ALTER TABLE `teachers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `attendance`
--
ALTER TABLE `attendance`
  ADD CONSTRAINT `attendance_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `attendance_ibfk_2` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `events`
--
ALTER TABLE `events`
  ADD CONSTRAINT `events_ibfk_1` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `grades`
--
ALTER TABLE `grades`
  ADD CONSTRAINT `grades_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `grades_ibfk_2` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `schedules`
--
ALTER TABLE `schedules`
  ADD CONSTRAINT `schedules_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `schedules_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `schedules_ibfk_3` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `students`
--
ALTER TABLE `students`
  ADD CONSTRAINT `students_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `students_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`),
  ADD CONSTRAINT `students_ibfk_3` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `subjects`
--
ALTER TABLE `subjects`
  ADD CONSTRAINT `subjects_ibfk_1` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`);

--
-- Constraints for table `teachers`
--
ALTER TABLE `teachers`
  ADD CONSTRAINT `teachers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
