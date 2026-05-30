# SymSync

SymSync is a Flutter application for live symmetry monitoring, balance feedback, and session analytics. It connects to a compatible EMG/Bluetooth device on Android and provides real-time symmetry scoring, session controls, activation summaries, and visual balance feedback.

## Features

- Live dashboard with symmetry index, session count, and balance overview
- Bluetooth EMG device support on Android via a PLUX integration channel
- Live session monitoring with anatomical and balance views
- Activation summary page with historical trend metrics and period filters
- Simple profile and session navigation using a bottom navigation bar
- Responsive UI with custom theme, animated cards, and data visualizations

## Technology

- Flutter
- flutter_bloc
- fl_chart
- permission_handler
- shared_preferences
- google_fonts
- shimmer

## Requirements

- Flutter SDK 3.11.4 or newer
- Android device/emulator for Bluetooth EMG device features
- macOS / iOS / desktop platforms are supported, but internal hardware falls back to simulated EMG data when Android-only Bluetooth hardware is unavailable

## Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/UzairZQ/SymSync.git
   cd SymSync
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:

   ```bash
   flutter run
   ```

   For Android specifically:

   ```bash
   flutter run -d android
   ```

## Build

- Build Android APK:

  ```bash
  flutter build apk
  ```

- Build iOS app:

  ```bash
  flutter build ios
  ```

## Project Structure

- `lib/main.dart` — application entrypoint
- `lib/app/sym_sync_app.dart` — root app setup, dependency providers, and session bloc wiring
- `lib/data/emg/` — hardware abstraction and EMG data sources
- `lib/domain/models/` — data models for session and EMG frames
- `lib/presentation/` — UI pages, navigation, and presentation widgets
- `lib/theme/` — app theme definitions and styling
- `lib/widgets/` — reusable UI components
- `lib/plux_service.dart` — native Bluetooth EMG device plumbing for Android

## Notes

- Android permissions for Bluetooth and location are requested before device connection.
- The app uses simulated data outside Android to keep desktop and iOS builds runnable during development.
- If you integrate a real PLUX device, update the MAC address in `lib/presentation/pages/home_shell_page.dart`.

## License

This repository is configured as a private Flutter package. Update the `publish_to` value in `pubspec.yaml` if you plan to publish.
