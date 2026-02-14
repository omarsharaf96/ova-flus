# OvaFlus Android App

Native Android application built with Kotlin and Jetpack Compose. Provides budget tracking, transaction management, and stock portfolio features with Material Design 3 and Android-native biometric authentication.

## Tech Stack

- Kotlin 1.9.22 + Jetpack Compose (BOM 2024.02.00)
- Room 2.6.1 for local persistence
- Kotlin Coroutines + Flow for async operations
- Hilt 2.50 for dependency injection
- Retrofit 2.9.0 + OkHttp 4.12.0 for networking
- Navigation Compose 2.7.7 for navigation
- AWS Amplify 2.14.0 for Cognito authentication
- Gradle with version catalogs (libs.versions.toml)
- WorkManager for background sync

## Prerequisites

- Android Studio Hedgehog (2023.1.1) or newer
- JDK 17
- Android SDK 34 (compileSdk/targetSdk)
- Android SDK 26 (minSdk)

## Project Structure

```
apps/android/
├── build.gradle.kts          # Project-level build config
├── settings.gradle.kts       # Module settings
├── gradle/
│   └── libs.versions.toml    # Version catalog
└── app/
    ├── build.gradle.kts      # App module build config
    └── src/main/
        ├── AndroidManifest.xml
        └── java/com/ovaflus/app/
            ├── MainActivity.kt
            ├── OvaFlusApp.kt
            ├── ui/
            │   ├── navigation/NavGraph.kt
            │   ├── theme/
            │   ├── screens/
            │   │   ├── dashboard/
            │   │   ├── budget/
            │   │   ├── stocks/
            │   │   └── profile/
            │   └── components/
            ├── domain/
            │   ├── models/
            │   └── usecases/
            ├── data/
            │   ├── repositories/
            │   ├── remote/
            │   └── local/
            ├── di/
            ├── widget/
            └── workers/
```

## Building

1. Open `apps/android/` in Android Studio as a project
2. Wait for Gradle sync to complete
3. Build > Make Project or run `./gradlew assembleDebug`

## Configuring Amplify

1. Install the Amplify CLI: `npm install -g @aws-amplify/cli`
2. Run `amplify init` in the android project directory
3. Add auth: `amplify add auth`
4. Push configuration: `amplify push`
5. The generated `amplifyconfiguration.json` and `awsconfiguration.json` will be placed in `app/src/main/res/raw/`

## Running

### On Emulator
1. Open AVD Manager in Android Studio
2. Create or select a virtual device (API 26+)
3. Click Run or use `./gradlew installDebug`

### On Physical Device
1. Enable Developer Options and USB Debugging on your device
2. Connect via USB
3. Click Run or use `./gradlew installDebug`

## Architecture

The app follows Clean Architecture with MVVM:

- **UI Layer**: Jetpack Compose screens with ViewModels using StateFlow
- **Domain Layer**: Use cases and data models
- **Data Layer**: Repository pattern with Room (local) and Retrofit (remote)
- **DI**: Hilt modules for dependency injection

## Play Store Distribution

1. Generate a signed APK/AAB: Build > Generate Signed Bundle/APK
2. Create a keystore for release signing
3. Configure signing in `app/build.gradle.kts` for release builds
4. Upload the AAB to Google Play Console
5. Complete store listing, content rating, and pricing
