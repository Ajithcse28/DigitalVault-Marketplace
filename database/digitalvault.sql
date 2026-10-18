-- ============================================================================
-- DigitalVault Relational Database Schema & Seed Data
-- Target: MySQL 8.0+ (InnoDB, utf8mb4) | Compatible notes for PostgreSQL 16+
-- ============================================================================

CREATE DATABASE IF NOT EXISTS digitalvault
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE digitalvault;

-- 1. ROLES
CREATE TABLE IF NOT EXISTS roles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE, -- ROLE_CUSTOMER, ROLE_ADMIN
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. USERS
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(25),
    email_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(128),
    reset_password_token VARCHAR(128),
    reset_token_expires_at TIMESTAMP NULL,
    preferred_locale VARCHAR(10) DEFAULT 'en', -- 'en' or 'ta' (Tamil)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_email (email)
) ENGINE=InnoDB;

-- USER_ROLES Join Table
CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 3. CATEGORIES
CREATE TABLE IF NOT EXISTS categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(120) NOT NULL UNIQUE,
    description TEXT,
    icon_name VARCHAR(60) DEFAULT 'Folder',
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_categories_slug (slug)
) ENGINE=InnoDB;

-- 4. PRODUCTS
CREATE TABLE IF NOT EXISTS products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(220) NOT NULL UNIQUE,
    short_description VARCHAR(500) NOT NULL,
    detailed_description TEXT NOT NULL,
    whats_included TEXT,
    product_type VARCHAR(50) NOT NULL, -- PDF_EBOOK, GOOGLE_DRIVE, VIDEO_COURSE, RESUME_TEMPLATE, RESUME_BUNDLE, STUDY_MATERIAL, SOFTWARE_ASSET, OTHER
    career_track VARCHAR(80),          -- Fresher, Experienced Professional, IT, Software Developer, General
    price_inr DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    discount_price_inr DECIMAL(10, 2) NULL,
    is_free BOOLEAN DEFAULT FALSE,
    cover_image_url VARCHAR(500),
    preview_images_json JSON,
    preview_video_url VARCHAR(500),
    file_format VARCHAR(80),           -- e.g., 'PDF, DOCX, ZIP'
    file_size_label VARCHAR(50),       -- e.g., '18.4 MB'
    video_duration_label VARCHAR(50),  -- e.g., '14h 30m (42 Lessons)'
    compatibility_info VARCHAR(255),   -- e.g., 'MS Word, Google Docs, ATS-Friendly PDF'
    is_featured BOOLEAN DEFAULT FALSE,
    is_bestseller BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT TRUE,
     is_demo_product BOOLEAN DEFAULT TRUE,
    sales_count INT DEFAULT 0,
    rating_avg DECIMAL(3, 2) DEFAULT 0.00,
    review_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id),
    INDEX idx_products_category (category_id),
    INDEX idx_products_published (is_published),
    INDEX idx_products_type (product_type)
) ENGINE=InnoDB;

-- 5. DIGITAL_ASSETS (Private storage references, Drive file IDs, or private video IDs; NEVER exposed before purchase)
CREATE TABLE IF NOT EXISTS digital_assets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    asset_name VARCHAR(200) NOT NULL,
    delivery_type VARCHAR(40) NOT NULL, -- PRIVATE_FILE, GOOGLE_DRIVE_API, AUTHORIZED_VIDEO
    storage_provider VARCHAR(40) NOT NULL, -- LOCAL_VAULT, S3_PRIVATE, GOOGLE_DRIVE, VIMEO_PRIVATE, MUX_SIGNED
    storage_key_or_file_id VARCHAR(500) NOT NULL, -- Private path outside webroot, Drive fileId, or Video ID
    mime_type VARCHAR(100),
    file_size_bytes BIGINT DEFAULT 0,
    checksum_sha256 VARCHAR(64),
    access_notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_assets_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_assets_product (product_id)
) ENGINE=InnoDB;

