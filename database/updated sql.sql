-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: localhost    Database: student_portal
-- ------------------------------------------------------
-- Server version	8.0.40

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `announcements`
--

DROP TABLE IF EXISTS `announcements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `announcements` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `posted_by` int NOT NULL,
  `target_audience` enum('all','students','teachers','admin') NOT NULL DEFAULT 'all',
  `priority` enum('low','medium','high') NOT NULL DEFAULT 'medium',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `posted_by` (`posted_by`),
  CONSTRAINT `announcements_ibfk_1` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `announcements`
--

LOCK TABLES `announcements` WRITE;
/*!40000 ALTER TABLE `announcements` DISABLE KEYS */;
INSERT INTO `announcements` VALUES (1,'Welcome to Student Portal','We are excited to announce the launch of our new Student Portal System! This platform will help you track your grades, attendance, and schedules more efficiently.',3,'all','high',1,'2025-11-24','2025-12-31','2025-11-30 19:52:14','2025-11-30 19:52:14'),(2,'Midterm Examination Schedule','Midterm examinations will begin next week. Please check your schedules and prepare accordingly. Good luck to all students!',3,'students','high',1,'2025-11-28','2025-12-15','2025-11-30 19:52:14','2025-11-30 19:52:14'),(3,'System Maintenance Notice','The Student Portal will undergo maintenance this weekend from 2 AM to 6 AM. Please save your work and log out during this time.',3,'all','medium',1,'2025-11-30','2025-12-03','2025-11-30 19:52:14','2025-11-30 19:52:14'),(4,'New Course Registration','Registration for next semester courses is now open. Please visit the enrollment section to select your courses for the upcoming term.',3,'students','medium',1,'2025-12-01','2025-12-22','2025-11-30 19:52:14','2025-11-30 19:52:14'),(5,'Teacher Meeting','All teachers are requested to attend a meeting on Friday at 3 PM in the conference room to discuss the new curriculum updates.',3,'teachers','high',1,'2025-12-01','2025-12-08','2025-11-30 19:52:14','2025-11-30 19:52:14'),(6,'Holiday Announcement','The school will be closed for the upcoming holiday. Please enjoy the break and stay safe!',3,'all','low',1,'2025-12-06','2025-12-11','2025-11-30 19:52:14','2025-11-30 19:52:14');
/*!40000 ALTER TABLE `announcements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `attendance`
--

DROP TABLE IF EXISTS `attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `attendance`
--

LOCK TABLES `attendance` WRITE;
/*!40000 ALTER TABLE `attendance` DISABLE KEYS */;
INSERT INTO `attendance` VALUES (1,1,28,'2025-11-13','present','be on time','2025-11-13 12:07:27'),(2,2,33,'2025-11-30','present','','2025-11-30 14:55:14'),(3,1,33,'2025-11-30','present','','2025-11-30 14:55:14'),(4,2,30,'2025-11-30','absent','','2025-11-30 14:55:25'),(5,1,30,'2025-11-30','present','','2025-11-30 14:55:25'),(6,2,28,'2025-11-30','present','','2025-11-30 14:55:35'),(7,1,28,'2025-11-30','present','','2025-11-30 14:55:35'),(8,2,30,'2025-11-30','present','','2025-11-30 14:58:34'),(9,1,30,'2025-11-30','absent','','2025-11-30 14:58:34'),(10,2,32,'2025-11-30','absent','','2025-11-30 14:58:48'),(11,1,32,'2025-11-30','present','','2025-11-30 14:58:48'),(12,2,32,'2025-11-30','absent','','2025-11-30 14:59:42'),(13,1,32,'2025-11-30','present','','2025-11-30 14:59:42'),(14,2,29,'2025-11-30','absent','','2025-11-30 14:59:48'),(15,1,29,'2025-11-30','present','','2025-11-30 14:59:48'),(16,2,29,'2025-11-30','absent','','2025-11-30 15:02:02'),(17,1,29,'2025-11-30','present','','2025-11-30 15:02:02'),(18,2,29,'2025-11-30','absent','','2025-11-30 15:03:09'),(19,1,29,'2025-11-30','present','','2025-11-30 15:03:09'),(20,2,29,'2025-11-30','absent','','2025-11-30 15:03:51'),(21,1,29,'2025-11-30','present','','2025-11-30 15:03:51'),(22,2,29,'2025-11-30','absent','','2025-11-30 15:04:07'),(23,1,29,'2025-11-30','present','','2025-11-30 15:04:07');
/*!40000 ALTER TABLE `attendance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `courses`
--

