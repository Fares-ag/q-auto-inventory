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
import 'package:q_auto_inventory/screens/admin/super_admin_dashboard_screen.dart';
import 'package:q_auto_inventory/screens/admin/admin_dashboard_screen.dart';
import 'package:q_auto_inventory/screens/admin/analytics_screen.dart';
import 'package:q_auto_inventory/screens/admin/category_management_screen.dart';
import 'package:q_auto_inventory/screens/admin/data_audit_screen.dart';
import 'package:q_auto_inventory/screens/admin/department_management_screen.dart';
import 'package:q_auto_inventory/screens/admin/excel_import_screen.dart';
import 'package:q_auto_inventory/screens/admin/locations_management_screen.dart';
import 'package:q_auto_inventory/screens/admin/permission_manager_screen.dart';
import 'package:q_auto_inventory/screens/admin/staff_management_screen.dart';
import 'package:q_auto_inventory/screens/admin/system_settings_screen.dart';
import 'package:q_auto_inventory/screens/admin/user_management_screen.dart';
import 'package:q_auto_inventory/screens/admin/vehicle_checkinout_screen.dart';
import 'package:q_auto_inventory/screens/admin/vehicle_maintenance_screen.dart';
import 'package:q_auto_inventory/screens/approvals/approval_queue_screen.dart';
import 'package:q_auto_inventory/screens/items/items_screen.dart';
import 'package:q_auto_inventory/screens/items/item_detail_screen.dart';
import 'package:q_auto_inventory/screens/items/add_item_screen.dart';
import 'package:q_auto_inventory/screens/items/edit_item_screen.dart';
import 'package:q_auto_inventory/screens/qr/bulk_qr_print_screen.dart';
import 'package:q_auto_inventory/screens/reports/reports_hub_screen.dart';
import 'package:q_auto_inventory/screens/settings/settings_screen.dart';
import 'package:q_auto_inventory/widgets/asset_preloader_widget.dart';
import 'package:q_auto_inventory/widgets/session_auth_gate.dart';

class SuperAdminApp extends StatelessWidget {
  const SuperAdminApp({super.key, required this.bootstrapper});

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
        title: 'Inventory — Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        home: const _SuperAdminAuthWrapper(),
        onGenerateRoute: _SuperAdminRouter.onGenerateRoute,
      ),
    );
  }
}

// ── Auth wrapper ─────────────────────────────────────────────────────────────

class _SuperAdminAuthWrapper extends StatelessWidget {
  const _SuperAdminAuthWrapper();

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
          child: const AssetPreloaderWidget(
            child: SuperAdminDashboardScreen(),
          ),
        );
      },
    );
  }
}

// ── Super-admin router — full access ─────────────────────────────────────────

class _SuperAdminRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
            builder: (_) => const SuperAdminDashboardScreen());
      case '/admin':
        return _guarded(
          builder: (_) => const AdminDashboardScreen(),
          permission: 'manage_items',
        );
      case '/admin/super':
        return _guarded(
          builder: (_) => const SuperAdminDashboardScreen(),
          permission: 'admin',
        );
      case '/admin/analytics':
        return _guarded(
          builder: (_) => const AnalyticsScreen(),
          permission: 'admin',
        );
      case '/admin/categories':
        return _guarded(
          builder: (_) => const CategoryManagementScreen(),
          permission: 'manage_items',
        );
      case '/admin/data-audit':
        return _guarded(
          builder: (_) => const DataAuditScreen(),
          permission: 'admin',
        );
      case '/admin/departments':
        return _guarded(
          builder: (_) => const DepartmentManagementScreen(),
          permission: 'manage_departments',
        );
      case '/admin/import':
        return _guarded(
          builder: (_) => const ExcelImportScreen(),
          permission: 'manage_items',
        );
      case '/admin/locations':
        return _guarded(
          builder: (_) => const LocationsManagementScreen(),
          permission: 'manage_departments',
        );
      case '/admin/permissions':
        return _guarded(
          builder: (_) => const PermissionManagerScreen(),
          permission: 'admin',
        );
      case '/admin/staff':
        return _guarded(
          builder: (_) => const StaffManagementScreen(),
          permission: 'manage_staff',
        );
      case '/admin/system-settings':
        return _guarded(
          builder: (_) => const SystemSettingsScreen(),
          permission: 'admin',
        );
      case '/admin/users':
        return _guarded(
          builder: (_) => const UserManagementScreen(),
          permission: 'admin',
        );
      case '/admin/vehicle-checkouts':
        return _guarded(
          builder: (_) => const VehicleCheckInOutScreen(),
          permission: 'admin',
        );
      case '/admin/vehicle-maintenance':
        return _guarded(
          builder: (_) => const VehicleMaintenanceScreen(),
          permission: 'admin',
        );
      case '/approvals':
        return _guarded(
          builder: (_) => const ApprovalQueueScreen(),
          permission: 'manage_items',
        );
      case '/items':
        return MaterialPageRoute(builder: (_) => const ItemsScreen());
      case '/items/add':
        return _guarded(
          builder: (_) => const AddItemScreen(),
          permission: 'manage_items',
        );
      case '/items/edit':
        final args = settings.arguments as Map<String, dynamic>?;
        final item = args?['item'] as InventoryItem?;
        if (item != null) {
          return MaterialPageRoute(
              builder: (_) => EditItemScreen(item: item));
        }
        return _error('Missing item for edit');
      case '/items/details':
        final args = settings.arguments;
        if (args is ItemDetailArgs) {
          return MaterialPageRoute(
            builder: (_) => ItemDetailScreen(item: args.item),
          );
        }
        return _error('Missing item for details');
      case BulkQrPrintScreen.routeName:
        return MaterialPageRoute(builder: (_) => const BulkQrPrintScreen());
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