-- 6. COUPONS
CREATE TABLE IF NOT EXISTS coupons (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(40) NOT NULL UNIQUE,
    description VARCHAR(255),
    discount_type VARCHAR(20) NOT NULL, -- PERCENTAGE, FIXED_INR
    discount_value DECIMAL(10, 2) NOT NULL,
    min_order_amount_inr DECIMAL(10, 2) DEFAULT 0.00,
    max_discount_inr DECIMAL(10, 2) NULL,
    usage_limit INT NULL,
    used_count INT DEFAULT 0,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_coupons_code (code)
) ENGINE=InnoDB;

-- 7. ORDERS
CREATE TABLE IF NOT EXISTS orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(64) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    subtotal_inr DECIMAL(10, 2) NOT NULL,
    discount_inr DECIMAL(10, 2) DEFAULT 0.00,
    tax_inr DECIMAL(10, 2) DEFAULT 0.00,
    total_amount_inr DECIMAL(10, 2) NOT NULL,
    coupon_id BIGINT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- PENDING, PAID, FAILED, REFUND_REQUESTED, REFUNDED
    razorpay_order_id VARCHAR(120) UNIQUE,
    receipt_number VARCHAR(80),
    customer_ip VARCHAR(64),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    paid_at TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_orders_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(id),
    INDEX idx_orders_user (user_id),
    INDEX idx_orders_status (status),
    INDEX idx_orders_rzp_order (razorpay_order_id)
) ENGINE=InnoDB;

-- 8. ORDER_ITEMS
CREATE TABLE IF NOT EXISTS order_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_title_snapshot VARCHAR(200) NOT NULL,
    product_type_snapshot VARCHAR(50) NOT NULL,
    unit_price_inr DECIMAL(10, 2) NOT NULL,
    final_price_inr DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(id),
    INDEX idx_order_items_order (order_id)
) ENGINE=InnoDB;

-- 9. PAYMENTS
CREATE TABLE IF NOT EXISTS payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    provider VARCHAR(30) NOT NULL DEFAULT 'RAZORPAY',
    razorpay_order_id VARCHAR(120) NOT NULL,
    razorpay_payment_id VARCHAR(120) UNIQUE,
    razorpay_signature VARCHAR(255),
    amount_inr DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    payment_method VARCHAR(50), -- UPI, CARD, NETBANKING, WALLET
    status VARCHAR(30) NOT NULL DEFAULT 'CREATED', -- CREATED, CAPTURED, VERIFIED, FAILED, REFUNDED
    signature_verified BOOLEAN DEFAULT FALSE,
    refund_status VARCHAR(30) DEFAULT 'NONE', -- NONE, PARTIAL, FULL
    raw_webhook_payload JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP NULL,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(id),
    INDEX idx_payments_order (order_id),
    INDEX idx_payments_rzp_payment (razorpay_payment_id)
) ENGINE=InnoDB;

-- 10. PRODUCT_ACCESS (Entitlement table granted strictly after verified payment)
CREATE TABLE IF NOT EXISTS product_access (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,
    access_status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, REVOKED_REFUND, EXPIRED
    drive_permission_id VARCHAR(120) NULL,
    drive_granted_email VARCHAR(160) NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    UNIQUE KEY uq_user_product_access (user_id, product_id, order_id),
    CONSTRAINT fk_access_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_access_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_access_order FOREIGN KEY (order_id) REFERENCES orders(id),
    INDEX idx_access_user (user_id)
) ENGINE=InnoDB;

-- 11. DOWNLOADS (Audit log of signed URL generations & asset downloads)
CREATE TABLE IF NOT EXISTS downloads (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    digital_asset_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,
    signed_token_hash VARCHAR(128) NOT NULL,
    ip_address VARCHAR(64),
    user_agent VARCHAR(255),
    downloaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_downloads_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_downloads_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_downloads_asset FOREIGN KEY (digital_asset_id) REFERENCES digital_assets(id),
    INDEX idx_downloads_user (user_id)
) ENGINE=InnoDB;

