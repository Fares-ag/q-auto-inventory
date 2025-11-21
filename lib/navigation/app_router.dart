import 'package:flutter/material.dart';

import '../models/firestore_models.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/category_management_screen.dart';
import '../screens/admin/department_management_screen.dart';
import '../screens/admin/permission_manager_screen.dart';
import '../screens/admin/staff_management_screen.dart';
import '../screens/admin/excel_import_screen.dart';
import '../screens/admin/super_admin_dashboard_screen.dart';
import '../screens/admin/data_audit_screen.dart';
import '../screens/admin/locations_management_screen.dart';
import '../screens/admin/system_settings_screen.dart';
import '../screens/admin/vehicle_checkinout_screen.dart';
import '../screens/admin/vehicle_maintenance_screen.dart';
import '../screens/approvals/approval_queue_screen.dart';
import '../screens/home/root_shell.dart';
import '../screens/items/add_item_screen.dart';
import '../screens/items/item_detail_screen.dart';
import '../screens/items/items_screen.dart';
import '../screens/qr/bulk_qr_print_screen.dart';
import '../screens/reports/reports_hub_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'permission_guard_wrapper.dart';

class AppRouter {
  static const String initialRoute = '/';
  static const String itemsRoute = '/items';
  static const String itemDetailsRoute = '/items/details';
  static const String addItemRoute = '/items/add';
  static const String adminRoute = '/admin';
  static const String approvalsRoute = '/approvals';
  static const String superAdminRoute = '/admin/super';
  static const String departmentManagementRoute = '/admin/departments';
  static const String categoryManagementRoute = '/admin/categories';
  static const String permissionManagerRoute = '/admin/permissions';
  static const String staffManagementRoute = '/admin/staff';
  static const String reportsRoute = '/reports';
  static const String bulkQrRoute = BulkQrPrintScreen.routeName;
  static const String loginRoute = '/login';
  static const String excelImportRoute = '/admin/import';
  static const String dataAuditRoute = '/admin/data-audit';
  static const String locationsRoute = '/admin/locations';
  static const String systemSettingsRoute = '/admin/system-settings';
  static const String vehicleCheckInOutRoute = '/admin/vehicle-checkouts';
  static const String vehicleMaintenanceRoute = '/admin/vehicle-maintenance';
  static const String settingsRoute = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
        return MaterialPageRoute(builder: (_) => const RootShell());
      case itemsRoute:
        return MaterialPageRoute(builder: (_) => const ItemsScreen());
      case addItemRoute:
        return MaterialPageRoute(builder: (_) => const AddItemScreen());
      case adminRoute:
        return _guardedRoute(
          builder: (_) => const AdminDashboardScreen(),
          permission: 'manage_items',
        );
      case approvalsRoute:
        return _guardedRoute(
          builder: (_) => const ApprovalQueueScreen(),
          permission: 'manage_items',
        );
      case superAdminRoute:
        return _guardedRoute(
          builder: (_) => const SuperAdminDashboardScreen(),
          permission: 'admin',
        );
      case dataAuditRoute:
        return _guardedRoute(
          builder: (_) => const DataAuditScreen(),
          permission: 'admin',
        );
      case locationsRoute:
        return _guardedRoute(
          builder: (_) => const LocationsManagementScreen(),
          permission: 'manage_departments',
        );
      case systemSettingsRoute:
        return _guardedRoute(
          builder: (_) => const SystemSettingsScreen(),
          permission: 'admin',
        );
      case vehicleCheckInOutRoute:
        return _guardedRoute(
          builder: (_) => const VehicleCheckInOutScreen(),
          permission: 'admin',
        );
      case vehicleMaintenanceRoute:
        return _guardedRoute(
          builder: (_) => const VehicleMaintenanceScreen(),
          permission: 'admin',
        );
      case departmentManagementRoute:
        return _guardedRoute(
          builder: (_) => const DepartmentManagementScreen(),
          permission: 'manage_departments',
        );
      case categoryManagementRoute:
        return _guardedRoute(
          builder: (_) => const CategoryManagementScreen(),
          permission: 'manage_items',
        );
      case permissionManagerRoute:
        return _guardedRoute(
          builder: (_) => const PermissionManagerScreen(),
          permission: 'admin',
        );
      case staffManagementRoute:
        return _guardedRoute(
          builder: (_) => const StaffManagementScreen(),
          permission: 'manage_staff',
        );
      case reportsRoute:
        return _guardedRoute(
          builder: (_) => const ReportsHubScreen(),
          permission: 'view_reports',
        );
      case excelImportRoute:
        return _guardedRoute(
          builder: (_) => const ExcelImportScreen(),
          permission: 'manage_items',
        );
      case bulkQrRoute:
        return MaterialPageRoute(builder: (_) => const BulkQrPrintScreen());
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case itemDetailsRoute:
        final args = settings.arguments;
        if (args is ItemDetailArgs) {
          return MaterialPageRoute(
            builder: (_) => ItemDetailScreen(item: args.item),
          );
        }
        return _errorRoute('Missing item for details route');
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _guardedRoute({
    required Widget Function(BuildContext) builder,
    required String permission,
  }) {
    return MaterialPageRoute(
      builder: (context) => PermissionGuardWrapper(
        permission: permission,
        child: builder(context),
      ),
    );
  }

  static MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(child: Text(message)),
      ),
    );
  }
}

class ItemDetailArgs {
  const ItemDetailArgs({required this.item});

  final InventoryItem item;
}
