import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/widgets/root_screen.dart'; // Import the new RootScreen
// This is now a content screen
// This is now a content screen
// Keep imports for data models

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

// The root widget of your application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q-AUTO Inventory',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
      home: const RootScreen(), // The RootScreen is now the app's entry point
      debugShowCheckedModeBanner: false,
    );
  }
}