-- 12. WISHLISTS
CREATE TABLE IF NOT EXISTS wishlists (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_wishlist_user_product (user_id, product_id),
    CONSTRAINT fk_wishlist_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_wishlist_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 13. REVIEWS
CREATE TABLE IF NOT EXISTS reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT NOT NULL,
    is_verified_purchase BOOLEAN DEFAULT TRUE,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_review_user_product (product_id, user_id),
    CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 14. SUPPORT_TICKETS
CREATE TABLE IF NOT EXISTS support_tickets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ticket_number VARCHAR(40) NOT NULL UNIQUE,
    user_id BIGINT NULL,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL,
    subject VARCHAR(200) NOT NULL,
    category VARCHAR(60) NOT NULL, -- DOWNLOAD_ISSUE, PAYMENT_QUERY, DRIVE_ACCESS, REFUND_REQUEST, GENERAL
    order_number VARCHAR(64) NULL,
    message TEXT NOT NULL,
    status VARCHAR(30) DEFAULT 'OPEN', -- OPEN, IN_PROGRESS, RESOLVED, CLOSED
    admin_reply TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_tickets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_tickets_status (status)
) ENGINE=InnoDB;

-- ============================================================================
-- SEED DATA (ROLES, DEMO USERS, 8 CATEGORIES, 6+ DEMO PRODUCTS, COUPONS)
-- ============================================================================

INSERT INTO roles (id, name, description) VALUES
(1, 'ROLE_CUSTOMER', 'Standard customer with access to purchased digital assets'),
(2, 'ROLE_ADMIN', 'Platform administrator with product, order, and vault management privileges');

-- Passwords below are BCrypt hashes for 'Admin@123' and 'Customer@123' (demo environment only)
INSERT INTO users (id, full_name, email, password_hash, phone, email_verified, preferred_locale) VALUES
(1, 'Arjun Subramanian (Admin)', 'admin@digitalvault.in', '$2a$12$R9h/cIPz0gi.URNNX3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUW', '+91 98401 11223', TRUE, 'en'),
(2, 'Priya Darshini (Demo Customer)', 'priya@example.com', '$2a$12$R9h/cIPz0gi.URNNX3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUW', '+91 98402 44556', TRUE, 'en');

INSERT INTO user_roles (user_id, role_id) VALUES (1, 1), (1, 2), (2, 1);

INSERT INTO categories (id, name, slug, description, icon_name, display_order) VALUES
(1, 'PDF & eBooks', 'pdf-ebooks', 'In-depth architecture handbooks, technical guides, and printable reference books.', 'BookOpen', 1),
(2, 'Google Drive Resources', 'google-drive-resources', 'Curated cloud resource folders, project boilerplates, and permission-managed workspaces.', 'HardDrive', 2),
(3, 'Video Courses', 'video-courses', 'HD private streaming masterclasses with hands-on project walkthroughs.', 'PlayCircle', 3),
(4, 'Resume Templates', 'resume-templates', 'ATS-optimized single-role resume templates in DOCX and PDF formats.', 'FileText', 4),
(5, 'Resume Bundles', 'resume-bundles', 'Multi-level career packs with cover letters, portfolio templates, and LinkedIn guides.', 'Layers', 5),
(6, 'Study Materials', 'study-materials', 'Structured semester notes, system design cheat sheets, and DSA workbooks.', 'GraduationCap', 6),
(7, 'Interview Preparation', 'interview-preparation', 'Mock question banks, coding patterns, and behavioral interview frameworks.', 'Award', 7),
(8, 'Software & Digital Assets', 'software-digital-assets', 'UI kits, Spring Boot starters, Postman collections, and developer utilities.', 'Cpu', 8),
(9, 'Other Digital Products', 'other-digital-products', 'Productivity trackers, Notion templates, and specialized career toolkits.', 'Package', 9);

