# SafeSkies Flutter App

Real-time weather alerts and crowd-sourced hazard reporting for rural East Africa.

## Project Structure

```
safeskies-flutter/
├── lib/
│   ├── main.dart                          # App entry point, theme, routing
│   ├── screens/
│   │   ├── home_screen.dart              # Map + alert banner + bottom nav
│   │   ├── forecast_screen.dart          # 24h forecast list + chart
│   │   ├── report_screen.dart            # Crowd hazard report form
│   │   └── settings_screen.dart          # Language, phone, notifications
│   ├── widgets/
│   │   ├── risk_banner.dart              # Big coloured alert banner
│   │   ├── forecast_chart.dart           # fl_chart 24h sparkline
│   │   ├── alert_card.dart               # Individual alert list item
│   │   └── offline_banner.dart           # 'Offline — cached data' notice
│   ├── models/
│   │   ├── forecast.dart                 # Forecast data models
│   │   ├── alert.dart                    # Alert data models
│   │   └── report.dart                   # Crowd report models
│   ├── services/
│   │   ├── api_service.dart              # All HTTP calls — toggleable mock
│   │   ├── cache_service.dart            # SQLite read/write
│   │   ├── location_service.dart         # GPS & permission handling
│   │   └── notification_service.dart     # FCM setup
│   └── providers/
│       └── weather_provider.dart         # App-wide weather state
└── pubspec.yaml
```

## Setup Instructions

### 1. Prerequisites
- Flutter 3.0+ installed
- Dart SDK
- Android Studio / Xcode for emulator
- Firebase account for FCM

### 2. Install Dependencies
```bash
cd safeskies-flutter
flutter pub get
```

### 3. Firebase Setup
1. Create a new Firebase project at https://console.firebase.google.com
2. Add Android app (SHA-1 fingerprint required)
3. Add iOS app if developing for iOS
4. Download `google-services.json` (Android) and place in `android/app/`
5. Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`

### 4. Run the App
```bash
flutter run
```

## Key Features

### Home Screen
- **Full-screen OpenStreetMap** with flutter_map (no API key required)
- **User location** shown as pulsing blue dot
- **Risk zone overlay** — colour-coded circles based on alert severity
- **Active alert markers** — red pins on map
- **Risk banner** at top with current alert level and message
- **Alert list slide-up** showing all active alerts in the area

### Forecast Screen
- **24-hour forecast list** with temperature, precipitation, risk badge
- **fl_chart precipitation trend** visualized over 24 hours
- **Pull-to-refresh** to fetch latest data
- **Offline cache display** with timestamp if no internet

### Report Screen
- **Hazard type selector** (Flood / Wind Damage / Road Blocked / Other)
- **Severity selector** (Low / Medium / High)
- **Optional description** field
- **GPS auto-fill** of location with drag-to-adjust map pin
- **Submit button** calls POST /v1/reports

### Settings Screen
- **Phone number** entry for SMS alert registration
- **Language selector** (English / Swahili)
- **Notification toggle** for push alerts
- **On save**: calls POST /v1/alerts/subscribe with FCM token + phone + location

## Offline Mode

The app caches all data locally using SQLite:
- Data is cached on every successful API response
- On app start, if offline, data loads from cache
- **Offline banner** displayed when using cached data
- **Cache expiry warning** if data older than 2 hours
- Works in airplane mode — critical for rural areas

## Mock API Service

`api_service.dart` has a `USE_MOCK` flag:
- When `USE_MOCK = true`: all methods return hardcoded test data
- Includes HIGH, MEDIUM, LOW risk alerts in mock data
- Set to `false` when backend is live to use real API

## Development

### Toggle Mock Data
Edit `lib/services/api_service.dart`:
```dart
static const bool USE_MOCK = true;  // Toggle this
```

### Backend API Contract
All API calls go through `ApiService` and must match:
- `GET /v1/forecast?lat=X&lon=Y` → ForecastResponse
- `GET /v1/alerts?lat=X&lon=Y` → AlertsResponse
- `POST /v1/reports` → ReportResponse
- `POST /v1/alerts/subscribe` → subscription confirmation

### State Management
- **Provider** package for app-wide weather state
- `WeatherProvider` handles forecast, alerts, location, connectivity
- Rebuilds UI automatically on state changes

### Connectivity Monitoring
- `connectivity_plus` detects online/offline state
- On disconnect: app loads from cache
- On reconnect: app refreshes data automatically
- **Offline banner** shows cache age

## Testing on Device

### Android
```bash
flutter run -v
```

### iOS
```bash
cd ios
pod install
cd ..
flutter run
```

### Test Offline Mode
1. Run the app normally to cache data
2. Enable airplane mode
3. App should display cached data with offline banner
4. Report form should still work (offline-first)

## Debugging

Check logs with:
```bash
flutter logs
```

Enable verbose logging:
```bash
flutter run -v
```

## Build for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Notes for Hackathon

1. **Mock data is live** — app works fully without backend on Day 1
2. **Switch to real API** at Hour 12 by setting `USE_MOCK = false`
3. **Offline mode MUST work** during demo — test airplane mode
4. **Home screen is the showcase** — ensure it looks polished
5. **Notifications** require Firebase setup — do this early
6. **GPS permissions** must be handled gracefully for iOS/Android

## Troubleshooting

### "android/app/google-services.json not found"
- Download it from Firebase Console
- Place in `android/app/google-services.json`

### "iOS pods not found"
```bash
cd ios
rm Podfile.lock
pod install
cd ..
```

### "Location permission denied"
- Check Android: `android/app/src/main/AndroidManifest.xml` has GPS permissions
- Check iOS: `ios/Runner/Info.plist` has location usage strings

### "Offline mode not working"
- Ensure SQLite database initialized in `CacheService.init()`
- Check cache keys: `last_forecast`, `active_alerts`, `last_updated_timestamp`

## API Key Required?
**No!** flutter_map uses OpenStreetMap tiles which need no API key.
