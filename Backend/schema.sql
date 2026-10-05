-- ==========================================================
-- 💈 BARBER SHOP MANAGEMENT & COMMISSION SETTLEMENT SYSTEM
-- Database Schema for MySQL on Railway / Cloud
-- ==========================================================

CREATE DATABASE IF NOT EXISTS `barber_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `barber_db`;

-- ----------------------------------------------------------
-- 1. ตารางจัดการข้อมูลผู้ใช้งานและช่างตัดผม (users)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
    `user_id` INT AUTO_INCREMENT PRIMARY KEY,
    `line_uid` VARCHAR(100) NULL COMMENT 'LINE User ID ของช่าง/เจ้าของร้าน',
    `full_name` VARCHAR(255) NOT NULL COMMENT 'ชื่อ-นามสกุล หรือชื่อเรียกช่าง',
    `role` VARCHAR(50) NOT NULL DEFAULT 'barber' COMMENT 'owner หรือ barber',
    `commission_rate` DECIMAL(5,2) NOT NULL DEFAULT 50.00 COMMENT 'อัตราส่วนแบ่งค่าคอมมิชชัน เช่น 50.00%',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1=เปิดใช้งาน, 0=ปิดใช้งาน',
    `image_url` VARCHAR(500) NULL DEFAULT '' COMMENT 'ลิงก์รูปภาพโปรไฟล์ช่าง',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 2. ตารางจัดการรายการบริการและราคา (services)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `services` (
    `service_id` INT AUTO_INCREMENT PRIMARY KEY,
    `service_name` VARCHAR(255) NOT NULL COMMENT 'ชื่อประเภทบริการ เช่น ตัดผมชายวินเทจ, สระไดร์',
    `base_price` DECIMAL(10,2) NOT NULL COMMENT 'ราคาค่าบริการมาตรฐาน',
    `image_url` VARCHAR(500) NULL DEFAULT '' COMMENT 'ลิงก์รูปภาพตัวอย่างบริการ',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1=เปิดให้บริการ, 0=ปิดบริการ',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 3. ตารางจัดการข้อมูลธุรกรรมและรายรับเงินเข้า (transactions)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `transactions` (
    `transaction_id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL COMMENT 'รหัสช่างผู้ให้บริการ',
    `service_id` INT NOT NULL COMMENT 'รหัสบริการที่ทำ',
    `customer_uid` VARCHAR(100) NULL COMMENT 'LINE User ID ของลูกค้า',
    `payment_method` ENUM('transfer', 'cash') NOT NULL DEFAULT 'transfer' COMMENT 'วิธีชำระเงิน: transfer=โอน, cash=เงินสด',
    `actual_price` DECIMAL(10,2) NOT NULL COMMENT 'ยอดเงินที่ชำระจริง',
    `commission_amount` DECIMAL(10,2) NOT NULL COMMENT 'ค่าคอมมิชชันที่คำนวณได้',
    `slip_image_url` VARCHAR(255) NULL COMMENT 'URL หรือลิงก์รูปภาพสลิปโอนเงิน',
    `trans_ref` VARCHAR(100) NULL UNIQUE COMMENT 'เลขอ้างอิงสลิปจากธนาคารเพื่อกันสลิปซ้ำ',
    `status` ENUM('completed', 'voided') NOT NULL DEFAULT 'completed' COMMENT 'สถานะบิล: completed=สำเร็จ, voided=โมฆะ',
    `payout_status` ENUM('unsettled', 'settled') NOT NULL DEFAULT 'unsettled' COMMENT 'สถานะเคลียร์เงินช่าง: unsettled=รอเคลียร์, settled=เคลียร์แล้ว',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_service_id` (`service_id`),
    INDEX `idx_payout_status` (`payout_status`),
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE,
    FOREIGN KEY (`service_id`) REFERENCES `services` (`service_id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 4. ตารางจัดการการตัดรอบเคลียร์เงินจ่ายช่าง (payouts)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `payouts` (
    `payout_id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL COMMENT 'รหัสช่างที่ได้รับเงิน',
    `start_date` DATE NOT NULL COMMENT 'วันที่เริ่มต้นของรอบเคลียร์ยอด',
    `end_date` DATE NOT NULL COMMENT 'วันที่สิ้นสุดของรอบเคลียร์ยอด',
    `total_jobs` INT NOT NULL DEFAULT 0 COMMENT 'จำนวนหัว/งานที่ตัดในรอบนี้',
    `total_revenue` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'ยอดรวมค่าบริการทั้งหมด',
    `commission_total` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'ยอดรวมค่าคอมมิชชันสะสม',
    `net_payout` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'ยอดเงินโอนเคลียร์สุทธิ',
    `payout_slip_url` VARCHAR(255) NULL COMMENT 'ลิงก์สลิปหลักฐานการโอนเงินเคลียร์ยอดให้ช่าง',
    `payout_status` ENUM('pending', 'paid') NOT NULL DEFAULT 'paid' COMMENT 'สถานะการจ่ายเงิน',
    `paid_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'วันและเวลาที่โอนเงินสำเร็จ',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_payout_user` (`user_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- ข้อมูลตัวอย่างเริ่มต้น (Seed Data)
-- ----------------------------------------------------------
INSERT INTO `users` (`user_id`, `line_uid`, `full_name`, `role`, `commission_rate`, `is_active`) VALUES
(1, 'U1234567890abcdef', 'ช่างเอก (Master Barber)', 'barber', 50.00, 1),
(2, 'U0987654321fedcba', 'ช่างบอย (Senior Barber)', 'barber', 50.00, 1),
(3, 'U1122334455aabbcc', 'เจ้าของร้าน (Admin/Owner)', 'owner', 0.00, 1)
ON DUPLICATE KEY UPDATE `full_name`=VALUES(`full_name`);

INSERT INTO `services` (`service_id`, `service_name`, `base_price`, `is_active`) VALUES
(1, 'ตัดผมชายวินเทจ (Vintage Haircut)', 350.00, 1),
(2, 'ตัดผม + สระไดร์เซ็ตทรง (Cut & Wash)', 450.00, 1),
(3, 'โกนหนวดเคราจัดทรง (Beard Shave & Trim)', 250.00, 1),
(4, 'ทำสีผมแฟชั่น (Hair Coloring)', 1200.00, 1),
(5, 'ดัดวอลลุ่มผมชาย (Hair Perm)', 1500.00, 1)
ON DUPLICATE KEY UPDATE `service_name`=VALUES(`service_name`), `base_price`=VALUES(`base_price`);
