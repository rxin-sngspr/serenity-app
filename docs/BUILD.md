# Serenity — Build Guide

> **Owner:** Engineering team
> **Purpose:** Everything needed to build, run, and debug the Serenity app. Machine issues live here, never in product docs.
> **Related:** [Architecture](ARCHITECTURE.md) | [Decisions](DECISIONS.md)

---

## Required Versions

| Tool | Version | Notes |
|------|---------|-------|
| Flutter | 3.x | Frozen in `pubspec.yaml` environment: `sdk: ^3.12.1` |
| Dart | ^3.12.1 | Bundled with Flutter SDK |
| Java | 17+ | Required by Android Gradle Plugin |
| Android SDK | 34+ | Compile SDK target |
| Gradle | 8.x | Managed by Gradle wrapper (`gradle-wrapper.properties`) |
| Android Gradle Plugin | 8.x | Set in `android/build.gradle` |
| NDK | 28.2.13676358 | Default Flutter NDK version |
| CMake | 3.31.4+ | Required by NDK 28 (see Known Issues below) |

### Android SDK Components

Install via SDK Manager:
- `platforms;android-34`
- `build-tools;34.0.0`
- `cmake;3.31.4`
- `ndk;28.2.13676358` (bundled with AGP)

---

## Before Building

Run `flutter doctor -v` and confirm all checks pass. Expected output:

```
Doctor summary (to see all details, run flutter doctor -v):
[√] Flutter (Channel stable, 3.x, on Windows)
[√] Windows Version (10.0.22631)
[√] Android toolchain - develop for Android devices (Android SDK version 34.x)
[√] Chrome - develop for the web
[√] Visual Studio - develop for Windows
[√] Android Studio (version 2024.x)
[√] VS Code (version 1.x)
[√] Connected device (1 available)
```

**Critical checks before building:**
- `[√] Android toolchain` — if this shows warnings, resolve them first
- CMake path in Android SDK — verify with `flutter config --list` or check `android/local.properties`

---

## Build Sequence

### Standard build

```powershell
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run                           # Debug on connected device
```

### Release APK

```powershell
flutter build apk --release
# Output: build\app\outputs\flutter-apk\app-release.apk
```

### Debug APK

```powershell
flutter build apk --debug
# Output: build\app\outputs\flutter-apk\app-debug.apk
```

### Install on device

```powershell
flutter install
# Or manually:
# adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## Build Configuration Files

| File | Purpose |
|------|---------|
| `android/local.properties` | SDK, CMake, Flutter paths (machine-specific) |
| `android/build.gradle` | Android Gradle Plugin version, compile SDK |
| `android/app/build.gradle` | App-level config (minSdk, targetSdk, signing) |
| `android/gradle.properties` | Gradle JVM args, AndroidX, AGP features |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle distribution version |
| `analysis_options.yaml` | Dart/Flutter lint rules |
| `build.yaml` | build_runner configuration |
| `pubspec.yaml` | Dart dependencies, environment, assets |

---

## Verification Checklist

After building, verify the APK has the required permissions:

```powershell
# List all permissions in the APK
& "C:\dev\android-sdk\build-tools\34.0.0\aapt2" dump permissions build\app\outputs\flutter-apk\app-release.apk

# Expected: android.permission.INTERNET must be present
```

---

## Known Issues

### Category 1: Project Issues

These affect the project on any machine. Documented here for new contributors.

| Issue | Impact | Status |
|-------|--------|--------|
| `dart run build_runner build` fails after drift table changes | Generated files out of sync | Run with `--delete-conflicting-outputs` flag |
| `passkeys_doctor` is an unused transitive dependency | Adds CMake build step unnecessarily | Tracked. Comes from `supabase_flutter` → `passkeys`. Cannot remove without forking supabase_flutter. |
| Release APK uses debug signing | APK is not production-signed | Acceptable for alpha testing. Add keystore before Play Store release. |

### Category 2: Machine/Environment Issues

These are specific to a given development machine. Document workarounds here.

| Issue | Cause | Workaround |
|-------|-------|------------|
| Windows file locking | Interrupted Gradle build leaves `java.exe` processes | `taskkill /F /IM java.exe` before retrying |
| Gradle daemon stale | Corrupted daemon cache | `cd android && gradlew --stop && cd ..` then retry |
| `ANDROID_HOME` not set | Missing environment variable | Set to `C:\dev\android-sdk` or wherever SDK is installed |
| CMake 3.22.1 incompatible with NDK 28 | NDK 28 LLD rejects `--no-rosegment` flag that CMake 3.22.1 generates | Install CMake 3.31.4+ via SDK Manager. Set `cmake.dir` in `android/local.properties` |

#### Resolving CMake/NDK incompatibility

The `--no-rosegment` error:

```
CMake Error at ... (message):
  The FFltoLinker.cmake file is not compatible with the LLD linker.
  --no-rosegment: unknown argument
```

**Root cause:** `passkeys_doctor: 1.4.1` (transitive from `supabase_flutter` → `passkeys`) has native code that generates CMake flags requiring CMake < 3.28. But NDK 28 only works with CMake ≥ 3.28.

**Fix:**
1. Open Android SDK Manager → SDK Tools → CMake
2. Install CMake 3.31.4 (or latest)
3. Edit `android/local.properties`:
   ```
   cmake.dir=C:\\dev\\android-sdk\\cmake\\3.31.4
   ```
4. Clean and rebuild

### Category 3: Dependency Issues

| Issue | Cause | Workaround |
|-------|-------|------------|
| `passkeys_doctor` native compilation fails | NDK 28 + CMake 3.22.1 incompatibility | See CMake fix above |
| `supabase_flutter` version conflicts | Pinning to `^2.8.0` may lag behind breaking changes | Run `flutter pub upgrade` and update code for any API changes |
| Build fails after major Flutter upgrade | Generated code out of sync | `dart run build_runner build --delete-conflicting-outputs` |

### Category 4: Current Known Workarounds

Active workarounds applied to the project:

1. **`android/local.properties`** — `cmake.dir` is pinned to `C:\\dev\\android-sdk\\cmake\\3.31.4` to bypass NDK 28 + CMake 3.22.1 incompatibility
2. **`android/app/src/main/AndroidManifest.xml`** — `<uses-permission android:name="android.permission.INTERNET" />` added because debug/profile manifests have it but release manifest was missing it
3. **`lib/core/supabase/supabase_config.dart`** — Uses `publishableKey:` parameter instead of deprecated `anonKey:` parameter

---

## Environment Troubleshooting

### APK has no INTERNET permission

```powershell
# Verify
& "C:\dev\android-sdk\build-tools\34.0.0\aapt2" dump permissions app-release.apk | Select-String "INTERNET"

# If missing, check android/app/src/main/AndroidManifest.xml has:
# <uses-permission android:name="android.permission.INTERNET" />
```

### Clean environment (when nothing works)

If the build environment becomes unreliable:

1. Kill all Java/Gradle processes: `taskkill /F /IM java.exe`
2. Delete build cache: `Remove-Item -Recurse -Force android/.gradle`
3. Delete Flutter build: `flutter clean`
4. Delete pub cache lock: `Remove-Item -Recurse -Force .dart_tool`
5. Fresh: `flutter pub get && dart run build_runner build --delete-conflicting-outputs`
6. Build: `flutter build apk --debug`

### When this machine cannot build

If environment issues block progress for more than 30 minutes:

1. Ensure all fixes are committed/pushed
2. Build on a different machine (clone repo, run build)
3. Or set up GitHub Actions CI with the build workflow
4. Or perform a clean Android Studio installation on this machine
