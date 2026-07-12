import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/auth_session_service.dart';
import '../services/firebase_services.dart';
import '../services/permission_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/root_shell.dart';
import '../screens/admin/super_admin_dashboard_screen.dart';
import '../screens/finance/finance_portal_shell.dart';
import 'asset_preloader_widget.dart';
import 'session_auth_gate.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final bootstrapper = context.read<FirebaseBootstrapper>();
    final permissionService = context.read<PermissionService>();

    return StreamBuilder<User?>(
      stream: bootstrapper.auth.authStateChanges(),
      initialData: bootstrapper.auth.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return SessionAuthGate(
          user: user,
          bootstrapper: bootstrapper,
          permissionService: permissionService,
          child: AssetPreloaderWidget(
            child: _PermissionAwareShell(
              userId: user.uid,
              permissionService: permissionService,
              bootstrapper: bootstrapper,
            ),
          ),
        );
      },
    );
  }
}

/// Shows UI immediately and updates when permissions load (non-blocking).
class _PermissionAwareShell extends StatefulWidget {
  const _PermissionAwareShell({
    required this.userId,
    required this.permissionService,
    required this.bootstrapper,
  });

  final String userId;
  final PermissionService permissionService;
  final FirebaseBootstrapper bootstrapper;

  @override
  State<_PermissionAwareShell> createState() => _PermissionAwareShellState();
}

class _PermissionAwareShellState extends State<_PermissionAwareShell> {
  Widget? _cachedShell;

  @override
  void initState() {
    super.initState();
    _cachedShell = const RootShell();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final userDoc = await widget.bootstrapper.firestore
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && isUserRecordDisabled(userDoc.data())) {
        await signOutAndClearSession(
          auth: widget.bootstrapper.auth,
          permissionService: widget.permissionService,
        );
        return;
      }

      final permissions =
          await widget.permissionService.getUserPermissions(widget.userId);
      if (!mounted) return;

      final isAdmin =
          widget.permissionService.hasPermission(permissions, 'admin');
      final isFinance =
          widget.permissionService.hasPermission(permissions, 'finance');

      if (mounted) {
        setState(() {
          if (isAdmin) {
            _cachedShell = const SuperAdminDashboardScreen();
          } else if (isFinance) {
            _cachedShell = const FinancePortalShell();
          }
        });
      }
    } catch (e) {
      debugPrint('Permission load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _cachedShell ?? const RootShell();
  }
}
