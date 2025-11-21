import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'services/firebase_services.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final bootstrapper = FirebaseBootstrapper();
  // Try anonymous auth, but don't fail if disabled - let AuthWrapper handle login
  await bootstrapper.ensureSignedInAnonymously();
  await bootstrapper.configureOfflinePersistence();

  runApp(InventoryApp(bootstrapper: bootstrapper));
}
