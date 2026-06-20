# SymSync — Complete Project Analysis

> **Purpose:** Comprehensive technical reference for the SymSync Flutter application. Designed to be given to an AI (Claude, GPT, etc.) to provide full project context for code reviews, improvements, and bug fixes.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Map](#2-architecture-map)
3. [File-by-File Breakdown](#3-file-by-file-breakdown)
4. [Data Flow](#4-data-flow)
5. [State Management](#5-state-management)
6. [Navigation & Routing](#6-navigation--routing)
7. [Hardware Layer](#7-hardware-layer)
8. [Signal Processing Pipeline](#8-signal-processing-pipeline)
9. [Design System](#9-design-system)
10. [Known Issues & Technical Debt](#10-known-issues--technical-debt)
11. [Testing](#11-testing)
12. [Landing Page](#12-landing-page)

---

## 1. Project Overview

**SymSync** is a Flutter mobile app (iOS + Android) that connects to a **biosignalsplux sEMG hub** over Bluetooth, streams two synchronized EMG channels (left + right trapezius), computes a real-time **symmetry index**, and surfaces it through a dashboard, anatomical heatmap, session history, and trend analysis. Target users: athletes monitoring bilateral balance, rehab patients, and clinicians.

### Key Stats
- **~8,600 lines of Dart** across 44 source files
- **Single Cubit** state management (`SessionBloc`)
- **Single abstract hardware interface** with two implementations (real BLE + simulated)
- **~1,150 lines of Kotlin** native bridge (`PluxBridge.kt`)
- **1 test file** with 7 test cases

### Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart SDK ^3.11.4) |
| State management | flutter_bloc 8.x (Cubit) |
| Charts | fl_chart ^1.2.0 |
| Persistence | shared_preferences (JSON-encoded strings) |
| Fonts | Google Fonts (Inter, JetBrains Mono) |
| Hardware | biosignalsplux sEMG Hub via PLUX BLE SDK |
| Onboarding | smooth_page_indicator |
| Permissions | permission_handler |
| Equality | equatable |
| Native bridge | Kotlin MethodChannel + pluxapi-0.2.0.jar |

---

## 2. Architecture Map

```
lib/
├── main.dart                                    # Entry point (4 lines)
├── plux_service.dart                            # Dart-side MethodChannel + EventChannel bridge
│
├── app/
│   ├── sym_sync_app.dart                        # Root widget: providers, theme, onboarding gate
│   └── sym_sync_theme.dart                      # Deprecated theme wrapper (delegates to AppTheme)
│
├── config/
│   └── app_config.dart                          # Feature flags (showResearcherTools)
│
├── data/
│   ├── emg/
│   │   ├── emg_hardware.dart                    # Abstract EmgHardware interface
│   │   ├── plux_emg_hardware.dart               # Android BLE impl (delegates to PluxService)
│   │   └── simulated_emg_hardware.dart          # iOS/simulator fallback (sine wave + noise)
│   └── history/
│       └── session_history_store.dart           # JSON persistence via SharedPreferences
│
├── domain/
│   ├── models/
│   │   ├── emg_frame.dart                       # Raw EMG data frame (ch1, ch3, timestamp)
│   │   ├── session_summary.dart                 # Per-session summary (duration, avg activation, etc.)
│   │   └── session_tab.dart                     # Enum for bottom nav tabs
│   └── services/
│       ├── signal_processor.dart                # Activation extraction, symmetry index, filtering
│       └── session_aggregator.dart              # Multi-session heatmap grid aggregation
│
├── presentation/
│   ├── bloc/
│   │   └── session_bloc.dart                    # Single Cubit managing ALL app state (~748 lines)
│   ├── pages/
│   │   ├── onboarding_page.dart                 # 5-slide walkthrough (~965 lines)
│   │   ├── home_shell_page.dart                 # Bottom nav shell + IndexedStack
│   │   ├── dashboard_page.dart                  # Main dashboard (~641 lines)
│   │   ├── session_page.dart                    # Session screen (tabbed: Anatomical + Balance)
│   │   ├── activation_summary_page.dart         # Historical summary with heatmap
│   │   ├── profile_page.dart                    # User profile + stats
│   │   ├── anatomical_view_page.dart            # Heatmap + imbalance label
│   │   ├── balance_monitor_page.dart            # Balance tilt-meter + channel cards
│   │   └── signal_view_content.dart             # Researcher-only signal monitor
│   └── widgets/
│       ├── session_visuals.dart                 # EmgWaveformChart, LegPairSilhouette, TiltMeter, etc.
│       ├── memphis_widgets.dart                 # Animated background decorations
│       └── historical_heatmap.dart              # Wraps LegPairSilhouette with SessionHeatmapData
│
├── screens/
│   └── calibration_screen.dart                  # Device setup + signal quality check
│
├── theme/
│   ├── app_theme.dart                           # Full design system + ThemeContext extension
│   └── theme_provider.dart                      # ThemeMode persistence
│
├── utils/
│   └── heatmap_utils.dart                       # HeatmapGradient colour mapping
│
└── widgets/                                     # Shared reusable components
    ├── app_card.dart
    ├── channel_bar.dart
    ├── connection_badge.dart
    ├── emg_chart.dart                           # Real-time waveform chart (fl_chart)
    ├── gradient_button.dart
    ├── heatmap_silhouette_widget.dart            # Upper-body silhouette + glow
    ├── section_label.dart
    ├── session_confirmation_modal.dart
    ├── session_tab_bar.dart
    ├── status_badge.dart
    ├── sym_sync_route.dart
    ├── symmetry_arc.dart
    └── theme_toggle.dart
```

### Android Native (Kotlin)

```
android/app/src/main/kotlin/com/symsync/emgvalidator/
├── MainActivity.kt                              # Configures PluxBridge on FlutterEngine
└── PluxBridge.kt                                # MethodChannel handler + BLE lifecycle (~386 lines)
```

---

## 3. File-by-File Breakdown

### 3.1 Entry Point — `lib/main.dart`

Minimal entry. Calls `WidgetsFlutterBinding.ensureInitialized()` then runs `SymSyncApp`.

### 3.2 App Root — `lib/app/sym_sync_app.dart`

**Responsibilities:**
- Wraps the widget tree in `RepositoryProvider` (for `SessionHistoryStore` + `EmgHardware`) and `BlocProvider` (for `SessionBloc`)
- Creates the appropriate `EmgHardware` based on platform (Android → `PluxEmgHardware`, else → `SimulatedEmgHardware`)
- Provides `MaterialApp` with `lightTheme`/`darkTheme` from `AppTheme`, switches via `ThemeProvider.themeNotifier`
- **Onboarding gate:** `_onboardingComplete` is **hardcoded to `false`** (line 38), so onboarding always shows. The `SharedPreferences` check is bypassed.

**Key issue:** `_onboardingComplete = false` is set in `_init()` but never reads from prefs. The `setState` at line 37-40 is a no-op since the value never changes.

### 3.3 Config — `lib/config/app_config.dart`

Single constant `showResearcherTools = false`. When `true`, a third "Signal" tab appears in the session page showing raw EMG waveforms.

### 3.4 Domain Models

#### `lib/domain/models/emg_frame.dart`
- Data class with `timestamp` (int ms), `ch1` (int, channel 1), `ch3` (int, channel 3)
- `EmgFrame.fromMap()` factory for deserializing from the native bridge

#### `lib/domain/models/session_summary.dart`
- Full session record: `startedAt`, `endedAt`, `durationSeconds`, `peakRaw`, `averageActivation`, `averageSymmetryIndex`, `averageLeftActivation`, `averageRightActivation`, `note`, `channelMapping`
- `toJson()` / `fromJson()` for persistence
- Used by `SessionHistoryStore` for storage and `SessionBloc` for state

#### `lib/domain/models/session_tab.dart`
- Enum: `dashboard, session, summary, profile`
- Extension `SessionTabLabel` provides display strings

### 3.5 Signal Processing — `lib/domain/services/signal_processor.dart`

**Core math:**

```dart
// Symmetry Index: -100 to +100
// Negative = left dominant, Positive = right dominant, 0 = balanced
symmetryIndex = ((right - left) / (left + right)) * 100

// Activation from raw ADC value (0-65535, midpoint 32768)
activation = |raw - 32768| / 32768   // → 0.0–1.0
```

**Helper methods:**
- `tiltDegreesFromSymmetry()` — maps symmetry index to ±20° visual tilt
- `correctiveInstruction()` — returns coaching text based on symmetry value thresholds (<8 balanced, >0 right dominant, else left dominant)
- `trendLabel()` — returns "Balanced", "Slight drift", or "Strong asymmetry" based on absolute symmetry index

**`SignalFilterState`** — maintains state for a real-time signal filter chain:
- High-pass (≈20 Hz cutoff at 1000 Hz, alpha = 0.88)
- Low-pass (≈400 Hz cutoff at 1000 Hz, alpha = 0.7)
- RMS envelope calculation (100-sample window, normalised by /300)
- `reset()` clears all state

### 3.6 Session Aggregator — `lib/domain/services/session_aggregator.dart`

Processes session history into a 4×14 heatmap grid per leg:
- Takes up to 10 most recent sessions
- For each session, distributes activation across grid cells with vertical/horizontal weighting
- Averages across sessions
- Also computes average symmetry index
- Returns `SessionHeatmapData` containing `leftIntensities`, `rightIntensities`, `sessionCount`, `averageSymmetry`

### 3.7 Hardware Abstraction

#### `lib/data/emg/emg_hardware.dart` — Abstract interface
```dart
abstract class EmgHardware {
  Stream<EmgFrame> get frames;
  Future<void> connect(String macAddress);
  Future<void> startAcquisition({List<int> channels, int sampleRate});
  Future<void> stopAcquisition();
  Future<void> disconnect();
}
```

#### `lib/data/emg/plux_emg_hardware.dart` — Android BLE
Delegates everything to `PluxService` (MethodChannel). Channels `[1, 3]` at 1000 Hz.

#### `lib/data/emg/simulated_emg_hardware.dart` — Fallback
Generates synthetic EMG at 50 Hz (20ms intervals) using sine waves + noise bursts + configurable asymmetry. Channel 3 simulates a flatline period between 15–25 seconds for testing signal-loss detection.

#### `lib/plux_service.dart` — Channel Bridge
- MethodChannel `'com.symsync/plux'` for commands: `connect`, `startAcquisition`, `stopAcquisition`, `disconnect`
- EventChannel `'com.symsync/plux/stream'` for frame streaming
- Channel A → CH1, Channel B → CH3

### 3.8 Session History Store — `lib/data/history/session_history_store.dart`

- Serializes `List<SessionSummary>` as JSON strings stored in `SharedPreferences` under key `'sym_sync.session_history.v1'`
- `append()` inserts at index 0 and caps at 10 sessions
- Simple JSON approach (no database) — adequate for single-user offline use < 10k sessions

### 3.9 State Management — `lib/presentation/bloc/session_bloc.dart`

**The single largest and most critical file (~748 lines).** A `Cubit<SessionState>` managing all app state.

#### SessionState (~224 lines)
25 fields including:
- `status` (enum: disconnected, connecting, connected, signalLost, error)
- `selectedTab`, `busy`
- `latestRaw`, `samplesPerSecond`, `sessionSeconds`
- `symmetryIndex` (double?), `liveActivation`
- `rawPoints`, `rawPoints3` (buffers of 3000 samples each)
- `history` (list of past sessions)
- `leftTrapRms`, `rightTrapRms`, `normalisedLeftActivation`, `normalisedRightActivation`
- `baselineRmsLeft`, `baselineRmsRight`, `calibratedAt`
- `channelMapping` (Map: A→left/right, B→left/right)
- `notice`, `errorMessage`

Key computed getters:
- `isConnected` — `true` if status is `connected` or `signalLost`
- `bilateralReady` — `true` if `symmetryIndex != null`
- `greeting` — time-of-day: "Good morning" (<12), "Good afternoon" (<17), "Good evening" (≥17)
- `displayName` — currently **hardcoded to `'Participant'`** (line 121), intended to come from SharedPreferences

#### SessionBloc (~524 lines)

**Timers (3 periodic):**
1. `_rebuildTimer` — every 250ms: computes windowed activation averages, emits snapshot with updated symmetry index, raw points, status
2. `_spsTimer` — every 1s: tracks samples-per-second, updates sessionSeconds
3. `_signalLossTimer` — every 500ms: checks if last frame was >2s ago, sets status to `signalLost`

**Key methods:**

| Method | Purpose |
|---|---|
| `connect(macAddress)` | Connects hardware, starts acquisition, subscribes to frame stream, resets session accumulators |
| `disconnect()` | Cancels subscription, stops acquisition, disconnects hardware, persists session, resets state |
| `calibrate()` | Saves current raw value as calibration midpoint |
| `saveCalibration()` | Saves baseline RMS values and sets `calibratedAt` |
| `selectTab(tab)` | Emits state with new selectedTab (for bottom nav) |
| `setChannelMapping()` | Persists A/B channel assignment to SharedPreferences |

**Frame processing (`_onFrame`):**
- Extracts left/right activation from ch3/ch1
- Accumulates activation sums for session-average computation
- Maintains rolling buffers (rawPoints, rawPoints3, activationPoints) capped at 3000
- Tracks per-session peak values for normalisation

**Snapshot emission (`_emitSnapshot`, every 250ms):**
- Computes windowed left/right activation averages
- Calculates symmetry index from those averages
- Applies smoothing via a queue of 8 SI values (`_siBuffer`)
- Normalises activations against session peaks
- Emits updated state

**Symmetry index calculation (`_calculateSymmetryIndex`):**
- Checks if both channels have active signal (variance > 50 ADC units over last 2000 samples)
- If active, computes `symmetryIndexFromLevels()` using the last raw values

### 3.10 Pages

#### Onboarding (`lib/presentation/pages/onboarding_page.dart` — 965 lines)
- 5 slides: Welcome → EMG Made Simple → Track Every Rep → Who Are You? → You're All Set
- Uses `smooth_page_indicator` for pagination dots
- Slide 4 offers user type selection (Athlete / Patient / Clinician)
- Slide 5 captures name via `TextField`
- Also has channel mapping assignment (left/right per cable)
- On complete: saves `onboarding_complete`, `user_name`, `user_type` to `SharedPreferences`
- Animated Memphis-style background via `MemphisBackdrop`

#### Home Shell (`lib/presentation/pages/home_shell_page.dart` — 265 lines)
- Contains 4-page `IndexedStack`: Dashboard, Session, Summary, Profile
- Custom bottom nav bar with 40px container, animated active indicator
- Handles connect/disconnect/calibrate callbacks
- Error message display via `BlocListener`
- **Note:** The "Session" tab uses `SessionPage` directly (not `SessionScreen`), which means the "Stop Recording" button's `Navigator.pop()` previously caused black screens (fixed)

#### Dashboard (`lib/presentation/pages/dashboard_page.dart` — 641 lines)
- Greeting ("Good morning, {name}")
- Symmetry index radial arc (`SymmetryArc`) — converts symmetry index to 0–100 score
- Metrics row: Sessions Today, Avg Symmetry, Best Balance
- Quick Start card: connection status, connect/disconnect button, "Start Session" button
- Channel A/B activation bars with `ChannelBar` widgets
- Recent sessions list (up to 3, with auto-generated titles + performance tags)
- "View Summary" button
- Theme-aware colors throughout

#### Session (`lib/presentation/pages/session_page.dart` — 315 lines)
- Two widgets: `SessionScreen` (full-screen pushed route with `PopScope`) and `SessionPage` (embedded in bottom nav)
- Tabbed interface: Anatomical, Balance, (optionally Signal)
- Timer display, "Stop Recording" / "Start Recording" button
- `_SessionActionsBar` handles the recording toggle:
  - Start: shows confirmation modal, then calls `bloc.connect()`
  - Stop: calls `bloc.disconnect()`, then `canPop()` check (fixed to avoid black screen on tab case)

#### Anatomical View (`lib/presentation/pages/anatomical_view_page.dart` — 199 lines)
- Shows `HeatmapSilhouetteWidget` with left/right activation
- Imbalance label ("Left side is X% more active" / "Right side is X% more active")
- Corrective instruction from `SignalProcessor`
- Muscle group chips (Trapezius active, Deltoid/Lat "Coming soon")

#### Balance Monitor (`lib/presentation/pages/balance_monitor_page.dart` — 454 lines)
- `TiltMeter` widget showing left/right balance as a slider
- Left Trap / Right Trap channel cards with percentage, activity level, progress bars
- Label with hysteresis (requires 2 consecutive same readings before updating displayed label)
- Channel card shows: `activation * 100` as percentage, `activityLabel()` mapping (Inactive <5%, Low <25%, Moderate <50%, High ≥50%)
- Dominance label + corrective instruction

#### Activation Summary (`lib/presentation/pages/activation_summary_page.dart` — 419 lines)
- Period filtering: Today / 7 Days / 30 Days
- `HeatmapSilhouetteWidget` with average left/right activation over period
- Muscle group chips
- Sessions count + Trend percentage
- Pattern Analysis card: Avg. Deviation (abs of average SI), Primary Imbalance (Left Trap Dominance / Right Trap Dominance / Balanced)
- Trend calculation: compares most recent two sessions' deviation
- Primary imbalance thresholds: `avgSI < -15` → Left, `avgSI > 15` → Right, else Balanced

#### Profile (`lib/presentation/pages/profile_page.dart` — 410 pages)
- User avatar with initials derived from display name
- Badge: TRACKING (if sessions > 0) or NEW USER
- Stat cards: Sessions, Time (hours/minutes), Balance score
- Dark Theme toggle
- Danger Zone (Clear All Data — button handler is empty `() {}`)

#### Calibration Screen (`lib/screens/calibration_screen.dart` — 446 pages)
- Two-phase flow: Connecting → Monitoring
- Connects to device, then shows signal quality per channel
- Noise floor in µV, status badges (No signal / Signal OK / Noisy)
- Sparkline preview of raw data
- On "Begin Session": saves baseline RMS, pushes `SessionScreen`

#### Signal View (`lib/presentation/pages/signal_view_content.dart` — 270 lines)
- Hidden behind `showResearcherTools` flag
- Dual EMG waveform charts (`EMGChart`) for left + right trapezius
- Three display modes: Raw ADC, Filtered, RMS Envelope (toggle chips)
- Single-channel fallback with amber warning

### 3.11 Widgets

#### `heatmap_silhouette_widget.dart` — Upper Body Heatmap
- `HeatmapSilhouetteWidget` displays `upper_body.png` with radial glow overlays
- `_HeatmapPainter._drawGlow()` draws a radial gradient circle per trapezius:
  - Radius = `width * 0.13` (localized to shoulder region)
  - Colour from `HeatmapGradient.at(activation * 1.4)` (boosted sensitivity)
  - Alpha fades from `0.1 + activation * 0.75` (transparent at rest, opaque at max)
- Centres at `(34%, 38%)` and `(66%, 38%)` of widget size

#### `session_visuals.dart` — Leg Silhouette + Tilt Meter
- `LegPairSilhouette` (used in Summary tab): Overlays `upper_body.png` with `CustomPaint` that draws a **4×14 grid of dots** at calculated positions
- `TiltMeter`: Animated balance indicator with track bar, marker, degree labels (-20° to +20°)
- `EmgWaveformChart`: Simple fl_chart line chart for live samples
- `SummaryBars`, `_SummaryBar`: Left/Right activation comparison bars

#### `emg_chart.dart` — EMG Waveform Chart (~398 lines)
- Full-featured real-time chart with 3 modes: Raw ADC, Filtered, RMS Envelope
- 3000-sample buffer (3 seconds at 1000 Hz)
- Signal-loss overlay (amber fade when variance < 50 ADC units for 2 seconds)
- Stats: RMS value, PEAK value
- 33ms redraw interval (~30 FPS)
- Channel activity detection via variance over 2-second window

#### `app_card.dart` — Reusable Card
Theme-aware container with `bgCard` background, `cardRadius` (32px), border, and shadow.

#### `connection_badge.dart` — Connection Status Pill
- Green dot + "Connected" / Amber + "Connecting" / Grey + "Not Connected"
- Used on Dashboard, Summary, Profile pages

#### `symmetry_arc.dart` — Radial Gauge
- 180° arc split into left (amber) and right (teal) halves
- Animated dot position based on symmetry index (-1 to +1)
- Glow effect around the dot

#### `session_tab_bar.dart` — Animated Segmented Control
Sliding highlight for Anatomical/Balance/Signal tabs within the Session page.

#### `session_confirmation_modal.dart` — Recording Dialog
Shows channel assignments before starting a session.

#### `theme_toggle.dart` — Dark/Light Switch
Circular button with animated sun/moon icon transition.

#### `status_badge.dart` — Status Badge (Legacy)
Pill badge with 4 states (connected, disconnected, recording, idle). **Contains 4 pre-existing `withOpacity` deprecations.**

#### Other widgets:
- `channel_bar.dart` — Vertical bar with percentage for activation display
- `gradient_button.dart` — Animated press-state button
- `section_label.dart` — Teal line + uppercase label
- `sym_sync_route.dart` — Page transition with fade + slide
- `memphis_widgets.dart` — Animated organic blob background
- `historical_heatmap.dart` — Wraps `LegPairSilhouette` with aggregated `SessionHeatmapData`

### 3.12 Android Native — `PluxBridge.kt` (~386 lines)

Full Kotlin implementation of the BLE bridge:

**Channel methods:**
- `connect(mac)` — Creates `BTHCommunication` via factory, calls `connect()` on a background thread, waits up to 30s with `CountDownLatch` for `CONNECTED` state
- `startAcquisition(channels, sampleRate)` — Configures `Source` objects (16-bit, port per channel), calls `controller.start()`
- `stopAcquisition` — Calls `stopInternal()` which checks `isAcquiring` flag before stopping
- `disconnect` — Stops acquisition, disconnects, unregisters receivers

**State tracking:**
- `isAcquiring` flag to prevent double-stop
- `lastConnectionState` tracked via `BroadcastReceiver` for `ACTION_STATE_CHANGED`
- `connectionReceiver` handles `CONNECTED`/`DISCONNECTED`/`ENDED` states
- Internal state read via reflection (`getInternalConnectionState()`)

**Frame forwarding:**
- `onBiopluxDataAvailable()` → `emitSample()` → posts to main handler → EventChannel sink

---

## 4. Data Flow

### Recording Flow
```
User taps "Start Recording"
  ↓
_SessionActionsBar → _showConfirmationModal()
  ↓
User confirms → bloc.connect(MAC)
  ↓
SessionBloc.connect():
  → _hardware.connect(mac)          [BLE connect]
  → _hardware.startAcquisition()    [Start 1000Hz stream]
  → Subscribe to _hardware.frames.stream
  ↓
Stream emits EmgFrame (ch1, ch3, timestamp) at ~1000Hz
  ↓
_onFrame() per frame:
  → activationFromRaw() for both channels
  → Accumulate sums for session averages
  → Append to rawPoints/rawPoints3 buffers (cap 3000)
  → Track session peaks
  ↓
_emitSnapshot() every 250ms:
  → Compute windowed averages
  → symmetryIndexFromLevels(leftAvg, rightAvg)
  → Smooth via 8-sample queue
  → Normalise activations against session peaks
  → Emit new SessionState
  ↓
UI rebuilds from BlocBuilder:
  → Dashboard: SymmetryArc, ChannelBar, metrics
  → Anatomical: HeatmapSilhouetteWidget with glow
  → Balance: TiltMeter, channel cards
```

### Disconnect Flow
```
User taps "Stop Recording"
  ↓
bloc.disconnect():
  → Cancel frame subscription
  → _hardware.stopAcquisition()     [try/catch: may fail if BLE already dropped]
  → _hardware.disconnect()
  → _persistSessionIfNeeded()       [save SessionSummary to SharedPreferences]
  → _resetSession()                 [clear all accumulators]
  → Emit SessionState.initial() + history
  ↓
Navigate: canPop() → pop to Dashboard
        : !canPop() → selectTab(Dashboard)
```

### Startup Flow
```
App launches
  ↓
SymSyncApp._init():
  → ThemeProvider.init()            [load saved theme mode]
  → Set _onboardingComplete = false [hardcoded — always shows onboarding]
  ↓
OnboardingPage (if not complete):
  → 5 slides
  → Save user_name, user_type, onboarding_complete to SharedPreferences
  ↓
HomeShellPage:
  → Create SessionBloc
  → SessionBloc.start():
     → _loadHistory()               [load from SharedPreferences]
     → _loadChannelMapping()
     → Start _rebuildTimer, _spsTimer, _signalLossTimer
```

---

## 5. State Management

**Design:** Single `Cubit<SessionState>` (`flutter_bloc`). All app state lives in one object.

**Pros:**
- Simple to reason about — one source of truth
- No cross-bloc communication needed
- Easy to snapshot/debug

**Cons:**
- Large state object (25+ fields, 224 lines for the class)
- Every `emit()` triggers a full rebuild of all `BlocBuilder` widgets
- No separation of concerns (hardware state ≠ UI state ≠ session state)
- 4 independent timers scattered in the bloc constructor

**Current issues:**
- `_rebuildTimer` emits at 250ms regardless of whether anything changed — causes unnecessary builds
- Normalised activation divides by `_sessionPeakLeft`/`_sessionPeakRight` which could be 0 at start (guarded by `> 0 ? _sessionPeakLeft : 1.0`)
- `displayName` is hardcoded to `'Participant'` — `setUserName()` exists but may not be called after onboarding (needs verification)

---

## 6. Navigation & Routing

**No named routes.** Navigation is handled via:
1. **Bottom nav tabs** — `SessionTab` enum + `IndexedStack` in `HomeShellPage`
2. **Direct `Navigator.push()`** — For `SessionScreen` (from Dashboard "Start Session" button) and `CalibrationScreen`
3. **`Navigator.pushReplacement()`** — From `CalibrationScreen` to `SessionScreen`

**Key navigation flows:**
- Dashboard "Launch Session" (text link) → `selectTab(SessionTab.session)` — switches bottom nav
- Dashboard "Start Session" (button) → `Navigator.push(SessionScreen)` — full-screen route
- Session "Stop Recording" → `disconnect()` + `canPop() ? pop() : selectTab(Dashboard)`
- Calibration "Begin Session" → `pushReplacement(SessionScreen)`
- Calibration back-arrow → `Navigator.pop()`

**Dual usage of SessionPage:**
`SessionPage` is used in two contexts:
1. Inside `SessionScreen` (pushed route) — "Start Session" from Dashboard
2. Directly in `HomeShellPage`'s `IndexedStack` — Session tab in bottom nav

This dual usage caused the black-screen bug (fixed by adding `canPop()` check before `Navigator.pop()`).

---

## 7. Hardware Layer

### Connection Lifecycle
1. `connect(MAC)` → creates `BTHCommunication`, calls native `connect()`, waits for `CONNECTED` state (30s timeout)
2. `startAcquisition(channels=[1,3], sampleRate=1000)` → configures 16-bit sources on ports 1 and 3
3. Frame streaming at 1000 Hz through EventChannel
4. `stopAcquisition()` → native `controller.stop()` (guarded by `isAcquiring` flag)
5. `disconnect()` → native `controller.disconnect()` + `unregisterReceivers()`

### Simulated Hardware
For iOS/simulator/testing: generates synthetic EMG at 50 Hz with:
- Sine wave at 2 frequencies + noise
- Burst events every ~6 seconds
- Configurable `asymmetry` parameter (default 0.18) that pushes left/right imbalance
- Flatline simulation on CH3 between 15–25 seconds

### Known Hardware Issues
- MAC address is **hardcoded** in 3 places: `home_shell_page.dart:24`, `session_page.dart:180`, `calibration_screen.dart:34`
- `stopAcquisition()` can throw "device is not in acquisition mode" if BLE already dropped — now wrapped in try-catch
- No reconnection logic — if BLE drops, user must manually reconnect
- No multi-device support

---

## 8. Signal Processing Pipeline

### Raw to Activation
```
ADC raw (0–65535, midpoint 32768)
  → de-mean: |raw - 32768|
  → normalize: / 32768
  → clamp: [0.0, 1.0]
```

### Symmetry Index
```
SI = ((right - left) / (left + right)) * 100
Range: -100 (fully left dominant) to +100 (fully right dominant)
```

The SI is **smoothed** via an 8-sample moving average (`_siBuffer`) to reduce jitter.

### Filter Chain (in `SignalFilterState`)
Used only in `EMGChart` widget (not in the main processing path):
1. **High-pass filter** (20 Hz, α=0.88) — removes DC offset
2. **Low-pass filter** (400 Hz, α=0.7) — anti-aliasing
3. **RMS envelope** (100-sample window, ~0.1s) — smoothed amplitude

### Activation Normalisation
Per-session peaks are tracked. Normalised activation = `current / sessionPeak`, clamped to [0.0, 1.0].

---

## 9. Design System

### Colours (from `lib/theme/app_theme.dart`)

| Token | Dark | Light |
|---|---|---|
| Background primary | `#171916` | `#FDF9EC` |
| Card | `#22241F` | `#FFFFFF` |
| Elevated | `#2C2E2A` | `#F8F3E6` |
| Text primary | `#FDF9EC` | `#171916` |
| Text secondary | `#C6C7C0` | `#454842` |
| Text tertiary | `#949590` | `#767872` |
| Divider | `#3A3D36` | `#E9E2D0` |

**Accents (identical in both themes):**
- Teal `#5C8F88`, Blue `#2F80ED`, Amber `#D99058`
- Red `#BA1A1A`, Green `#2E6C00`, Lime `#ADF67F`
- Left Trap `#C56D5D`, Right Trap `#8BAEA3`

### Theme Extension (`ThemeContext on BuildContext`)
Provides theme-aware getters: `context.bgPrimary`, `context.txtPrimary`, `context.bgCard`, `context.dividerClr`, `context.cardShadow`, etc. All pages should use these — never hardcode dark colours.

### Typography
- **Inter** (Google Fonts) — all UI text (weights 400–900)
- **JetBrains Mono** — numeric/monospace values

Predefined styles: `displayHero` (64), `displayLarge` (44), `displayMedium` (32), `headingLarge` (28), `headingMedium` (18), `bodyLarge` (16), `bodyMedium` (14), `labelSmall` (11), `monoLarge` (28), `monoSmall` (13).

### Spacing & Radii
- Spacing: XS(4), SM(8), MD(16), LG(24), XL(32), XXL(48)
- Radii: SM(8), MD(20), LG(28), XL(32) — card radius is XL(32)

---

## 10. Known Issues & Technical Debt

### Critical Bugs (Fixed in Session)

| Issue | Fix | File |
|---|---|---|
| "Stop Recording" caused black screen (popped root nav when used in tab) | Added `canPop()` check before `Navigator.pop()` | `session_page.dart:204` |
| Heatmap glow circles covered entire silhouette (radius = 50% of width) | Reduced to 13% of width, localized to trap region | `heatmap_silhouette_widget.dart:75` |
| Heatmap never showed orange/red (color mapping too conservative) | Apply `* 1.4` boost to activation before gradient lookup | `heatmap_silhouette_widget.dart:79` |
| Heatmap invisible at low activation (<10% threshold removed) | Removed `activation < 0.10` early return, alpha now scales from 0.1 | `heatmap_silhouette_widget.dart:76` |
| Heatmap glow centered too low (mid-chest, not traps) | Moved centre Y from 45.4% → 38% | `heatmap_silhouette_widget.dart:97-98` |
| Disconnect failed when BLE connection already lost | Wrapped `stopAcquisition()` in try-catch | `session_bloc.dart:435-438` |

### Pre-existing Issues (Not Yet Fixed)

| Priority | Issue | Location | Details |
|---|---|---|---|
| High | `withOpacity` deprecation (5 sites) | `status_badge.dart` (4 sites), `symmetry_arc.dart` (1 site) | Use `withValues(alpha:)` instead — deprecated in Flutter 3.x |
| High | Onboarding always shows | `sym_sync_app.dart:38` | `_onboardingComplete` hardcoded to `false`; SharedPreferences check is never executed |
| High | `displayName` hardcoded to "Participant" | `session_bloc.dart:121` | `setUserName()` exists but `displayName` getter ignores it; should return `userName ?? 'Participant'` |
| High | "Clear All Session Data" button does nothing | `profile_page.dart:228` | `onPressed: () {}` — no implementation |
| Medium | MAC address hardcoded in 3 places | `home_shell_page.dart:24`, `session_page.dart:180`, `calibration_screen.dart:34` | Should be configurable in-app |
| Medium | No reconnection when BLE drops | `PluxBridge.kt` + `session_bloc.dart` | Once signalLost, user must manually reconnect |
| Medium | `_rebuildTimer` fires every 250ms unconditionally | `session_bloc.dart:236` | Wastes CPU — should skip if no new frame data |
| Medium | Normalised activation at session start | `session_bloc.dart:701-702` | If `_sessionPeakLeft == 0`, defaults to 1.0 — correct but fragile |
| Low | No error handling for SharedPreferences failures | `session_history_store.dart` | If prefs fails, `load()` returns `[]`, `save()` may crash |
| Low | `session_history_store.dart` caps at 10 sessions | `line 33` | `take(10)` — old data silently dropped |
| Low | Session tab bar uses `NeverScrollableScrollPhysics` | `session_page.dart:160` | PageView is programmatic only; may confuse users expecting swipe |
| Low | `sym_sync_theme.dart` is dead code | All of it | `SymSyncTheme.light()` just delegates to `AppTheme.themeData()` which returns `darkTheme` |
| Low | Onboarding slide 4 channel mapping UI is complex (~965 lines total) | `onboarding_page.dart` | Should be split into smaller widgets |
| Low | Landing page (`index3.html`) not committed to git | root | User has not decided whether to commit the rewrite |

### Architectural Concerns

1. **Single monolithic Cubit** — `SessionBloc` handles hardware lifecycle, signal processing, session management, UI state, and user preferences. Consider splitting:
   - `ConnectionCubit` — BLE connect/disconnect/status
   - `SessionCubit` — recording state, frame processing, symmetry calculation
   - `HistoryCubit` — session persistence, aggregation, trend analysis

2. **No database** — Current JSON approach works for <10k single-user sessions but won't scale. Recommended: Isar (indexed queries + reactive) or Drift (SQLite for raw samples).

3. **No error reporting/analytics** — Crashes are silent. No crash reporting (Firebase Crashlytics, Sentry).

4. **No background BLE** — App must be in foreground for frame streaming. No background data collection.

5. **Single device only** — No multi-device, no cloud sync, no clinician dashboard.

---

## 11. Testing

**Current state:** 1 test file with 7 test cases:

| Test | What it covers |
|---|---|
| Empty history returns empty data | Edge case |
| Correct session count | Basic aggregation |
| Average symmetry computation | Core math |
| Missing symmetry index handled | Null safety |
| 15 sessions → only 10 used | `take(10)` behaviour |
| Grid dimensions (14×4) | Data structure |
| Intensities clamped to [0,1] | Range safety |

**What's missing:**
- No widget tests
- No integration tests
- No bloc unit tests (`SessionBloc` has no tests at all)
- No hardware simulation tests
- No signal processor unit tests (except what's implicitly tested via aggregation)

---

## 12. Landing Page

`index3.html` in the project root is a self-contained landing page (~20KB, no external JS frameworks):

- Dark theme matching the app (`#0F1311` background, `#FDF9EC` text)
- Google Fonts: Inter (body) + DM Serif Display (headings)
- Sections: Nav, Hero, Features (3 pillars), How It Works (3 steps), Stats (4 metrics), Heatmap Showcase (inline JS-generated 4×14 dot grid), Dashboard Showcase, Use Cases (4), Science (3 pillars), CTA, Footer
- Phone mockups rendered with CSS, heatmap visualized with canvas
- Open directly in browser: `open index3.html`

---

## Appendix A: SessionState Fields (Complete Reference)

| Field | Type | Description |
|---|---|---|
| `status` | `SessionStatus` | disconnected / connecting / connected / signalLost / error |
| `selectedTab` | `SessionTab` | dashboard / session / summary / profile |
| `busy` | `bool` | Operation in progress (connect/disconnect) |
| `latestRaw` | `int` | Most recent CH1 ADC value |
| `samplesPerSecond` | `int` | Current sample rate |
| `sessionSeconds` | `int` | Current recording duration |
| `calibrationMidpoint` | `int` | Calibration baseline ADC value |
| `liveActivation` | `double` | Latest right activation (0.0–1.0) |
| `symmetryIndex` | `double?` | Smoothed symmetry index (-100 to +100) |
| `rawPoints` | `List<int>` | CH1 buffer (3000 samples) |
| `rawPoints3` | `List<int>` | CH3 buffer (3000 samples) |
| `history` | `List<SessionSummary>` | Past sessions (up to 10) |
| `notice` | `String?` | Status message for snackbar |
| `errorMessage` | `String?` | Error message |
| `connectedAtMs` | `int?` | Session start timestamp |
| `lastFrameMs` | `int?` | Last frame timestamp |
| `channelMapping` | `Map<String, String>` | A→left/right, B→left/right |
| `leftTrapRms` | `double` | Left trapezius RMS (windowed avg) |
| `rightTrapRms` | `double` | Right trapezius RMS (windowed avg) |
| `normalisedLeftActivation` | `double` | Left activation / session peak |
| `normalisedRightActivation` | `double` | Right activation / session peak |
| `baselineRmsLeft` | `double` | Calibration baseline for left |
| `baselineRmsRight` | `double` | Calibration baseline for right |
| `calibratedAt` | `DateTime?` | Last calibration timestamp |

## Appendix B: SessionSummary Fields

| Field | Type | Persisted |
|---|---|---|
| `startedAt` | `DateTime` | Yes |
| `endedAt` | `DateTime` | Yes |
| `durationSeconds` | `int` | Yes |
| `peakRaw` | `int` | Yes |
| `averageActivation` | `double` | Yes |
| `averageSymmetryIndex` | `double?` | Yes |
| `averageLeftActivation` | `double?` | Yes |
| `averageRightActivation` | `double?` | Yes |
| `note` | `String` | Yes (auto-generated from date) |
| `channelMapping` | `Map<String, String>?` | Yes |

## Appendix C: Key Constants

| Constant | Value | Location |
|---|---|---|
| ADC midpoint | 32768 | `signal_processor.dart:4` |
| ADC full scale | 65535 | `signal_processor.dart:5` |
| Buffer size | 3000 samples | `session_bloc.dart:62-70` |
| SI smoothing window | 8 samples | `session_bloc.dart:319-320` |
| Rebuild interval | 250ms | `session_bloc.dart:236` |
| Signal loss timeout | 2000ms | `session_bloc.dart:266` |
| Session history cap | 10 sessions | `session_history_store.dart:33` |
| Heatmap grid | 4 cols × 14 rows | `session_aggregator.dart:4-5` |
| BLE connection timeout | 30s | `PluxBridge.kt:193` |
| Simulated EMG rate | 50 Hz | `simulated_emg_hardware.dart:34` |
| Heatmap glow radius | 13% of width | `heatmap_silhouette_widget.dart:73` |
| Heatmap colour boost | 1.4× | `heatmap_silhouette_widget.dart:79` |
