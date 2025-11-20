# Flutter Gemini 3 Pro AI API Example App

Minimal chat UI that calls Gemini REST API directly (no SDK) to generate text and images.

## Quick start

1) Clone and install

```sh
flutter pub get
```

2) Configure API key

-  `.env` and set your key:

```
GEMINI_API_KEY=YOUR_API_KEY
# Optional (defaults to gemini-2.5-flash)
GEMINI_MODEL=gemini-2.5-flash
```

Note: `.env` is already git-ignored.

3) Run the app

- Android: connect a device/emulator, then:
```sh
flutter run -d android
```
- iOS (on macOS):
```sh
flutter run -d ios
```
- Web:
```sh
flutter run -d chrome
```
- Windows/Mac/Linux (desktop enabled):
```sh
flutter run
```

## How it works (REST only)
- The app constructs Gemini chat history as `contents` with role `user`/`model` and `parts`.
- It posts JSON to: `https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key=API_KEY` using `package:http`.
- Text is read from `part.text`.
- Images (if any) are read from `inline_data` as base64 and displayed.

See `lib/services/gemini_ai_service.dart` and `lib/main.dart`.

## Tips
- If you see “Missing GEMINI_API_KEY”, ensure `.env` exists and contains your key.
- To switch models, change `GEMINI_MODEL` in `.env`.
- Network errors will appear as a Snackbar with the server message.
