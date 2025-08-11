import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Controllers and State
import 'controllers/whisper_controller.dart';
import 'state/translation_state.dart';

// Services
import 'services/permissions_service.dart';

// Global keys for state management
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  print('Starting app...');
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter binding initialized...');

  await PermissionsService.requestAndroidPermissions();
  print('Permissions requested...');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WhisperController()),
        ChangeNotifierProvider(create: (_) => TranslationState()),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        navigatorKey: navigatorKey,
        home: Scaffold(
          appBar: AppBar(title: const Text('CC Gen Ultimate')),
          body: const Center(child: Text('App is working!')),
        ),
      ),
    ),
  );
}
