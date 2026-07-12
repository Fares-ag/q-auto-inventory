import 'package:flutter/material.dart';
import 'app.dart';
import 'bootstrap/firebase_app_bootstrap.dart';

// This entry point mirrors main.dart but can be customised for web-only
// configuration if needed.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrapper = await initializeFirebaseApp(
    enableOfflinePersistence: false,
  );

  runApp(InventoryApp(bootstrapper: bootstrapper));
}
