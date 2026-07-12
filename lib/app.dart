import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/firestore_models.dart';
import 'navigation/app_router.dart';
import 'services/firebase_services.dart';
import 'services/permission_service.dart';
import 'services/offline_queue_service.dart';
import 'services/data_preloader_service.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_wrapper.dart';

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key, required this.bootstrapper});

  final FirebaseBootstrapper bootstrapper;

  @override
  Widget build(BuildContext context) {
    // Provider is kept for backward-compat with screens that still use
    // context.read<T>(). New screens use flutter_riverpod providers in
    // lib/providers/. Both can coexist inside a ProviderScope.
    return MultiProvider(
      providers: [
        Provider.value(value: bootstrapper.firestore),
        ChangeNotifierProvider(create: (_) => OfflineQueueService()),
        ProxyProvider<OfflineQueueService, CatalogService>(
          update: (ctx, queue, _) =>
              CatalogService(bootstrapper.firestore, offlineQueue: queue),
        ),
        Provider(create: (_) => AssetCounterService(bootstrapper.firestore)),
        Provider(create: (_) => DepartmentService(bootstrapper.firestore)),
        Provider(create: (_) => CommentService(bootstrapper.firestore)),
        Provider(create: (_) => IssueService(bootstrapper.firestore)),
        Provider(create: (_) => HistoryService(bootstrapper.firestore)),
        Provider(create: (_) => StaffService(bootstrapper.firestore)),
        Provider(create: (_) => UserService(bootstrapper.firestore)),
        Provider(create: (_) => SystemSettingsService(bootstrapper.firestore)),
        Provider(create: (_) => VehicleService(bootstrapper.firestore)),
        Provider(
          create: (_) => PermissionService(firestore: bootstrapper.firestore),
        ),
        Provider(
          create: (ctx) => DataPreloaderService(
            catalog: ctx.read<CatalogService>(),
            departments: ctx.read<DepartmentService>(),
            staff: ctx.read<StaffService>(),
          ),
        ),
        Provider.value(value: bootstrapper),
      ],
      child: MaterialApp(
        title: 'Q Auto Inventory',
        debugShowCheckedModeBanner: false,
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
