# PeduliYuk - Platform Donasi Digital

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-005C84?style=for-the-badge&logo=mysql&logoColor=white)

**PeduliYuk** adalah aplikasi mobile berbasis Flutter yang memfasilitasi donasi barang bekas antara masyarakat dan organisasi. Aplikasi ini dirancang untuk mempermudah proses donasi, distribusi, dan tracking bantuan sosial dengan sistem yang terintegrasi.

## 📋 Daftar Isi

- [Fitur Utama](#-fitur-utama)
- [Arsitektur Aplikasi](#-arsitektur-aplikasi)
- [Teknologi yang Digunakan](#-teknologi-yang-digunakan)
- [Struktur Project](#-struktur-project)
- [Instalasi](#-instalasi)
- [Konfigurasi](#-konfigurasi)
- [Cara Menjalankan](#-cara-menjalankan)
- [API Documentation](#-api-documentation)
- [Screenshots](#-screenshots)
- [Contributing](#-contributing)
- [Tim Pengembang](#-tim-pengembang)

## 🌟 Fitur Utama

### 👥 Multi-Role System
- **Masyarakat (Donatur)**: Dapat melakukan donasi barang
- **Organisasi (Penerima)**: Dapat menerima dan mendistribusikan donasi
- **Admin**: Mengelola dan memverifikasi donasi

### 📦 Manajemen Donasi
- **Donasi Pakaian**: Lengkap dengan foto, ukuran, dan kondisi
- **Donasi Barang**: Untuk peralatan, buku, dan barang lainnya
- **Upload Foto**: Dokumentasi item dengan kamera atau galeri
- **Real-time Tracking**: Status donasi dari awal hingga selesai

### 🔄 Workflow Donasi
1. **Submit Donasi** - Masyarakat mengajukan donasi
2. **Admin Approval** - Verifikasi oleh admin
3. **Find Receiver** - Pencarian penerima yang sesuai
4. **Delivery Coordination** - Koordinasi pengambilan
5. **Confirmation** - Konfirmasi penerimaan dengan foto bukti
6. **Feedback System** - Rating dan ulasan

### 📱 Fitur Tambahan
- **Suara Kebutuhan**: Organisasi dapat menyampaikan kebutuhan spesifik
- **Article Management**: Admin dapat mengelola artikel informatif
- **Notification System**: Notifikasi real-time untuk semua aktivitas
- **Profile Management**: Manajemen profil lengkap untuk semua role
- **WhatsApp Integration**: Koordinasi langsung melalui WhatsApp

## 🏗️ Arsitektur Aplikasi

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   REST API      │    │    Database     │
│   (Flutter)     │◄──►│     (PHP)       │◄──►│    (MySQL)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                        │                        │
        │                        │                        │
   ┌─────────┐              ┌─────────┐              ┌─────────┐
   │UI Layer │              │Business │              │ Data    │
   │Screens  │              │Logic    │              │Storage  │
   │Widgets  │              │API Calls│              │Files    │
   └─────────┘              └─────────┘              └─────────┘
```

## 🛠️ Teknologi yang Digunakan

### Frontend (Mobile)
- **Flutter 3.6.0** - Framework utama
- **Dart** - Bahasa pemrograman
- **HTTP Package** - API calls
- **Image Picker** - Upload foto
- **URL Launcher** - WhatsApp integration
- **Flutter Rating Bar** - Sistem rating
- **Shared Preferences** - Local storage
- **Shimmer** - Loading animations
- **Google Fonts** - Typography

### Backend
- **PHP** - Server-side logic
- **MySQL** - Database management
- **RESTful API** - Communication protocol

### Key Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.6
  image_picker: ^0.8.9
  url_launcher: ^6.2.4
  intl: ^0.19.0
  flutter_rating_bar: 4.0.1
  shared_preferences: ^2.2.0
  dotted_border: ^2.1.0
  shimmer: ^3.0.0
  google_fonts: ^4.0.4
```

## 📁 Struktur Project

### Mobile App (`peduliyuk_tubes/`)
```
lib/
├── main.dart                 # Entry point aplikasi
├── pages/                   # Halaman umum (login, register)
│   ├── login.dart
│   └── register.dart
├── masyarakat/              # Fitur untuk donatur
│   ├── masyarakat_main_screen.dart
│   ├── donation_form_screen.dart
│   ├── donation_detail_screen.dart
│   └── MasyarakatMyDonationsScreen.dart
├── organization/            # Fitur untuk organisasi
│   ├── organization_main_screen.dart
│   ├── penerimaan_screen.dart
│   ├── donation_detail_accepted_screen.dart
│   └── suara_kebutuhan_list_screen.dart
├── admin/                   # Fitur untuk admin
│   ├── admin_home.dart
│   ├── add_article.dart
│   └── admin_donation_detail_screen.dart
├── controller/              # Business logic
├── navigation/              # Navigation widgets
└── assets/                  # Images, icons, etc.
```

### Backend API (`peduliyuk_api/`)
```
peduliyuk_api/
├── db.php                   # Database connection
├── login.php               # Authentication
├── signup.php              # User registration
├── upload_donation.php     # Create donation
├── get_my_donations.php    # Get user donations
├── take_donations.php      # Accept donation
├── confirm_donation_received.php  # Confirm receipt
├── get_articles.php        # Article management
├── add_suara_kebutuhan.php # Voice of needs
└── uploads/                # File storage
    ├── user_photos/
    ├── received_photos/
    └── suara_kebutuhan/
```

## 🚀 Instalasi

### Prerequisites
- Flutter SDK 3.6.0+
- Android Studio / VS Code
- PHP 7.4+
- MySQL 5.7+
- Web server (Apache/Nginx)

### 1. Clone Repository
```bash
git clone [repository-url]
cd Tubes_Mobile/peduliyuk_tubes
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Setup Backend
1. Copy folder `peduliyuk_api` ke web server directory
2. Import database schema (jika ada file SQL)
3. Konfigurasi database di `db.php`

### 4. Update API Configuration
Edit file `lib/main.dart`:
```dart
final String apiBaseUrl = 'http://your-server-ip/peduliyuk_api';
```

## ⚙️ Konfigurasi

### Database Configuration (`peduliyuk_api/db.php`)
```php
<?php
$servername = "localhost";
$username = "your_db_username";
$password = "your_db_password";
$dbname = "peduliyuk_db";
?>
```

### Android Configuration
File `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## 🏃‍♂️ Cara Menjalankan

### Development Mode
```bash
# Jalankan aplikasi di emulator/device
flutter run

# Build APK untuk testing
flutter build apk --debug

# Build release APK
flutter build apk --release
```

### Production Deployment
1. **Setup server** dengan PHP dan MySQL
2. **Upload API files** ke web server
3. **Configure database** dan permissions
4. **Build & distribute** APK untuk user

## 📚 API Documentation

### Authentication Endpoints
- `POST /login.php` - User login
- `POST /signup.php` - User registration

### Donation Endpoints
- `POST /upload_donation.php` - Create new donation
- `POST /get_my_donations.php` - Get user donations
- `POST /take_donations.php` - Accept donation
- `POST /confirm_donation_received.php` - Confirm receipt

### Content Management
- `GET /get_articles.php` - Get articles
- `POST /add_article.php` - Create article
- `POST /add_suara_kebutuhan.php` - Add voice of needs

### Status Workflow
```
Waiting For Approval → Waiting For Receiver → Found Receiver 
→ On Delivery → Received → Waiting For Feedback → Success
```

## 📸 Screenshots

[Tambahkan screenshots aplikasi di sini]

## 🤝 Contributing

1. Fork repository ini
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## 👨‍💻 Tim Pengembang

**Tim Naspuan - Tugas Besar Mobile Programming**

| Nama | Role | GitHub |
|------|------|---------|
| **YanStephen29** | Project Manager & Backend Developer | [@YanStephen29](https://github.com/YanStephen29) |
| **FerdinandTJ** | Backend Developer | [@FerdinandTJ](https://github.com/FerdinandTJ) |
| **nurhumam** | Frontend Developer | [@nurhumam](https://github.com/nurhumam) |
| **Haekal1243** | Quality Assurance & Tester | [@Haekal1243](https://github.com/Haekal1243) |
| **ArielYosua** | Frontend Developer | [@ArielYosua](https://github.com/ArielYosua) |

### 🎯 Kontribusi Tim
- **Project Manager & Backend**: Mengelola proyek, mengembangkan API PHP, dan database MySQL
- **Frontend Developers**: Mengembangkan UI/UX aplikasi Flutter dan integrasi dengan backend
- **Quality Assurance**: Testing aplikasi, bug reporting, dan memastikan kualitas aplikasi
- **Observer**: Kritikus

Proyek ini dikembangkan sebagai tugas besar mata kuliah Mobile Programming dengan fokus pada pengembangan aplikasi donasi digital yang dapat membantu masyarakat dalam berbagi dan menerima bantuan.

## 📄 License

Proyek ini dikembangkan untuk keperluan akademik. Silakan hubungi tim pengembang untuk informasi penggunaan lebih lanjut.

---

**Made with ❤️ by Tim Naspuan**

> Aplikasi PeduliYuk - Menghubungkan hati yang peduli untuk berbagi kebaikan