-- Seed Required Demo Products (Clearly marked as Demo Products)
INSERT INTO products (
    id, category_id, title, slug, short_description, detailed_description, whats_included,
    product_type, career_track, price_inr, discount_price_inr, is_free,
    file_format, file_size_label, video_duration_label, compatibility_info,
    is_featured, is_bestseller, is_published, is_demo_product, sales_count, rating_avg, review_count
) VALUES
(
    1, 4,
    'Ultimate Java Developer Resume Template',
    'ultimate-java-developer-resume-template',
    'ATS-tested resume template tailored for Java, Spring Boot, and Microservices engineers.',
    'Stand out in technical screenings with a clean, single-column and dual-column ATS-compliant resume layout crafted specifically for Java backend and full-stack developers. Includes action-verb banks for Spring Boot, Kafka, Docker, and AWS metrics.',
    '["Editable MS Word (.docx) Template", "Google Docs Direct Template", "ATS-Verified PDF Layout Guide", "50+ Java/Spring Impact Bullet Examples"]',
    'RESUME_TEMPLATE', 'Software Developer', 299.00, 149.00, FALSE,
    'DOCX, PDF', '4.2 MB', NULL, 'MS Word 2016+, Google Docs, macOS Pages, Adobe Acrobat',
    TRUE, TRUE, TRUE, TRUE, 342, 4.90, 28
),
(
    2, 5,
    'Full Stack Developer Resume Bundle',
    'full-stack-developer-resume-bundle',
    'Complete career kit for Fresher to Senior Full-Stack Engineers (React + Java/Node).',
    'Comprehensive 5-in-1 resume and portfolio bundle covering Fresher, Mid-Level (2-5 YOE), and Senior Architect profiles. Designed to pass modern enterprise ATS filters while highlighting GitHub architecture and system metrics.',
    '["3 Experience-Tier Resume Templates (DOCX & PDF)", "Matching Technical Cover Letter Pack", "GitHub Profile README Markdown Template", "Recruiter Cold-Email & LinkedIn Outreach Scripts"]',
    'RESUME_BUNDLE', 'Experienced Professional', 499.00, 249.00, FALSE,
    'ZIP (DOCX, PDF, MD)', '16.8 MB', NULL, 'MS Word, Google Docs, Markdown Editors, PDF Readers',
    TRUE, TRUE, TRUE, TRUE, 289, 4.85, 24
),
(
    3, 7,
    'Java Interview Preparation PDF',
    'java-interview-preparation-pdf',
    '250+ curated Java 21, JVM internals, Concurrency, and Spring Security questions with diagrams.',
    'A structured 195-page engineering handbook covering Core Java 21 (Virtual Threads, Record Patterns), JVM Memory Model, Garbage Collection tuning, Multithreading, JPA N+1 optimization, and real product-company interview rounds.',
    '["195-Page Bookmarked PDF eBook", "JVM Memory & GC Cheat Sheet Poster (PDF)", "Top 40 Coding Scenarios with Complexity Analysis"]',
    'PDF_EBOOK', 'IT', 199.00, 99.00, FALSE,
    'PDF', '12.5 MB', NULL, 'Any PDF Viewer (Desktop, Tablet, Mobile, Kindle)',
    TRUE, TRUE, TRUE, TRUE, 518, 4.95, 46
),
(
    4, 1,
    'Spring Boot Project Guide',
    'spring-boot-project-guide',
    'Production-grade blueprint for building secure Spring Boot 3, JWT, Razorpay, and MySQL/PostgreSQL apps.',
    'Step-by-step architectural guide that walks through designing clean layered Spring Boot 3 applications: DTO validation, global exception handling, Spring Security 6 JWT filter chains, HMAC webhook verification, and Flyway/SQL migrations.',
    '["240-Page Architecture PDF Guide", "Database Schema & ER Diagram Pack", "Postman API Collection JSON", "Production Security Checklist"]',
    'PDF_EBOOK', 'Software Developer', 399.00, 199.00, FALSE,
    'PDF, JSON', '21.0 MB', NULL, 'PDF Readers, Postman v10+, IntelliJ IDEA / Eclipse',
    TRUE, FALSE, TRUE, TRUE, 215, 4.80, 19
),
(
    5, 3,
    'Web Development Video Course',
    'web-development-video-course',
    '16-hour HD project-based masterclass covering React 18, TypeScript, Tailwind CSS, and Spring Boot REST APIs.',
    'Master modern full-stack engineering from scratch to cloud deployment. Stream 48 chapters of ad-free 1080p video lessons through our authorized private video player, complete with downloadable lab exercises and timestamped code checkpoints.',
    '["48 HD Private Streaming Video Modules (16h 20m)", "Downloadable Lesson Slides & Architecture Diagrams", "Full Source Code Checkpoints", "Certificate of Completion Template"]',
    'VIDEO_COURSE', 'Fresher', 999.00, 499.00, FALSE,
    'Authorized HD Video Stream + ZIP Labs', 'Streaming + 85 MB Labs', '16h 20m (48 Lessons)', 'Modern Web Browsers (Chrome, Firefox, Safari, Edge) on Desktop & Mobile',
    TRUE, TRUE, TRUE, TRUE, 176, 4.92, 31
),
(
    6, 2,
    'Software Developer Career Resources Bundle',
    'software-developer-career-resources-bundle',
    'Authorized Google Drive resource vault with DSA sheets, system design templates, and resume kits.',
    'Gain automated, permission-controlled reader access to our curated Google Drive Engineering Vault. Upon verified payment, our backend uses the Google Drive API v3 to grant your email direct viewer/downloader permissions to the private folder.',
    '["Direct Google Drive API Folder Access Grant", "System Design Case Studies (15 Architecture Docs)", "450-Problem DSA Tracker Spreadsheet", "Fresher & Experienced Resume Templates"]',
    'GOOGLE_DRIVE', 'Software Developer', 599.00, 299.00, FALSE,
    'Google Drive Folder (PDF, XLSX, DOCX)', '140+ MB Cloud Vault', NULL, 'Google Drive Account (Gmail / Workspace) or Authenticated Vault Download',
    TRUE, FALSE, TRUE, TRUE, 264, 4.88, 22
),
(
    7, 6,
    'System Design & Microservices Study Notes',
    'system-design-microservices-study-notes',
    'Visual handwritten & digital study notes on caching, sharding, Kafka, and load balancing.',
    'Concise, high-yield visual notes created for rapid revision before high-level design (HLD) and low-level design (LLD) interviews. Covers CAP theorem, consistent hashing, rate limiters, and distributed transactions.',
    '["88-Page High-Resolution Illustrated PDF", "Quick-Reference Architecture Flashcards"]',
    'STUDY_MATERIAL', 'Experienced Professional', 149.00, 0.00, TRUE,
    'PDF', '9.4 MB', NULL, 'All Devices (PDF)',
    FALSE, FALSE, TRUE, TRUE, 610, 4.90, 52
),
(
    8, 8,
    'Spring Boot + React SaaS Starter Kit Assets',
    'spring-boot-react-saas-starter-kit-assets',
    'Reusable UI component templates, JWT security filter boilerplate, and OpenAPI specs.',
    'Accelerate your side projects with pre-configured Tailwind UI layouts, Axios interceptor patterns, and Spring Boot 3 security configurations packaged in a clean archive.',
    '["ZIP Archive with Frontend & Backend Boilerplate Modules", "Swagger OpenAPI 3.0 Spec File", "Docker Compose Dev Setup"]',
    'SOFTWARE_ASSET', 'Software Developer', 349.00, 249.00, FALSE,
    'ZIP', '14.1 MB', NULL, 'Node.js 20+, JDK 21, Docker',
    FALSE, FALSE, TRUE, TRUE, 94, 4.75, 11
);

