import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Controllers and State
import 'controllers/whisper_controller.dart';
import 'state/translation_state.dart';

// Services
import 'services/permissions_service.dart';

// UI Components
import 'ui/theme_app_wrapper.dart';

// Global keys for state management
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PermissionsService.requestAndroidPermissions();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WhisperController()),
        ChangeNotifierProvider(create: (_) => TranslationState()),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        navigatorKey: navigatorKey,
        home: const ThemeAppWrapper(),
      ),
    ),
  );
}
