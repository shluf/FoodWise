# FoodWise

A Flutter-based application to help users monitor, reduce, and manage food waste. FoodWise uses Firebase for data storage and Google Gemini AI for food detection.

## Main Features

- **Food Scanning**: Scan food using camera and Google Gemini AI
- **Scan History**: View and manage history of scanned food
- **Calendar**: View food waste activities by date
- **Education**: Educational materials about food waste management
- **Gamification**: Leaderboard and quests to motivate users

## Technologies Used

- **Flutter**: Framework for UI development
- **Firebase**: Authentication, Firestore, Storage
- **Google Gemini API**: AI for food scanning and analysis

## Prerequisites

- Flutter SDK (version 3.0.0 or newer)
- Firebase Account
- Google Gemini API Account

## Installation

1. Clone this repository
```bash
git clone https://github.com/shluf/FoodWise
cd FoodWise
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase and Gemini API

   - Create a project in Firebase Console
   - Add Android and iOS apps to your Firebase project
   - Download configuration files:
     - `google-services.json` (Android) - place in `/android/app/`
     - `GoogleService-Info.plist` (iOS) - place in `/ios/Runner/`

   - Get API key from Google AI Studio
   - Copy `env.example` and rename it to `.env` 
   - Replace with your API key

4. Run the application
```bash
flutter run
```

## Project Structure

```
lib/
  - main.dart               # Application entry point
  - config/                 # Configuration
    - firebase_options.dart # Firebase options
  - models/                 # Data models
    - user_model.dart
    - food_scan_model.dart
    - quest_model.dart
  - services/               # Services 
    - auth_service.dart     # Authentication
    - firestore_service.dart # Database
    - ai_service.dart       # AI integration
  - providers/              # State management
    - auth_provider.dart
    - food_scan_provider.dart
    - gamification_provider.dart
  - screens/                # UI screens
    - auth/
    - home/
    - layout/
    - onboarding/
    - scan/
    - history/
    - calendar/
    - progress/
    - settings/
    - gamification/
  - widgets/                # UI Components
  - utils/                  # Utility functions
```

## License

[MIT License](LICENSE)

