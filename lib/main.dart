import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/widgets/root_screen.dart'; // Import the new RootScreen
import 'package:flutter_application_1/widgets/items_screen.dart'; // This is now a content screen
import 'package:flutter_application_1/widgets/dashboard_screen.dart'; // This is now a content screen
import 'package:flutter_application_1/widgets/item_model.dart'; // Keep imports for data models
import 'package:flutter_application_1/widgets/issue_model.dart';
import 'package:flutter_application_1/widgets/history_entry_model.dart';
import 'dart:math';

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
