# Authenticall

A Flutter project at its initial scaffold stage. The current app is the standard Material counter demo: tap the **+** button to increment the counter.

## Current status

- Material UI with a seeded purple color scheme.
- Stateful counter screen.
- Widget test covering the counter interaction.
- Platform scaffolding for Android, iOS, web, Windows, macOS, and Linux. These targets have not all been built or verified.

## Requirements

Install Flutter with a bundled Dart SDK compatible with `^3.13.1`, as required by `pubspec.yaml`. Native builds also require the toolchain for the target platform.

## Run locally

```sh
git clone https://github.com/Karanjain487l/authenticall.git
cd authenticall
flutter pub get
flutter devices
flutter run
```

To run in Chrome:

```sh
flutter run -d chrome
```

## Development checks

```sh
flutter analyze
flutter test
```

## Project structure

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App entry point and counter screen |
| `test/widget_test.dart` | Counter widget test |
| `pubspec.yaml` | Package metadata and dependencies |
| `pubspec.lock` | Locked dependency versions |
| `android/`, `ios/` | Mobile platform runners |
| `web/` | Web app scaffolding |
| `windows/`, `macos/`, `linux/` | Desktop platform runners |

## Repository hygiene

Generated build files, Flutter caches, IDE metadata, local environment files, and signing credentials are excluded through `.gitignore`. Keep credentials out of source code.