-- Seed Private Digital Assets (Paths are strictly internal vault keys / Drive IDs)
INSERT INTO digital_assets (id, product_id, asset_name, delivery_type, storage_provider, storage_key_or_file_id, mime_type, file_size_bytes, access_notes) VALUES
(1, 1, 'Ultimate_Java_Developer_Resume_Pack.zip', 'PRIVATE_FILE', 'LOCAL_VAULT', 'vault/resumes/java-dev-resume-v2.zip', 'application/zip', 4404019, 'Signed HMAC download link valid for 15 minutes'),
(2, 2, 'Full_Stack_Resume_Bundle_Complete.zip', 'PRIVATE_FILE', 'LOCAL_VAULT', 'vault/bundles/fullstack-career-bundle.zip', 'application/zip', 17616076, 'Signed HMAC download link valid for 15 minutes'),
(3, 3, 'Java_21_Interview_Prep_Handbook.pdf', 'PRIVATE_FILE', 'LOCAL_VAULT', 'vault/ebooks/java21-interview-handbook.pdf', 'application/pdf', 13107200, 'Watermarked & signed PDF download stream'),
(4, 4, 'Spring_Boot_3_Production_Guide.pdf', 'PRIVATE_FILE', 'LOCAL_VAULT', 'vault/ebooks/springboot3-production-guide.pdf', 'application/pdf', 22020096, 'Signed download stream'),
(5, 5, 'Full_Stack_Web_Dev_Masterclass_Stream', 'AUTHORIZED_VIDEO', 'VIMEO_PRIVATE', 'video_vault_course_48_modules_hd', 'video/mp4', 0, 'Authenticated session token required for HLS stream playback'),
(6, 6, 'Career_Resources_Google_Drive_Vault', 'GOOGLE_DRIVE_API', 'GOOGLE_DRIVE', '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms_DEMO_VAULT', 'application/vnd.google-apps.folder', 146800640, 'Granted via Google Drive Permissions API v3 (role: reader) + fallback signed archive'),
(7, 7, 'System_Design_Visual_Study_Notes.pdf', 'PRIVATE_FILE', 'LOCAL_VAULT', 'vault/study/system-design-notes.pdf', 'application/pdf', 9856614, 'Free authenticated download'),
(8, 8, 'SaaS_Starter_Kit_Assets.zip', 'PRIVATE_FILE', 'LOCAL_VAULT', 'vault/software/saas-starter-assets.zip', 'application/zip', 14784921, 'Signed HMAC download link');

