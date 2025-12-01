import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_application_1/widgets/auth_wrapper.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/config/app_theme.dart';
import 'package:flutter_application_1/providers/app_state_provider.dart';
import 'package:flutter_application_1/providers/item_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Initialize Firebase with timeout to prevent hangs
  try {
    await FirebaseService.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Firebase initialization timed out after 10 seconds');
        debugPrint('App will continue - Firebase may initialize later');
      },
    );
  } catch (e) {
    // Firebase initialization failed
    debugPrint('Firebase initialization error: $e');
    if (kIsWeb) {
      debugPrint('For web: Please add a web app in Firebase Console and update lib/firebase_options.dart');
      debugPrint('See WEB_FIREBASE_SETUP.md for instructions');
    } else {
      debugPrint('Note: Please add your Firebase configuration files (google-services.json for Android, GoogleService-Info.plist for iOS)');
    }
  }
  
  runApp(const MyApp());
}

// The root widget of your application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
      ],
      child: MaterialApp(
        title: 'AssetFlow Pro',
        theme: AppTheme.theme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
