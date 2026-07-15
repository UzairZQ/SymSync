# SymSync

### Making bilateral muscle activity easier to understand

SymSync is a Flutter research prototype that turns two live surface-EMG signals into clear left-versus-right muscle feedback. It was created for a Human–Computer Interaction study exploring how people understand bilateral muscle activity during everyday and exercise scenarios.

The app connects to a biosignalsplux device on Android, guides the user through sensor placement and baseline calibration, and presents the signal through two complementary views: an anatomical heatmap and a balance monitor. On other platforms, simulated input keeps the interface available for development and demonstration.

> SymSync is an educational research prototype. It is not a medical device and should not be used for diagnosis or treatment.

## The experience

Users begin with a short introduction to EMG and electrode placement. After calibration, they can record a scenario and watch the balance between both muscles change in real time. Every completed session is stored locally and summarized in language intended for non-experts.

The current prototype includes:

- live bilateral EMG monitoring for upper trapezius and biceps demonstrations
- guided placement, connection and baseline calibration
- anatomical and balance-based feedback conditions
- anonymous participant and scenario management
- session history, activation summaries and accessibility settings
- CSV and JSON research-data export with baseline and task-duration values

## A closer look

<p align="center">
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.18.26.png" alt="SymSync onboarding" width="240">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.18.31.png" alt="EMG introduction" width="240">
</p>

<p align="center"><sub>A welcoming introduction to SymSync and EMG</sub></p>

<br><br>

<p align="center">
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.18.36.png" alt="Sensor placement guidance" width="240">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.18.38.png" alt="Muscle symmetry explanation" width="240">
</p>

<p align="center"><sub>Sensor placement and muscle-symmetry guidance</sub></p>

<br><br>

<p align="center">
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.18.42.png" alt="User type selection" width="240">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.18.45.png" alt="Cable assignment guidance" width="240">
</p>

<p align="center"><sub>Personalising the experience and assigning sensor channels</sub></p>

<br><br>

<p align="center">
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.18.48.png" alt="Onboarding completion" width="240">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.18.55.png" alt="Research participant setup" width="240">
</p>

<p align="center"><sub>Completing onboarding and preparing a research session</sub></p>

<br><br>

<p align="center">
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.19.06.png" alt="SymSync dashboard" width="240">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.19.12.png" alt="Dashboard quick start" width="240">
</p>

<p align="center"><sub>The dashboard and quick-start workflow</sub></p>

<br><br>

<p align="center">
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.19.19.png" alt="Anatomical muscle feedback" width="240">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.19.32.png" alt="Bilateral balance feedback" width="240">
</p>

<p align="center"><sub>The anatomical and balance-monitor feedback conditions</sub></p>

<br><br>

<p align="center">
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.19.43.png" alt="Activation summary" width="240">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.19.46.png" alt="Exercise recommendations" width="240">
</p>

<p align="center"><sub>Session insights and supporting exercise guidance</sub></p>

<br><br>

<p align="center">
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.19.53.png" alt="Profile overview" width="240">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="symsync%20screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-06-23%20at%2023.19.56.png" alt="Profile preferences" width="240">
</p>

<p align="center"><sub>Research controls, preferences and accessibility options</sub></p>

## How it works

Two synchronized channels are sampled from the biosignalsplux sEMG hub. SymSync filters and baseline-corrects the signal, calculates activation for each side, and converts the difference into visual feedback. Session state is managed with Flutter Bloc, while participant context, preferences and summaries remain on the device through SharedPreferences.

The Android build communicates with the PLUX SDK through a Flutter MethodChannel. The hardware layer is abstracted so the same interface can use simulated EMG during UI development and testing.

## Run the project

You will need Flutter and a supported Dart SDK. Real sensor streaming requires an Android device and the biosignalsplux hardware; the simulated implementation is used elsewhere.

```bash
git clone https://github.com/UzairZQ/SymSync.git
cd SymSync
flutter pub get
flutter run
```

To create an Android release build:

```bash
flutter build apk --release
```

For distribution, copy `android/key.properties.example` to
`android/key.properties` and point it to a private release keystore. Without
that file, the build intentionally uses the debug key so it remains compatible
with locally installed development APKs.

## Project structure

- `lib/data` contains hardware, persistence, notification and export services.
- `lib/domain` contains the session models and signal-processing logic.
- `lib/presentation` contains the app state and user-facing screens.
- `lib/widgets` contains reusable charts, feedback views and controls.
- `test` covers signal processing, persistence, export and mobile layouts.

## Data and privacy

SymSync does not require an account or collect participant names. Research records use anonymous participant codes, and saved sessions remain local until the researcher explicitly exports them. Exports contain summarized measurements rather than raw EMG waveforms.

Because this is a local research prototype, its SharedPreferences-based storage is not intended for clinical deployment or multi-device synchronization.

## Built with

Flutter, Dart, Flutter Bloc, SharedPreferences, fl_chart, the PLUX Android SDK and local notifications.

## License

This repository is currently maintained as a private academic project and is not published as a reusable package.
