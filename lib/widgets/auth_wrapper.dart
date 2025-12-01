import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/widgets/root_screen.dart';
import 'package:flutter_application_1/widgets/super_admin_screen.dart';

/// Wrapper widget that checks authentication state
/// Shows login screen if not authenticated, RootScreen if authenticated
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if Firebase is initialized
    try {
      // Try to access Firebase - if it fails, show error
      final auth = FirebaseService.auth;
      
      return StreamBuilder(
        stream: auth.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // If user is logged in, decide between Super Admin and normal app
          if (snapshot.hasData && FirebaseService.currentUser != null) {
            return FutureBuilder<bool>(
              future: AdminService.isCurrentUserAdmin(),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final isAdmin = adminSnapshot.data ?? false;
                if (isAdmin) {
                  return const SuperAdminScreen();
                }

                return const RootScreen();
              },
            );
          }

          // If user is not logged in, show login screen
          return const LoginScreen();
        },
      );
    } catch (e) {
      // Firebase not initialized - show error screen
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Not Configured',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'For web, please add your Firebase web app configuration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Text(
                  'To fix this:\n1. Go to Firebase Console\n2. Add a web app\n3. Copy the config\n4. Update lib/firebase_options.dart',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

