import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/widgets/splash_screen.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  // 1. Prepare all the app services and data BEFORE running the app.
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // 2. Register ALL your adapters.
  Hive.registerAdapter(ItemTypeAdapter());
  Hive.registerAdapter(ItemModelAdapter());
  Hive.registerAdapter(LocalUserAdapter());

  // 3. Open ALL your boxes.
  await Hive.openBox<ItemModel>('items');
  await Hive.openBox<LocalUser>('users');

  // 4. Create your data store instance.
  final dataStore = LocalDataStore();

  // 5. Load all the data from storage.
  await dataStore.loadItemsFromHive();
  await dataStore.loadUsersFromHive();

  // 6. Now, run the app with the fully loaded data store.
  runApp(
    ChangeNotifierProvider.value(
      value: dataStore, // Use .value because the instance already exists.
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The build method is now clean. It only describes the UI.
    // No data is loaded here.
    return MaterialApp(
      title: 'Q-AUTO DAM',
      theme: ThemeData(
          primarySwatch: Colors.grey,
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: false),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
