import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../services/auth_session_service.dart';
import '../services/firebase_services.dart';
import '../services/permission_service.dart';

class SessionAuthGate extends StatelessWidget {
  const SessionAuthGate({
    super.key,
    required this.user,
    required this.bootstrapper,
    required this.permissionService,
    required this.child,
  });

  final User user;
  final FirebaseBootstrapper bootstrapper;
  final PermissionService permissionService;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (user.isAnonymous) {
      return _AnonymousRedirect(
        bootstrapper: bootstrapper,
        permissionService: permissionService,
      );
    }
    return child;
  }
}

class _AnonymousRedirect extends StatefulWidget {
  const _AnonymousRedirect({
    required this.bootstrapper,
    required this.permissionService,
  });

  final FirebaseBootstrapper bootstrapper;
  final PermissionService permissionService;

  @override
  State<_AnonymousRedirect> createState() => _AnonymousRedirectState();
}

class _AnonymousRedirectState extends State<_AnonymousRedirect> {
  @override
  void initState() {
    super.initState();
    signOutAndClearSession(
      auth: widget.bootstrapper.auth,
      permissionService: widget.permissionService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
