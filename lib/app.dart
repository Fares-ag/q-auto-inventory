import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/firestore_models.dart';
import 'navigation/app_router.dart';
import 'services/firebase_services.dart';
import 'services/permission_service.dart';
import 'services/offline_queue_service.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_wrapper.dart';

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key, required this.bootstrapper});

  final FirebaseBootstrapper bootstrapper;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: bootstrapper.firestore),
        Provider(create: (_) => CatalogService(bootstrapper.firestore)),
        Provider(create: (_) => AssetCounterService(bootstrapper.firestore)),
        Provider(create: (_) => DepartmentService(bootstrapper.firestore)),
        Provider(create: (_) => CommentService(bootstrapper.firestore)),
        Provider(create: (_) => IssueService(bootstrapper.firestore)),
        Provider(create: (_) => HistoryService(bootstrapper.firestore)),
        Provider(create: (_) => StaffService(bootstrapper.firestore)),
        Provider(create: (_) => SystemSettingsService(bootstrapper.firestore)),
        Provider(create: (_) => VehicleService(bootstrapper.firestore)),
        Provider(
            create: (_) =>
                PermissionService(firestore: bootstrapper.firestore)),
        Provider(create: (_) => OfflineQueueService()),
        Provider.value(value: bootstrapper),
      ],
      child: MaterialApp(
        title: 'Q Auto Inventory',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

extension InventoryItemExtensions on InventoryItem {
  String get displayStatus => status ?? 'Unknown';
}
