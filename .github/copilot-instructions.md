<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

This project is a Flutter desktop/mobile app for Windows and Android. It features three main tabs (Generate CC, Translate CC, Models), a dynamic bottom bar, and an expandable logs panel. The app integrates with local Whisper AI and LibreTranslate models for subtitle generation and translation. Preferences are stored in a config file in the app directory. UI and logic should follow the requirements in the project README and user stories.
But now we'll use a different approach to implement the features.
## Copilot Instructions (faster-whisper, ffmpeg and fastapi) in a venv [faster-whisper-env] in %USERPROFILE%\virtual_environments for subtitle generation and (libretranslate and fastapi) in a venv [libretranslate-env] in %USERPROFILE%\virtual_environments for translation
- Use the `faster-whisper` library for subtitle generation.
- Implement a FastAPI backend(py file in assets/py_script) to handle requests for subtitle generation.
- Use the `ffmpeg` library for audio processing.
- Use the `libretranslate` library for translation.
- Implement a FastAPI backend(py file in assets/py_script) to handle requests for translation.
- Ensure that the FastAPI backends are set up to run in their respective virtual environments.
- Use the `requests` library to communicate with the FastAPI backends from the Flutter app.
- Store configuration settings in a `config.json` file in the app directory.
- Models Table should allow users to download, manage, and update Faster-Whisper and LibreTranslate models now.
- remove the gpu requirement from the models.[removoe any logic that checks for GPU availability]