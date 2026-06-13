# SymSync

**Real-time bilateral muscle symmetry monitoring for athletes, rehabilitation, and clinical use.**

SymSync connects to a biosignalsplux sEMG hub over Bluetooth, streams two synchronized EMG channels, computes a real-time symmetry index (0–100 scale), and surfaces it through a radial gauge, anatomical heatmap, session history, and trend analysis.

---

## Features

- **Live Dashboard** — Time-of-day greeting, symmetry index radial gauge, quick-start session controls, channel status bars, and recent session history with performance tags
- **Live Session** — Tabbed interface (Anatomical / Balance) with EMG heatmap overlay, tilt-meter balance gauge, channel-level metrics, and a research-grade signal monitor
- **Activation Summary** — Imbalance heatmap with period filtering (Today / 7 Days / 30 Days), pattern analysis, average deviation, primary imbalance, and trend computation
- **Profile** — User card with initials, session/tracking stats, dark theme toggle, and data management
- **Onboarding** — 6-slide walkthrough covering EMG basics, user type selection, and cable assignment
- **Calibration Screen** — Two-phase device calibration with noise-floor monitoring, signal quality badges, and sparkline previews
- **Dark & Light Themes** — Full design system with theme-aware context extension
- **Landing Page** — Self-contained `index3.html` with phone mockups, feature showcase, and inline heatmap visualization

---

## Technology

| Layer | Choice |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State management | flutter_bloc (Cubit) |
| Charts | fl_chart |
| Persistence | shared_preferences (JSON) |
| Fonts | Google Fonts (Inter, JetBrains Mono) |
| Hardware | biosignalsplux sEMG Hub via PLUX BLE SDK |
| Onboarding | smooth_page_indicator |
| Permissions | permission_handler |
| Launcher icons | flutter_launcher_icons |

---

## Hardware

**Primary device:** biosignalsplux sEMG Hub
- 2 synchronized channels at 1000 Hz
- 16-bit ADC (0–65535 range, 32768 midpoint)
- Bluetooth BLE connection

**Android:** Native BLE via `pluxapi-0.2.0.jar` through Flutter MethodChannel  
**iOS / Simulator:** Falls back to simulated EMG (sine-wave + noise at 50 Hz with configurable asymmetry)

> The device MAC address is hardcoded in `lib/presentation/pages/home_shell_page.dart`. Update it to match your device.

---

## Architecture

```
lib/
├── main.dart                     # Entry point
├── plux_service.dart             # MethodChannel bridge to native BLE SDK
├── app/
│   └── sym_sync_app.dart         # Root widget, providers, theme, routing
├── config/
│   └── app_config.dart           # Feature flags (showResearcherTools)
├── data/
│   ├── emg/                      # Hardware abstraction + implementations
│   └── history/                  # Session persistence (JSON via SharedPreferences)
├── domain/
│   ├── models/                   # EmgFrame, SessionSummary, SessionTab
│   └── services/                 # SignalProcessor, SignalFilterState, SessionAggregator
├── presentation/
│   ├── bloc/
│   │   └── session_bloc.dart     # Single Cubit managing all app state
│   └── pages/                    # Onboarding, Dashboard, Session, Summary, Profile, etc.
├── screens/
│   └── calibration_screen.dart   # Device setup + signal quality check
├── theme/
│   ├── app_theme.dart            # Full design system + ThemeContext extension
│   └── theme_provider.dart       # ThemeMode persistence
├── utils/
│   └── heatmap_utils.dart        # Activation colour mapping
└── widgets/                      # Reusable components (cards, charts, badges, nav)
```

---

## Design System

### Colours

| Token | Dark | Light |
|---|---|---|
| Background primary | `#171916` | `#FDF9EC` |
| Card | `#22241F` | `#FFFFFF` |
| Elevated | `#2C2E2A` | `#F8F3E6` |
| Text primary | `#FDF9EC` | `#171916` |
| Divider | `#3A3D36` | `#E9E2D0` |

**Accents:** Teal `#5C8F88`, Blue `#2F80ED`, Amber `#D99058`, Red `#BA1A1A`, Green `#2E6C00`, Lime `#ADF67F`

Theme-aware colours via `context.bgPrimary`, `context.txtPrimary`, etc. — never hardcode dark values in widgets.

### Typography
- **Inter** for all UI text
- **JetBrains Mono** for numeric/monospace values
- Weights: 400–900

### Spacing & Radii
- Spacing: 4 / 8 / 16 / 24 / 32 / 48 px
- Radii: 8 / 20 / 28 / 32 px (cards use 32 px)

---

## Getting Started

```bash
# Clone
git clone https://github.com/UzairZQ/SymSync.git
cd SymSync

# Install dependencies
flutter pub get

# Generate launcher icons
dart run flutter_launcher_icons

# Run (Android — BLE supported)
flutter run -d android

# Run (iOS — simulated hardware)
flutter run -d ios
```

## Build

```bash
# Android APK
flutter build apk

# iOS
flutter build ios
```

---

## Landing Page

`index3.html` — self-contained landing page with dark theme matching the app. Open directly in a browser:

```bash
open index3.html
```

Features: sticky nav, phone mockups, feature pillars, heatmap visualization (inline JS), use cases, science section, and CTA.

---

## Known Issues

- 5 pre-existing `withOpacity` deprecation warnings in `status_badge.dart` and `symmetry_arc.dart` (use `withValues(alpha:)` instead)
- Onboarding always shows (`_onboardingComplete` hardcoded to `false` in `sym_sync_app.dart`)
- No database migration — uses JSON via SharedPreferences (sufficient for offline single-user <10k sessions)
- No automated tests — `test/` directory is empty

---

## License

Private package. Update `publish_to` in `pubspec.yaml` to publish.
