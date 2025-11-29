# Flutter Openai Api Example App

Minimal Flutter example app demonstrating OpenAI text (chat) and image generation.

## Features
- Chat-based text generation using the OpenAI GPT (chat) model. Conversation is kept in-memory using a global list.
- Image generation (example integration with OpenAI image endpoints).

## Quick setup
1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Add the OpenAI Dart package to `pubspec.yaml`:
```
    dependencies:
        openai_dart: ^0.6.0+1
        flutter_dotenv: ^5.1.0
```

3. Provide your OpenAI API key as an environment variable named `OPENAI_API_KEY`.

```
OPENAI_API_KEY=
ORGANIZATION=
```

## Run the app

1. Fetch dependencies:

    `flutter pub get`

2. Run on a connected device or emulator:

    `flutter run`

Notes
- Chat UI and OpenAI integration live in `lib/main.dart` and `lib/openai_services.dart`.
- The app keeps the conversation in a global list so the chat persists while the app runs.
- This `README.md` is intentionally minimal — see the source files for implementation details.
