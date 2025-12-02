-- Create announcements table
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
);

-- Insert sample announcements
INSERT INTO announcements (title, content, target_audience, priority, posted_by) VALUES
('Welcome Back Students!', 'We are excited to start the new school year. Please check your schedules and attend your classes regularly.', 'students', 'high', 1),
('Midterm Exams Announcement', 'Midterm examinations will begin next week. Please prepare well and review your lessons.', 'students', 'high', 1),
('New Library Hours', 'The library will be open from 8 AM to 8 PM Monday to Friday. Weekends from 9 AM to 5 PM.', 'all', 'medium', 1),
('School Festival Next Month', 'Join us for our annual school festival next month. Lots of activities and prizes await!', 'all', 'medium', 1);
