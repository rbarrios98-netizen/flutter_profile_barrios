Place your logo image here as `cpms_logo.png` so the Flutter app can load it via `Image.asset('assets/cpms_logo.png')`.

Steps:
1. Save the provided logo image to: `assets/cpms_logo.png` (lowercase filename).
2. Run the app:

```bash
flutter pub get
flutter run
```

Notes:
- For Android emulator use `10.0.2.2` when the app calls `http://localhost:3000` for backend APIs.
- If the image filename or path differs, update `lib/pages/home_page.dart` and `pubspec.yaml` accordingly.
