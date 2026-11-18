# AuthentiCall

Flutter application source for voice analysis and Agora audio calls, with a bundled TensorFlow Lite voice-spoofing model.

## Android download

Download the [AuthentiCall Android preview APK](https://github.com/Karanjain487l/authenticall/releases/download/v1.0.0-preview.1/authenticall.apk) (about 309 MB), or read the [release notes and installation instructions](https://github.com/Karanjain487l/authenticall/releases/tag/v1.0.0-preview.1). Requires Android 7.0 or newer. This is an owner-supplied demo build; its exact correspondence to this source snapshot has not been verified.

## Status

This repository now contains the app project identified by its owner as the source used for the app installed on their phone. It replaces the unrelated Flutter counter scaffold previously published here.

**This source snapshot is not yet a verified, reproducible build.** Inspection found:

- `lib/detection/engine.dart` imports `tflite_runner.dart`, but that file is missing from the supplied project. Restore the original matching implementation before building.
- `test/widget_test.dart` is the old counter test and references `MyApp`, which the current entry point no longer defines. It is retained as supplied, not evidence of passing app tests.
- `agora_rtc_engine` is declared as `^6.3.2`, while the supplied lockfile resolves `6.6.4`. The exact version used by the installed app has not been verified.
- The Android release configuration currently uses debug signing. Configure release signing before distributing a production build.
- No successful analysis, test, rebuild, or phone inference verification is claimed for this published snapshot.

## Included code

- AuthentiCall screens for onboarding, home, analysis, calls, history, and settings.
- Microphone audio sources, DSP utilities, and simulated audio sources.
- Agora call controls and raw audio observer integration.
- Hive local storage and Provider state management.
- A detection engine that buffers audio at 16 kHz into 80,000-sample windows and attempts inference approximately every second.
- Android and web project files from the supplied source. Web inference compatibility has not been verified.

## Model asset

| Item | Supplied value |
| --- | --- |
| Model | `assets/authenticall_ens_mobile_float32.tflite` |
| Size | 9,154,888 bytes |
| SHA-256 | `580b9e6455cb0efb433ee9758bad50ac8ef3979ed5ac778e229670b9d2f8280d` |
| Metadata | `assets/mobile_model_spec.json` |
| Metadata input | `pcm`, float32, shape `[1, 80000]` |
| Metadata output | `spoof_prob`, float32, shape `[1, 1]` |

The metadata labels the weights as real v2/v3 checkpoints and records an expected development EER of 16.92%. These are supplied metadata claims, not independently reproduced measurements. The asset has not been established as the exact model behind the research paper's reported results. The checksum identifies the file included here; it does not validate model accuracy or provenance.

## Setup

Install Flutter with Dart compatible with `>=3.3.0 <4.0.0` and the Android SDK/toolchain. Start by restoring the missing runner and updating the obsolete test noted above.

```sh
git clone https://github.com/Karanjain487l/authenticall.git
cd authenticall
flutter pub get
flutter analyze
flutter test
flutter run
```

These are the intended development commands; they are not a record of passing checks for this snapshot.

For real Agora calls, use your own Agora project. Configure the App ID and any required channel token through the app's Call configuration screen. The public copy omits the owner's hardcoded App ID. You may also supply an App ID when building:

```sh
flutter run --dart-define=AGORA_APP_ID=YOUR_APP_ID
```

Keep channel tokens, certificates, signing keys, and other credentials out of Git. The app's simulation/demo modes are not proof of live-call model accuracy.

## Layout

| Directory | Purpose |
| --- | --- |
| `lib/audio/` | Microphone, platform, simulation, and DSP code |
| `lib/detection/` | Detection engine; matching TFLite runner still missing |
| `lib/services/` | Agora service |
| `lib/state/` | Call, detection, history, and theme controllers |
| `lib/ui/` | Screens and shared widgets |
| `assets/` | Model, metadata, and checksum |
| `android/`, `web/` | Supplied platform projects |

## Limitations

Use this project as a research prototype. A voice score is not identity verification or a guarantee that a call is safe. Live-call accuracy and the research results need verification with the exact matching model and evaluation protocol. An owner-supplied Android APK is available as a preview release; it is not a verified rebuild of this source snapshot.
