# Recreate This Flutter Mux Upload Demo

This guide recreates the current project as a fresh Flutter app.

## What This App Does

- Shows a login screen with two demo users.
- `creator / creator` can pick a local video and upload it to Mux using a direct upload URL.
- `subscriber / subscriber` can watch the latest uploaded video through Mux playback.
- Stores only the latest playback ID in app memory, so uploaded video state is lost when the app restarts.
- Uses Mux credentials passed at runtime with `--dart-define`.

## Requirements

- Flutter SDK with Dart `^3.11.3` support.
- A Mux account.
- Mux API token ID and token secret with video permissions.
- Android, iOS, macOS, Windows, Linux, or web target configured through Flutter.

## Create A New Flutter Project

```bash
flutter create testupload
cd testupload
```

If you want a different app name, replace `testupload` with your preferred project name. You will also need to update package imports in tests if the app name changes.

## Add Dependencies

Update `pubspec.yaml` so the dependencies include:

```yaml
environment:
  sdk: ^3.11.3

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  file_picker: ^10.3.7
  http: ^1.6.0
  video_player: ^2.10.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

Then install packages:

```bash
flutter pub get
```

## Copy The App Code

Copy this project's app entry point into the new project:

```text
lib/main.dart
```

The current `lib/main.dart` contains:

- `MuxDemoApp`
- `LoginScreen`
- `CreatorScreen`
- `SubscriberScreen`
- `MuxClient`
- `MuxDirectUpload`
- `UploadProgress`

Important implementation details to preserve:

- Mux credentials are read from compile-time environment values:

```dart
const muxTokenId = String.fromEnvironment('MUX_TOKEN_ID');
const muxTokenSecret = String.fromEnvironment('MUX_TOKEN_SECRET');
```

- The latest uploaded video is stored in memory only:

```dart
String? latestPlaybackId;
```

- Mux direct uploads are created with:

```dart
POST https://api.mux.com/video/v1/uploads
```

- Playback uses this HLS URL format:

```dart
https://stream.mux.com/<PLAYBACK_ID>.m3u8
```

## Android Internet Permission

For Android, add the internet permission to `android/app/src/main/AndroidManifest.xml` directly under the opening `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

The top of the manifest should look like:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="testupload"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
```

## Optional Widget Test

Replace `test/widget_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:testupload/main.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MuxDemoApp());

    expect(find.text('Mux Upload Demo'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(
      find.text('Demo users: creator/creator and subscriber/subscriber'),
      findsOneWidget,
    );
  });
}
```

If your new project name is not `testupload`, change the import to match your package name.

## Run The App

Run with Mux credentials:

```bash
flutter run \
  --dart-define=MUX_TOKEN_ID=your_mux_token_id \
  --dart-define=MUX_TOKEN_SECRET=your_mux_token_secret
```

For a specific device:

```bash
flutter devices
flutter run -d <device_id> \
  --dart-define=MUX_TOKEN_ID=your_mux_token_id \
  --dart-define=MUX_TOKEN_SECRET=your_mux_token_secret
```

## Test And Analyze

```bash
flutter analyze
flutter test
```

## Demo Login Details

Use these credentials in the app:

```text
creator / creator
subscriber / subscriber
```

## Known Limitations

- This demo sends Mux API credentials from the client app. That is acceptable only for local testing. In production, create direct uploads from a backend server instead.
- The latest playback ID is kept in memory only. Add a backend or database if subscribers need to see uploads after app restart.
- Uploaded assets use public playback policy.
- Mux processing can take time after upload completes, so the app polls until an asset and playback ID are available.

## Files To Port From This Project

Minimum files:

```text
pubspec.yaml dependency changes
lib/main.dart
android/app/src/main/AndroidManifest.xml internet permission
```

Generated folders such as `build/`, `.dart_tool/`, and IDE folders such as `.idea/` do not need to be copied.
