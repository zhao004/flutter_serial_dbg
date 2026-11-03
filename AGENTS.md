# Repository Guidelines

## Project Structure & Module Organization

This Flutter application is migrating from an Android serial debugging tool to a native Flutter client. Keep its `app`-oriented structure:

- `lib/main.dart` initializes GetIt and GoRouter.
- `lib/app/di/` registers dependencies; `lib/app/routes/` defines navigation.
- `lib/app/pages/` contains views and controllers; `home` is the current template page.
- `lib/app/database/`, `models/`, and `http/` contain Drift, model, and Retrofit examples.
- `test/` contains `*_test.dart` files.
- `android/` is the Android host project. No asset tree exists yet; declare new assets in `pubspec.yaml`.

Regenerate, never hand-edit, `.g.dart` files.

## Build, Test, and Development Commands

```bash
flutter pub get                                           # Resolve dependencies
dart run build_runner build --delete-conflicting-outputs  # Regenerate `.g.dart` files
dart format lib test                                      # Format source and tests
flutter analyze                                           # Run Flutter lints
flutter test                                              # Run unit and widget tests
flutter run -d <device-id>                                # Run on a device
flutter build apk --release                               # Build the release APK
```

Run focused tests as needed, for example `flutter test test/widget_test.dart`.

## Coding Style & Naming Conventions

Use two-space indentation and `dart format` output. Use `snake_case.dart` filenames, `PascalCase` types, and `lowerCamelCase` members. Keep widgets out of transport, database, and protocol work; controllers coordinate those services.

Follow `flutter_lints` in `analysis_options.yaml`. Document public widget and service contracts with `///`, including lifecycle and side effects where relevant. Keep comments in Chinese and justify every lint suppression.

## Testing Guidelines

Use `flutter_test` with behavior-based names such as `connects to the configured TCP host`. Place files under `test/` with a `_test.dart` suffix. No coverage threshold is configured. Add focused success, failure, and boundary tests for every bug fix and transport or protocol change, then run `flutter analyze` and `flutter test`.

## Commit & Pull Request Guidelines

This checkout is not a Git repository, so no history convention is available. After initialization, use Conventional Commits with a concise Chinese subject, for example `feat(transport): 新增 TCP 客户端`.

Pull requests should explain scope, link issues, list verification results, and include UI screenshots. For Android, BLE, USB, or network changes, state the device, Android version, and hardware tested. Never commit build outputs, credentials, signing keys, or `.env` values.

## Scope & Security

Keep development Android-first. Do not log raw serial traffic, tokens, device identifiers, or secrets; keep signing material outside the repository.
