# AgriNexa Flutter App

The world's best agricultural marketplace — built in Flutter.

## 🎨 Design System
- **Primary Color:** `#2E7D32` (Deep Green)
- **Accent:** `#4CAF50` (Medium Green)
- **Background:** `#F5F5F5`
- **Font:** Poppins (via Google Fonts)

## 📱 Screens Included

| Screen | File |
|--------|------|
| Splash Screen | `lib/screens/splash_screen.dart` |
| Login | `lib/screens/login_screen.dart` |
| Register | `lib/screens/register_screen.dart` |
| Home / Marketplace | `lib/screens/marketplace_screen.dart` |
| Product Detail | `lib/screens/product_detail_screen.dart` |
| Order Summary | `lib/screens/order_summary_screen.dart` |
| Order Confirmed | `lib/screens/order_confirmed_screen.dart` |
| Sell Product | `lib/screens/sell_product_screen.dart` |
| My Listing | `lib/screens/my_listing_screen.dart` |
| Profile | `lib/screens/profile_screen.dart` |
| Authenticate (ID) | `lib/screens/authenticate_screen.dart` |
| Chat | `lib/screens/chat_screen.dart` |

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio or VS Code with Flutter extension

### 2. Install Dependencies
```bash
cd agri_nexa
flutter pub get
```

### 3. Add Poppins Font (Recommended)
Download Poppins from [Google Fonts](https://fonts.google.com/specimen/Poppins), place in `assets/fonts/`, and uncomment the fonts section in `pubspec.yaml`.

Or use the `google_fonts` package (already added) by updating `app_theme.dart`:
```dart
import 'package:google_fonts/google_fonts.dart';

// In AppTheme.get theme:
textTheme: GoogleFonts.poppinsTextTheme(),
```

### 4. Run the App
```bash
flutter run
```

## 🗂 Project Structure
```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart      # Colors + ThemeData
└── screens/
    ├── splash_screen.dart
    ├── login_screen.dart
    ├── register_screen.dart
    ├── home_screen.dart         # Bottom nav wrapper
    ├── marketplace_screen.dart
    ├── product_detail_screen.dart
    ├── order_summary_screen.dart
    ├── order_confirmed_screen.dart
    ├── sell_product_screen.dart
    ├── my_listing_screen.dart
    ├── profile_screen.dart
    ├── authenticate_screen.dart
    └── chat_screen.dart
```

## 🔧 Next Steps to Make Production-Ready
1. **Backend Integration** — Connect to REST API or Firebase for real data
2. **Image Picker** — Wire up `image_picker` for product & ID photo uploads
3. **State Management** — Add Provider, Riverpod, or Bloc for app state
4. **Authentication** — Integrate Firebase Auth or your custom auth API
5. **Payments** — Integrate Mobile Money (MTN/Orange) payment gateway
6. **Push Notifications** — Add Firebase Cloud Messaging
7. **Localization** — Add French (Cameroon's official language)
