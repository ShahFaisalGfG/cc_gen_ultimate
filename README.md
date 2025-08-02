
# CC Gen Ultimate

CC Gen Ultimate is a cross-platform Flutter app (Windows & Android) for generating and translating subtitles (closed captions) using local Whisper AI and LibreTranslate models. The app communicates with local FastAPI Python backends for subtitle generation and translation, each running in its own virtual environment.

## Features
* Generate subtitles for audio/video files (single or batch, queued)
* Translate generated subtitles to other languages (using local LibreTranslate)
* Three main tabs: Generate CC, Translate CC, Models
* Drag & drop or select files for processing
* Model, language, translation, and format options
* Download, manage, and update Faster-Whisper and LibreTranslate models (no GPU required)
* Expandable/collapsible logs panel (auto-expands on error)
* All preferences and settings saved in a `config.json` file in the app directory
* Output files saved in the same directory as the source, with appropriate naming

## Getting Started
1. Install Flutter (https://docs.flutter.dev/get-started/install)
2. Run `flutter pub get` in the project directory
3. Install Python (recommended: 3.10+) and ensure it's in your PATH
4. Use the provided batch scripts in `assets/installation_scripts/` to set up dependencies and create virtual environments for:
   - Faster-Whisper backend (`faster-whisper-env`)
   - LibreTranslate backend (`libretranslate-env`)
5. Start the FastAPI servers for subtitle generation and translation (see `assets/py_scripts/whisper_api.py` and `translate_api.py`)
6. Run the app: `flutter run -d windows` or `flutter run -d android`

## TODO

* Improve integration and error handling for FastAPI backends
* Enhance file processing, translation, and model management logic
* Polish UI/UX
* Add more model management features (download, update, remove)

See `.github/copilot-instructions.md` for developer guidance and backend setup details.