DROP TABLE IF EXISTS `courses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `courses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `course_code` varchar(10) COLLATE utf8mb4_general_ci NOT NULL,
  `course_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `course_code` (`course_code`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `courses`
--

LOCK TABLES `courses` WRITE;
/*!40000 ALTER TABLE `courses` DISABLE KEYS */;
INSERT INTO `courses` VALUES (1,'STEM','Science, Technology, Engineering, and Mathematics','STEM strand focuses on science, technology, engineering, and mathematics','2025-11-07 07:35:43'),(2,'ABM','Accountancy, Business and Management','ABM strand focuses on business, finance, and management','2025-11-07 07:35:43'),(3,'HUMSS','Humanities and Social Sciences','HUMSS strand focuses on humanities, social sciences, and liberal arts','2025-11-07 07:35:43'),(12,'JHS7','Junior High School',NULL,'2025-11-07 12:42:55'),(13,'JHS8','Junior High School Grade 8',NULL,'2025-11-07 12:42:55'),(14,'JHS9','Junior High School',NULL,'2025-11-07 12:42:55'),(15,'JHS10','Junior High School',NULL,'2025-11-07 12:42:55');
/*!40000 ALTER TABLE `courses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `enrollments`
--

DROP TABLE IF EXISTS `enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enrollments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `subject_id` int NOT NULL,
  `status` enum('enrolled','dropped','completed') COLLATE utf8mb4_unicode_ci DEFAULT 'enrolled',
  `enrolled_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `dropped_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `grade` decimal(5,2) DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_enrollment` (`student_id`,`subject_id`,`status`),
  KEY `idx_student_id` (`student_id`),
  KEY `idx_subject_id` (`subject_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `enrollments_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `enrollments_ibfk_2` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `enrollments`
--

LOCK TABLES `enrollments` WRITE;
/*!40000 ALTER TABLE `enrollments` DISABLE KEYS */;
INSERT INTO `enrollments` VALUES (1,1,27,'dropped','2025-12-01 08:38:17','2025-12-01 08:44:47',NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:44:47'),(2,1,23,'dropped','2025-12-01 08:38:17','2025-12-01 08:44:43',NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:44:43'),(3,1,25,'dropped','2025-12-01 08:38:17','2025-12-01 08:44:34',NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:44:34'),(4,2,26,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(5,2,24,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(6,2,23,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(7,2,21,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(8,3,22,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(9,3,21,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(10,3,23,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(11,3,29,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(12,4,29,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(13,4,23,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(14,4,25,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(15,4,28,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(16,5,23,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(17,5,30,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(18,5,25,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(19,5,27,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(20,5,28,'enrolled','2025-12-01 08:38:17',NULL,NULL,NULL,NULL,'2025-12-01 08:38:17','2025-12-01 08:38:17'),(21,1,33,'dropped','2025-12-01 08:43:08','2025-12-01 08:44:50',NULL,NULL,NULL,'2025-12-01 08:43:08','2025-12-01 08:44:50'),(22,1,28,'dropped','2025-12-01 08:45:06','2025-12-01 08:45:20',NULL,NULL,NULL,'2025-12-01 08:45:06','2025-12-01 08:45:20');
/*!40000 ALTER TABLE `enrollments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_reminders`
--

DROP TABLE IF EXISTS `event_reminders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `event_reminders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `event_type` enum('exam','school_event','assignment') COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_id` int NOT NULL,
  `reminder_date` datetime NOT NULL,
  `reminder_message` text COLLATE utf8mb4_unicode_ci,
  `is_sent` tinyint(1) DEFAULT '0',
  `sent_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_reminder_date` (`reminder_date`),
  KEY `idx_is_sent` (`is_sent`),
  KEY `idx_event_type` (`event_type`),
  CONSTRAINT `event_reminders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_reminders`
--

LOCK TABLES `event_reminders` WRITE;
/*!40000 ALTER TABLE `event_reminders` DISABLE KEYS */;
INSERT INTO `event_reminders` VALUES (1,1,'exam',7,'2025-11-30 00:00:00','Reminder: Exam tomorrow!',0,NULL,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(2,6,'exam',9,'2025-12-02 00:00:00','Reminder: Exam tomorrow!',0,NULL,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(3,8,'exam',11,'2025-12-04 00:00:00','Reminder: Exam tomorrow!',0,NULL,'2025-12-01 08:47:41','2025-12-01 08:47:41');
/*!40000 ALTER TABLE `event_reminders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `exam_schedules`
--

DROP TABLE IF EXISTS `exam_schedules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `exam_schedules` (
  `id` int NOT NULL AUTO_INCREMENT,
  `subject_id` int NOT NULL,
  `course_id` int DEFAULT NULL,
  `exam_title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `exam_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `room` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `exam_type` enum('quiz','midterm','final','assignment','project') COLLATE utf8mb4_unicode_ci DEFAULT 'quiz',
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) DEFAULT '1',
  `created_by` int DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `created_by` (`created_by`),
  KEY `idx_exam_date` (`exam_date`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_subject_id` (`subject_id`),
  KEY `idx_is_active` (`is_active`),
  CONSTRAINT `exam_schedules_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `exam_schedules_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE SET NULL,
  CONSTRAINT `exam_schedules_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `teachers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `exam_schedules`
--

LOCK TABLES `exam_schedules` WRITE;
/*!40000 ALTER TABLE `exam_schedules` DISABLE KEYS */;
INSERT INTO `exam_schedules` VALUES (7,21,2,'Midterm Exam - Subject 1','2025-12-01','09:00:00','11:00:00','Room 101','midterm',NULL,1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(8,21,2,'Final Exam - Subject 1','2025-12-08','09:00:00','11:00:00','Room 101','final',NULL,1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(9,22,3,'Midterm Exam - Subject 2','2025-12-03','09:00:00','11:00:00','Room 102','midterm',NULL,1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(10,22,3,'Final Exam - Subject 2','2025-12-10','09:00:00','11:00:00','Room 102','final',NULL,1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(11,23,15,'Midterm Exam - Subject 3','2025-12-05','09:00:00','11:00:00','Room 103','midterm',NULL,1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(12,23,15,'Final Exam - Subject 3','2025-12-12','09:00:00','11:00:00','Room 103','final',NULL,1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41');
/*!40000 ALTER TABLE `exam_schedules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `grade_entries`
--

DROP TABLE IF EXISTS `grade_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `grade_entries`
--

LOCK TABLES `grade_entries` WRITE;
/*!40000 ALTER TABLE `grade_entries` DISABLE KEYS */;
INSERT INTO `grade_entries` VALUES (1,1,28,'Q1',93,'2025-2025','SHS','good','2025-11-13 11:47:08');
/*!40000 ALTER TABLE `grade_entries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `grades`
--

DROP TABLE IF EXISTS `grades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `grades`
--

LOCK TABLES `grades` WRITE;
/*!40000 ALTER TABLE `grades` DISABLE KEYS */;
/*!40000 ALTER TABLE `grades` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schedules`
--

DROP TABLE IF EXISTS `schedules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schedules`
--

LOCK TABLES `schedules` WRITE;
/*!40000 ALTER TABLE `schedules` DISABLE KEYS */;
INSERT INTO `schedules` VALUES (1,28,1,1,'Tuesday','11:00:00','12:00:00','101','2025-11-13 11:40:54'),(2,27,1,1,'Monday','19:06:00','23:06:00','room 202','2025-11-30 15:06:59');
/*!40000 ALTER TABLE `schedules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `school_events`
--

DROP TABLE IF EXISTS `school_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `school_events` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `target_audience` enum('all','students','teachers','parents') COLLATE utf8mb4_unicode_ci DEFAULT 'all',
  `event_type` enum('holiday','meeting','activity','deadline','announcement') COLLATE utf8mb4_unicode_ci DEFAULT 'announcement',
  `is_active` tinyint(1) DEFAULT '1',
  `created_by` int DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `created_by` (`created_by`),
  KEY `idx_start_date` (`start_date`),
  KEY `idx_target_audience` (`target_audience`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_event_type` (`event_type`),
  CONSTRAINT `school_events_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `teachers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `school_events`
--

LOCK TABLES `school_events` WRITE;
/*!40000 ALTER TABLE `school_events` DISABLE KEYS */;
INSERT INTO `school_events` VALUES (6,'School Foundation Day','Annual celebration of the school founding','2025-12-01','2025-12-01',NULL,NULL,'Campus 1','all','activity',1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(7,'Parent-Teacher Conference','Meeting between parents and teachers','2025-12-06','2025-12-06',NULL,NULL,'Campus 2','parents','meeting',1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(8,'Science Fair','Annual science exhibition','2025-12-11','2025-12-11',NULL,NULL,'Campus 3','students','activity',1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(9,'Semester Break','Break between semesters','2025-12-16','2025-12-17',NULL,NULL,'Campus 4','all','holiday',1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41'),(10,'Enrollment Period','Period for student enrollment','2025-12-21','2025-12-21',NULL,NULL,'Campus 5','students','deadline',1,2,'2025-12-01 08:47:41','2025-12-01 08:47:41');
/*!40000 ALTER TABLE `school_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `student_relations`
--

DROP TABLE IF EXISTS `student_relations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_relations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `user_id` int NOT NULL,
  `relation` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `student_relations`
--

LOCK TABLES `student_relations` WRITE;
/*!40000 ALTER TABLE `student_relations` DISABLE KEYS */;
INSERT INTO `student_relations` VALUES (1,1,5,'Father','2025-11-13 11:31:05'),(2,3,12,'Mother','2025-11-27 14:10:11');
/*!40000 ALTER TABLE `student_relations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `students`
--

DROP TABLE IF EXISTS `students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
  `permanently_deleted` tinyint(1) NOT NULL DEFAULT '0',
  `archive_reason` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `student_id` (`student_id`),
  KEY `user_id` (`user_id`),
  KEY `course_id` (`course_id`),
  KEY `parent_user_id` (`parent_user_id`),
  CONSTRAINT `students_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `students_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`),
  CONSTRAINT `students_ibfk_3` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `students`
--

LOCK TABLES `students` WRITE;
/*!40000 ALTER TABLE `students` DISABLE KEYS */;
INSERT INTO `students` VALUES (1,1,'231-2244','matthew','meracap','evangelista',NULL,NULL,'09532584860','Blk 11 L14 Bougainvillea homes Brgy.Banadero Calamba City laguna',1,1,'E',2,NULL,NULL,'2025-11-07','active','2025-11-07 08:09:21','2025-11-30 14:52:35','static/uploads/avatars/user_1_1763905376.jpg','','O-','Jonathan Evangelista','Father','17matthewevangelista@gmail.com','Blk 11 L14 Bougainvillea homes Brgy.Banadero Calamba City laguna','John Matthew','Meracap','Evangelista','Marilyn','Meracap','Evangelista','','','','','','New Student',0,NULL),(2,6,'STEM-001','jonathan','harvey','arao',NULL,'Male',NULL,NULL,1,12,NULL,NULL,NULL,NULL,'2025-11-25','active','2025-11-25 08:22:02','2025-11-29 13:08:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'10984001951',NULL,NULL,NULL,NULL,'New Student',0,NULL),(3,8,'ABM-001','Juan',NULL,'Dela Cruz',NULL,NULL,NULL,NULL,2,11,NULL,NULL,NULL,NULL,NULL,'active','2025-11-25 09:49:47','2025-11-25 09:49:47',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'New Student',0,NULL),(4,9,'ABM-002','Maria',NULL,'Santos',NULL,NULL,NULL,NULL,2,11,NULL,NULL,NULL,NULL,NULL,'active','2025-11-25 09:49:47','2025-11-25 09:49:47',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'New Student',0,NULL),(5,10,'ABM-003','Pedro',NULL,'Reyes',NULL,NULL,NULL,NULL,2,12,NULL,NULL,NULL,NULL,NULL,'active','2025-11-25 09:49:48','2025-11-25 09:49:48',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'New Student',0,NULL),(6,11,'ABM-004','John Matthew','Meracap','Evangelista',NULL,'Male',NULL,NULL,2,11,NULL,NULL,NULL,NULL,'2025-11-25','active','2025-11-25 09:51:18','2025-11-25 09:51:18',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'10984001951',NULL,NULL,NULL,NULL,'New Student',0,NULL),(7,13,'ABM-005','Jervie','Rana','Avila',NULL,'Male',NULL,NULL,2,11,NULL,NULL,NULL,NULL,'2025-11-30','active','2025-11-30 03:03:24','2025-11-30 03:03:24',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'10984001951',NULL,NULL,NULL,NULL,'New Student',0,NULL);
/*!40000 ALTER TABLE `students` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subjects`
--

DROP TABLE IF EXISTS `subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subjects`
--

LOCK TABLES `subjects` WRITE;
/*!40000 ALTER TABLE `subjects` DISABLE KEYS */;
INSERT INTO `subjects` VALUES (1,'JHS7-MATH','Mathematics',12,3.0,NULL,'2025-11-13 11:22:34'),(2,'JHS7-ENG','English',12,3.0,NULL,'2025-11-13 11:22:34'),(3,'JHS7-SCI','Science',12,3.0,NULL,'2025-11-13 11:22:34'),(4,'JHS7-FIL','Filipino',12,3.0,NULL,'2025-11-13 11:22:34'),(5,'JHS7-MAP','MAPEH',12,3.0,NULL,'2025-11-13 11:22:34'),(6,'JHS8-MATH','Mathematics',13,3.0,NULL,'2025-11-13 11:22:34'),(7,'JHS8-ENG','English',13,3.0,NULL,'2025-11-13 11:22:34'),(8,'JHS8-SCI','Science',13,3.0,NULL,'2025-11-13 11:22:34'),(9,'JHS8-FIL','Filipino',13,3.0,NULL,'2025-11-13 11:22:34'),(10,'JHS8-MAP','MAPEH',13,3.0,NULL,'2025-11-13 11:22:34'),(11,'JHS9-MATH','Mathematics',14,3.0,NULL,'2025-11-13 11:22:34'),(12,'JHS9-ENG','English',14,3.0,NULL,'2025-11-13 11:22:34'),(13,'JHS9-SCI','Science',14,3.0,NULL,'2025-11-13 11:22:34'),(14,'JHS9-FIL','Filipino',14,3.0,NULL,'2025-11-13 11:22:34'),(15,'JHS9-MAP','MAPEH',14,3.0,NULL,'2025-11-13 11:22:34'),(16,'JHS10-MATH','Mathematics',15,3.0,NULL,'2025-11-13 11:22:34'),(17,'JHS10-ENG','English',15,3.0,NULL,'2025-11-13 11:22:34'),(18,'JHS10-SCI','Science',15,3.0,NULL,'2025-11-13 11:22:34'),(19,'JHS10-FIL','Filipino',15,3.0,NULL,'2025-11-13 11:22:34'),(20,'JHS10-MAP','MAPEH',15,3.0,NULL,'2025-11-13 11:22:34'),(21,'ICT101','Computer Systems Servicing',NULL,3.0,NULL,'2025-11-13 11:22:34'),(22,'ICT102','Programming Fundamentals',NULL,3.0,NULL,'2025-11-13 11:22:34'),(23,'ICT103','Networking Basics',NULL,3.0,NULL,'2025-11-13 11:22:34'),(24,'ICT104','Multimedia Technologies',NULL,3.0,NULL,'2025-11-13 11:22:34'),(25,'STEM101','General Mathematics',1,3.0,NULL,'2025-11-13 11:22:34'),(26,'STEM102','Statistics and Probability',1,3.0,NULL,'2025-11-13 11:22:34'),(27,'STEM103','Pre-Calculus',1,3.0,NULL,'2025-11-13 11:22:34'),(28,'STEM104','Basic Calculus',1,3.0,NULL,'2025-11-13 11:22:34'),(29,'STEM105','General Physics 1',1,3.0,NULL,'2025-11-13 11:22:34'),(30,'STEM106','General Physics 2',1,3.0,NULL,'2025-11-13 11:22:34'),(31,'STEM107','General Chemistry 1',1,3.0,NULL,'2025-11-13 11:22:34'),(32,'STEM108','General Chemistry 2',1,3.0,NULL,'2025-11-13 11:22:34'),(33,'STEM109','Biology 1',1,3.0,NULL,'2025-11-13 11:22:34'),(34,'STEM110','Biology 2',1,3.0,NULL,'2025-11-13 11:22:34'),(35,'ABM101','Fundamentals of Accountancy, Business and Management 1',2,3.0,NULL,'2025-11-13 11:22:34'),(36,'ABM102','Fundamentals of Accountancy, Business and Management 2',2,3.0,NULL,'2025-11-13 11:22:34'),(37,'ABM103','Business Math',2,3.0,NULL,'2025-11-13 11:22:34'),(38,'ABM104','Business Finance',2,3.0,NULL,'2025-11-13 11:22:34'),(39,'ABM105','Organization and Management',2,3.0,NULL,'2025-11-13 11:22:34'),(40,'ABM106','Principles of Marketing',2,3.0,NULL,'2025-11-13 11:22:34'),(41,'ABM107','Applied Economics',2,3.0,NULL,'2025-11-13 11:22:34'),(42,'ABM108','Business Ethics and Social Responsibility',2,3.0,NULL,'2025-11-13 11:22:34'),(43,'HUMSS101','Creative Writing',3,3.0,NULL,'2025-11-13 11:22:34'),(44,'HUMSS102','Creative Nonfiction',3,3.0,NULL,'2025-11-13 11:22:34'),(45,'HUMSS103','World Religions and Belief Systems',3,3.0,NULL,'2025-11-13 11:22:34'),(46,'HUMSS104','Introduction to World Religions and Belief Systems',3,3.0,NULL,'2025-11-13 11:22:34'),(47,'HUMSS105','Disciplines and Ideas in the Social Sciences',3,3.0,NULL,'2025-11-13 11:22:34'),(48,'HUMSS106','Disciplines and Ideas in Applied Social Sciences',3,3.0,NULL,'2025-11-13 11:22:34'),(49,'HUMSS107','Philippine Politics and Governance',3,3.0,NULL,'2025-11-13 11:22:34'),(50,'HUMSS108','Community Engagement, Solidarity, and Citizenship',3,3.0,NULL,'2025-11-13 11:22:34');
/*!40000 ALTER TABLE `subjects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teachers`
--

DROP TABLE IF EXISTS `teachers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teachers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `first_name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `last_name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `department` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `archived` tinyint DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `teachers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teachers`
--

LOCK TABLES `teachers` WRITE;
/*!40000 ALTER TABLE `teachers` DISABLE KEYS */;
INSERT INTO `teachers` VALUES (1,4,'teacher1','test','teacher1@gmail.com',NULL,'STEM','2025-11-07 11:41:26',0),(2,NULL,'Maria','Santos','maria.santos@school.edu',NULL,'Mathematics','2025-11-13 11:22:34',0),(3,NULL,'Juan','Cruz','juan.cruz@school.edu',NULL,'Science','2025-11-13 11:22:34',0),(4,NULL,'Ana','Reyes','ana.reyes@school.edu',NULL,'English','2025-11-13 11:22:34',0),(5,NULL,'Carlos','Garcia','carlos.garcia@school.edu',NULL,'Social Studies','2025-11-13 11:22:34',0),(8,14,'Lopit','Mo','lopitmo123@gmail.com',NULL,'HUMSS','2025-11-30 16:21:26',0);
/*!40000 ALTER TABLE `teachers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'matthew1234','scrypt:32768:8:1$c77kQxePXaJpX2T2$1f7e50b7c1bf20ce588b961c0ae01cb291a149b74fb3b80710be5e9a1c3435e461680f7aacc7a1b22c131f70d1a41fecd5982cb71760d901378c37472ac7e5e8','17matthewevangelista@gmail.com','231-2244','student','2025-11-07 08:09:21','2025-11-07 08:09:21',NULL,NULL,NULL),(2,'marilynevangelista1','scrypt:32768:8:1$M55DjbNRALFworCc$2867c29fd19c80b6470d9331a26c3ad57c1e9faacae23d62210c5b8c0d6cd8e7db8a0b4ccea0e8f0c57e9a3abf18a421911699938cfd6196be9f57b5c1423b20','marilynevangelista123@gmail.com',NULL,'parent','2025-11-07 10:53:51','2025-11-07 10:53:51',NULL,NULL,NULL),(3,'admin','scrypt:32768:8:1$iqe5nYRZGe9YFDGY$e6019fd1d4379df04dfe30461bb399b5ea443836c2e7c0b69e2787e3c1e5addbc0f8659e5b3fbd20583a0b767ea19d751eb84815bb5879210acf1ebe969ce012','17matthewevangelista',NULL,'admin','2025-11-07 11:39:31','2025-11-07 11:39:31',NULL,NULL,NULL),(4,'teacher1','scrypt:32768:8:1$dQvNkunntYHr7qfX$a6dbe83f5de292d16076937a02bbc16bd26bcc963bf27960fb94d941023fdee04f0de161f03469f5fd6a84238b60bc0835a5cf6b4b37b1a9e80ff00676d815a8','teacher1@gmail.com',NULL,'teacher','2025-11-07 11:41:26','2025-11-07 11:41:26',NULL,NULL,NULL),(5,'jonathan1','scrypt:32768:8:1$QdIVEbWNbYsSY4Mn$55a14c73ecf86172d84a7a21dd44b9eab607133b581faa649e6490baa1dac523c4bb1be7198cded6988a81206d6b715650cfd7cc4cf2898215554e11ab5ce54d','jonathanevangelista@gmail.com',NULL,'parent','2025-11-13 11:12:56','2025-11-13 11:30:35','static/uploads/avatars/user_5_1763033435.jpg',NULL,NULL),(6,'jonathanharveyarao1','scrypt:32768:8:1$6VyeARd2WaXJgklg$43a1c5cbc4494507d59d34213d9cb7e7906b730d463a2178d149d789700d2511662a7506e22664a1012927c9a8889177b123f13c590ee6d3bbb464baadacdbff','jonathanarao@gmail.com','STEM-001','student','2025-11-25 08:22:02','2025-11-25 08:22:02',NULL,NULL,NULL),(8,'abm-001','scrypt:32768:8:1$5dejLWZz93Rkf5rm$5136cada41ca4809570eeeb8b69129b552f9548bb41dc9c7242c57a71757b2ec07d200abb1bf4cde5020d789688cc38d37147f03d2cbe327dd2f77c8fda7e612',NULL,'ABM-001','student','2025-11-25 09:49:47','2025-11-25 09:49:47',NULL,NULL,NULL),(9,'abm-002','scrypt:32768:8:1$rMuVq7dwh4QQlpXb$1733ab74d13ea322d4899cff72614c9b1229b926676c040bfb26a7b69fbc7f359ac863af507556624cdc384822e7a5fe4eb58b416a352ecd2158bcc1ac7bea78',NULL,'ABM-002','student','2025-11-25 09:49:47','2025-11-25 09:49:47',NULL,NULL,NULL),(10,'abm-003','scrypt:32768:8:1$LOauraj8cOAmOVr3$e417a6d377501e550ace9c59d565a0d168549bf04a7bc8ea12e51441356ab32cb1370ea81ecc50c3363578217ec58ec32e35bf275479987eb6b2f926671f301e',NULL,'ABM-003','student','2025-11-25 09:49:48','2025-11-25 09:49:48',NULL,NULL,NULL),(11,'matmat123','scrypt:32768:8:1$6fATsqD2KstNCSig$7f8fb44983084240748e12234c3907737443386c379a0308f8b58f40b12099a1745a9b6c7af71bb4bcc3cf5e02cb91a3f73b879229fa9d4d5d810c755796e2dd','17matthewevangelista@gmail.com','ABM-004','student','2025-11-25 09:51:18','2025-11-25 09:51:18',NULL,NULL,NULL),(12,'helloworld123','scrypt:32768:8:1$pRICmBYNyfc7mARP$701e6a7f2dd8a4aea5273de9d69128db7105f90db209c0c222e39094b9b94f382e28c07179aeca53e0ad9b8cbe928d0227b56fd4c60be78b6fa86f7fe8ca1dae','helloworld123@gmail.com',NULL,'parent','2025-11-27 14:09:19','2025-11-27 14:09:19',NULL,NULL,NULL),(13,'jervieavila94@gmail.com','scrypt:32768:8:1$Bve4i6Ahj7h2NZdj$c5dffe790fb61428b52d53b07e631a8151a7d5dddb15e4281d05608275d4023f5238b10e8ae289442946693420b0534cdc66ad9eb97d4c3d5214fa5e5906b199','jervieavila94@gmail.com','ABM-005','student','2025-11-30 03:03:24','2025-11-30 03:03:24',NULL,NULL,NULL),(14,'lopitmo123','scrypt:32768:8:1$4E0XjMODZ4FsWyTe$e75c910ac6d5c2d35b1114cfb122431301ee8ce184a37e7e37a565de68ce759d46303ef6a0beb702b88dad3f40ed8daa2ab8348ce48dc77a3a74f974716878d0','lopitmo123@gmail.com',NULL,'teacher','2025-11-30 16:21:26','2025-11-30 16:21:26',NULL,NULL,NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-01 19:37:50
