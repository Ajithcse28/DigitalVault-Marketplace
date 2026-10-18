# DigitalVault — Full-Stack Digital Products Sales Platform

A complete, responsive digital products marketplace built with **React + Vite + TypeScript + Tailwind CSS** on the frontend and **Java 21 + Spring Boot 3 + Spring Security (JWT) + MySQL 8 / PostgreSQL** on the backend.

## 1. Architecture Highlights

- **Configurable Branding & Localization**: Rebrand `DigitalVault` dynamically from the Admin Settings or `.env` (`APP_BRAND_NAME`), with built-in **English (`en`) and Tamil (`ta` - தமிழ்)** UI localization.
- **9 Specialized Digital Categories**: PDF & eBooks, Google Drive Resources, Video Courses, Resume Templates, Resume Bundles, Study Materials, Interview Preparation, Software & Digital Assets, and Other Digital Products.
- **Strict Asset Protection**:
  - Private files (`PDF`, `DOCX`, `ZIP`) live outside the web root (`PRIVATE_VAULT_DIR`) and are delivered exclusively via **15-minute HMAC-SHA256 signed URLs** after ownership verification.
  - **Google Drive Resources**: Uses Google Drive API v3 (`permissions.create` with `role: reader`) to authorize the buyer's verified email address only after payment verification, plus an authenticated vault download fallback (explaining why public link-sharing is insecure and avoided).
  - **Authorized Video Streaming**: Plays preview trailers publicly while locking full HD course modules behind authenticated customer playback tokens in **My Video Library** (without making false DRM claims).
- **Server-Side Razorpay Verification**:
  1. Client initiates checkout -> Backend creates a `PENDING` order (`POST /api/orders`) and Razorpay `order_id`.
  2. Razorpay Checkout collects payment in Test Mode (`rzp_test_*`).
  3. Backend verifies `HMAC_SHA256(razorpay_order_id + "|" + razorpay_payment_id, RAZORPAY_KEY_SECRET)` in `RazorpayPaymentService.java` using constant-time digest comparison before marking the order `PAID` and granting `product_access`.

## 2. Prerequisites

- **Java**: JDK 21+
- **Maven**: 3.9+
- **Node.js**: v20+ & npm 10+
- **Database**: MySQL 8.0+ (or PostgreSQL 16+)

## 3. Database Setup (MySQL 8)

```bash
mysql -u root -p < database/digitalvault.sql
```

This creates the `digitalvault` schema with all 14 tables (`users`, `roles`, `user_roles`, `categories`, `products`, `digital_assets`, `orders`, `order_items`, `payments`, `product_access`, `downloads`, `wishlists`, `coupons`, `reviews`, `support_tickets`) and seeds the 8 demo products, coupons (`VAULT20`, `CAREER50`, `LAUNCH100`), and demo accounts.

## 4. Running the Backend (Spring Boot 3)

```bash
cd backend
cp ../.env.example .env
# Export your DB_USER, DB_PASSWORD, JWT_SECRET, and RAZORPAY_KEY_SECRET
mvn clean test
mvn spring-boot:run
```

- **API Base URL**: `http://localhost:8080/api`
- **Swagger / OpenAPI UI**: `http://localhost:8080/swagger-ui.html`

## 5. Running the Frontend (React + Vite)

```bash
cd frontend
npm install
npm run dev
```

- **Local Dev Server**: `http://localhost:5173`

## 6. External Credentials & Integrations Disclosure

- **Razorpay Test Mode**: Requires your `RAZORPAY_KEY_ID` (`rzp_test_...`) and server-only `RAZORPAY_KEY_SECRET` from the Razorpay Dashboard. In the interactive preview, checkout runs in a clearly labeled **Simulated Razorpay Test Mode Sandbox** that demonstrates the exact payload and HMAC-SHA256 verification flow without claiming to process real banking transactions.
- **Google Drive API v3**: Requires a Google Cloud Service Account JSON key (`GOOGLE_APPLICATION_CREDENTIALS`) with Drive API enabled and shared on the target vault folder.
- **SMTP Email**: Requires `SMTP_HOST`, `SMTP_USERNAME`, and `SMTP_PASSWORD` to dispatch live transactional emails.
