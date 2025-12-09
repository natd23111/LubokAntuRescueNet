# 📱 Lubok Antu RescueNet (LAR)

Lubok Antu RescueNet (LAR) is a mobile-based emergency and community aid reporting system designed for residents of Lubok Antu and managed by Pusat Khidmat Lubok Antu.

This repository contains two separate projects inside one monorepo:
```bash
LubokAntuRescueNet/
├── frontend/   → Flutter mobile application
└── backend/    → Laravel REST API
```

## 🚀 Project Overview
Mobile App (Flutter)
Resident Features

Submit Emergency Reports

Submit Aid Requests

View “My Reports”

Track Report Status

View Bantuan/Aid Programs

AI Chatbot (Gemini API)

Edit Profile

Admin Features

View All Reports

Update Status (Submitted → In Progress → Completed)

Add Admin Remarks

Manage Bantuan Programs

Basic Analytics Overview

Manage User Accounts

## 🖥️ Backend API (Laravel)

REST API for all app functions

Authentication using Laravel Sanctum

CRUD for emergency reports and aid requests

Google Maps coordinate support

Telegram Bot notifications

JSON-based API responses

## 📁 Repository Structure
```bash
LubokAntuRescueNet/
│
├── frontend/              # Flutter Mobile App
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── pubspec.yaml
│   └── ...
│
├── backend/               # Laravel REST API
│   ├── app/
│   ├── routes/
│   ├── database/
│   ├── config/
│   ├── composer.json
│   └── ...
│
└── README.md
```

## 🛠️ Setup Instructions
📱 Flutter Setup
1. Navigate to the frontend folder:
```bash
cd frontend
```

2. Install packages:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 🖥️ Laravel Backend Setup
1. Navigate to backend folder:
```bash
cd backend
```

2. Install dependencies:
```bash
composer install
```

3. Copy .env:
```bash
cp .env.example .env
```

4. Generate app key:
```bash
php artisan key:generate
```

5. Configure database:
```bash
DB_DATABASE=lar_rescuenet
DB_USERNAME=root
DB_PASSWORD=
```

6. Run migrations:
```bash
php artisan migrate
```

7. Start the server:
```bash
php artisan serve
```

## API runs at:
http://127.0.0.1:8000

🔌 API Integration (Flutter ↔ Laravel)
Base URL for Android Emulator:
http://10.0.2.2:8000/api

Base URL for Physical Device:
http://YOUR_LOCAL_IP:8000/api

## 🔥 Key API Endpoints
Authentication
POST /api/auth/register
POST /api/auth/login

Reports (Resident)
POST /api/reports/emergency
POST /api/reports/aid
GET  /api/reports/my

Admin
GET  /api/admin/reports
POST /api/admin/reports/update

## 📌 Tools Used
Frontend

Flutter

Dart

Provider / Riverpod

Google Maps API

Gemini API

Backend

Laravel

PHP

MySQL

Laravel Breeze + Sanctum

Telegram Bot API

Google Maps API