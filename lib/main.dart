import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/login_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ItemTypeAdapter());
  Hive.registerAdapter(ItemModelAdapter());
  await Hive.openBox<ItemModel>('items');
  await LocalDataStore().loadItemsFromHive();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q-AUTO Inventory',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
