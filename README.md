# CC Gen Ultimate

A powerful Flutter desktop/mobile application for subtitle generation and translation using AI models. The application supports both Windows and Android platforms.

## Features

- **Subtitle Generation**: Generate subtitles from video/audio files using Faster-Whisper AI model
- **Subtitle Translation**: Translate subtitles using LibreTranslate
- **Multi-Platform**: Works on Windows desktop and Android devices
- **Dynamic Interface**: 
  - Three main tabs: Generate CC, Translate CC, and Models
  - Dynamic bottom bar for status and controls
  - Expandable logs panel for detailed operation tracking
- **Model Management**: 
  - Download and manage Faster-Whisper models
  - Manage LibreTranslate models
  - No GPU requirement - works on CPU

## Prerequisites

- Python 3.8 or higher
- Flutter SDK
- FFmpeg (installed automatically)
- Windows/Android device

## Installation

1. Clone the repository:
```bash
git clone https://github.com/ShahFaisalGfG/cc_gen_ultimate.git
cd cc_gen_ultimate
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. The app will automatically set up:
   - Python virtual environments
   - Faster-Whisper in `faster-whisper-env`
   - LibreTranslate in `libretranslate-env`
   - FFmpeg and other required dependencies

## Project Structure

- `/lib`: Core Flutter application code
  - `/controllers`: State management and control logic
  - `/logic`: Business logic implementation
  - `/models`: Data models and structures
  - `/services`: Backend services and API integrations
  - `/ui`: User interface components
  - `/utils`: Utility functions and helpers

- `/assets`:
  - `/installation_scripts`: Automated setup scripts
  - `/py_scripts`: FastAPI backends for AI processing
    - `whisper_api.py`: Subtitle generation API
    - `translate_api.py`: Translation API

## How It Works

1. **Subtitle Generation**:
   - Uses Faster-Whisper model through FastAPI backend
   - Processes audio/video files to generate accurate subtitles
   - Supports various input formats via FFmpeg

2. **Translation**:
   - Utilizes LibreTranslate through FastAPI backend
   - Supports multiple language pairs
   - Batch translation capabilities

3. **Model Management**:
   - Download and update AI models
   - Manage model configurations
   - Track model status and versions

## Configuration

The application stores its configuration in `config.ini` in the app directory. This includes:
- Model paths and settings
- API endpoints
- User preferences
- Language settings

## Building

For Windows:
```bash
flutter build windows
```

For Android:
```bash
flutter build apk
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Faster-Whisper](https://github.com/guillaumekln/faster-whisper) for subtitle generation
- [LibreTranslate](https://github.com/LibreTranslate/LibreTranslate) for translation capabilities
- [Flutter](https://flutter.dev) for the cross-platform framework
- [FastAPI](https://fastapi.tiangolo.com) for the backend API
