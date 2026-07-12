import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:q_auto_inventory/models/firestore_models.dart';
import 'package:q_auto_inventory/services/firebase_services.dart';
import 'package:q_auto_inventory/services/permission_service.dart';
import 'package:q_auto_inventory/services/offline_queue_service.dart';
import 'package:q_auto_inventory/services/data_preloader_service.dart';
import 'package:q_auto_inventory/theme/app_theme.dart';
import 'package:q_auto_inventory/navigation/permission_guard_wrapper.dart';
import 'package:q_auto_inventory/screens/auth/login_screen.dart';
import 'package:q_auto_inventory/screens/finance/finance_portal_shell.dart';
import 'package:q_auto_inventory/screens/items/items_screen.dart';
import 'package:q_auto_inventory/screens/items/finance_edit_item_screen.dart';
import 'package:q_auto_inventory/screens/reports/reports_hub_screen.dart';
import 'package:q_auto_inventory/screens/settings/settings_screen.dart';
import 'package:q_auto_inventory/widgets/asset_preloader_widget.dart';
import 'package:q_auto_inventory/widgets/session_auth_gate.dart';

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key, required this.bootstrapper});

  final FirebaseBootstrapper bootstrapper;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: bootstrapper.firestore),
        ChangeNotifierProvider(create: (_) => OfflineQueueService()),
        ProxyProvider<OfflineQueueService, CatalogService>(
          update: (ctx, queue, _) =>
              CatalogService(bootstrapper.firestore, offlineQueue: queue),
        ),
        Provider(create: (_) => DepartmentService(bootstrapper.firestore)),
        Provider(create: (_) => CommentService(bootstrapper.firestore)),
        Provider(create: (_) => IssueService(bootstrapper.firestore)),
        Provider(create: (_) => HistoryService(bootstrapper.firestore)),
        Provider(create: (_) => StaffService(bootstrapper.firestore)),
        Provider(
          create: (_) =>
              PermissionService(firestore: bootstrapper.firestore),
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
        title: 'Inventory — Finance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        home: const _FinanceAuthWrapper(),
        onGenerateRoute: _FinanceRouter.onGenerateRoute,
      ),
    );
  }
}

// ── Auth wrapper ─────────────────────────────────────────────────────────────

class _FinanceAuthWrapper extends StatelessWidget {
  const _FinanceAuthWrapper();

  @override
  Widget build(BuildContext context) {
    final bootstrapper = context.read<FirebaseBootstrapper>();
    final permissionService = context.read<PermissionService>();
    return StreamBuilder<User?>(
      stream: bootstrapper.auth.authStateChanges(),
      initialData: bootstrapper.auth.currentUser,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return SessionAuthGate(
          user: user,
          bootstrapper: bootstrapper,
          permissionService: permissionService,
          child: const AssetPreloaderWidget(child: FinancePortalShell()),
        );
      },
    );
  }
}

// ── Finance router — finance-accessible routes only ──────────────────────────

class _FinanceRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const FinancePortalShell());
      case '/items':
        return MaterialPageRoute(builder: (_) => const ItemsScreen());
      case '/items/details':
        final args = settings.arguments;
        if (args is ItemDetailArgs) {
          return MaterialPageRoute(
            builder: (_) => FinanceEditItemScreen(item: args.item),
          );
        }
        return _error('Missing item for details');
      case '/reports':
        return _guarded(
          builder: (_) => const ReportsHubScreen(),
          permission: 'view_reports',
        );
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      default:
        return _error('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _guarded({
    required Widget Function(BuildContext) builder,
    required String permission,
  }) =>
      MaterialPageRoute(
        builder: (ctx) => PermissionGuardWrapper(
          permission: permission,
          child: builder(ctx),
        ),
      );

  static MaterialPageRoute _error(String msg) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Not found')),
          body: Center(child: Text(msg)),
        ),
      );
}

class ItemDetailArgs {
  const ItemDetailArgs({required this.item});
  final InventoryItem item;
}
