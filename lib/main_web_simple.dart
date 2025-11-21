import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'services/firebase_services.dart';
import 'firebase_options.dart';

// This entry point mirrors main.dart but can be customised for web-only
// configuration if needed.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final bootstrapper = FirebaseBootstrapper();
  await bootstrapper.ensureSignedInAnonymously();
  await bootstrapper.configureOfflinePersistence(enabled: false);

  runApp(InventoryApp(bootstrapper: bootstrapper));
}
