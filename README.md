# FoodWise

Aplikasi berbasis Flutter untuk membantu pengguna memantau, mengurangi, dan mengelola sampah makanan (food waste). FoodWise menggunakan Firebase untuk penyimpanan data dan Google Gemini AI untuk mendeteksi makanan.

## Fitur Utama

- **Pemindaian Makanan**: Scan makanan menggunakan kamera dan AI Google Gemini
- **Riwayat Pemindaian**: Melihat dan mengelola riwayat makanan yang dipindai
- **Kalender**: Melihat aktivitas food waste berdasarkan tanggal
- **Edukasi**: Materi edukasi tentang pengelolaan sampah makanan
- **Gamifikasi**: Leaderboard dan quest untuk memotivasi pengguna

## Teknologi yang Digunakan

- **Flutter**: Framework untuk pengembangan UI
- **Firebase**: Autentikasi, Firestore, Storage
- **Provider**: State management
- **Google Gemini API**: AI untuk pemindaian dan analisis makanan
- **FlChart**: Visualisasi data food waste
- **Table Calendar**: Integrasi kalender

## Prasyarat

- Flutter SDK (versi 3.0.0 atau lebih baru)
- Akun Firebase
- Akun Google Gemini API

## Instalasi

1. Clone repository ini
```bash
git clone https://github.com/shluf/foodwise
cd foodwise
```

2. Instal dependensi
```bash
flutter pub get
```

3. Konfigurasi Firebase dan Gemini API

   - Buat proyek di Firebase Console
   - Tambahkan aplikasi Android dan iOS ke proyek Firebase Anda
   - Unduh file konfigurasi:
     - `google-services.json` (Android) - letakkan di `/android/app/`
     - `GoogleService-Info.plist` (iOS) - letakkan di `/ios/Runner/`

   - Dapatkan API key dari Google AI Studio
   - Salin `env.example` dan ubah namanya menjadi `.env` 
   - Ganti dengan API key Anda

4. Jalankan aplikasi
```bash
flutter run
```

## Struktur Project

```
lib/
  - main.dart               # Entry point aplikasi
  - config/                 # Konfigurasi
    - firebase_options.dart # Opsi Firebase
  - models/                 # Model data
    - user_model.dart
    - food_scan_model.dart
    - quest_model.dart
  - services/               # Layanan 
    - auth_service.dart     # Autentikasi
    - firestore_service.dart # Database
    - ai_service.dart       # Integrasi AI
  - providers/              # State management
    - auth_provider.dart
    - food_scan_provider.dart
    - gamification_provider.dart
  - screens/                # UI screens
    - auth/
    - home/
    - scan/
    - history/
    - educational/
    - calendar/
    - progress/
    - settings/
    - gamification/
  - widgets/                # UI Components
```

## Lisensi

[MIT License](LICENSE)