-- Seed Coupons
INSERT INTO coupons (code, description, discount_type, discount_value, min_order_amount_inr, max_discount_inr, usage_limit, is_active) VALUES
('VAULT20', 'Flat 20% off on orders above ₹199', 'PERCENTAGE', 20.00, 199.00, 250.00, 500, TRUE),
('CAREER50', '₹50 instant discount on any Resume or Interview pack', 'FIXED_INR', 50.00, 149.00, 50.00, 200, TRUE),
('LAUNCH100', '₹100 off on bundles and video courses above ₹399', 'FIXED_INR', 100.00, 399.00, 100.00, 100, TRUE);

-- Seed Sample Verified Order for Demo Customer (Priya)
INSERT INTO orders (id, order_number, user_id, subtotal_inr, discount_inr, tax_inr, total_amount_inr, status, razorpay_order_id, receipt_number, paid_at) VALUES
(1, 'DV-2026-1001', 2, 348.00, 0.00, 0.00, 348.00, 'PAID', 'order_DemoRzp998811', 'RCPT-2026-1001', CURRENT_TIMESTAMP);

INSERT INTO order_items (order_id, product_id, product_title_snapshot, product_type_snapshot, unit_price_inr, final_price_inr) VALUES
(1, 1, 'Ultimate Java Developer Resume Template', 'RESUME_TEMPLATE', 299.00, 149.00),
(1, 4, 'Spring Boot Project Guide', 'PDF_EBOOK', 399.00, 199.00);

INSERT INTO payments (order_id, provider, razorpay_order_id, razorpay_payment_id, razorpay_signature, amount_inr, currency, payment_method, status, signature_verified, verified_at) VALUES
(1, 'RAZORPAY', 'order_DemoRzp998811', 'pay_DemoRzp776655', 'e5b8c2a19d0f4c7e8b1234567890abcdef1234567890abcdef1234567890abcd', 348.00, 'INR', 'UPI', 'VERIFIED', TRUE, CURRENT_TIMESTAMP);

INSERT INTO product_access (user_id, product_id, order_id, access_status) VALUES
(2, 1, 1, 'ACTIVE'),
(2, 4, 1, 'ACTIVE');
