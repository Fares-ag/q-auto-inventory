// lib/widgets/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/widgets/root_screen.dart';
import 'package:flutter_application_1/widgets/super_admin_dashboard.dart';
import 'package:flutter_application_1/widgets/admin_dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _signIn() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate a network call and login check
    Future.delayed(const Duration(seconds: 1), () {
      final dataStore = Provider.of<LocalDataStore>(context, listen: false);

      // Find the user in our local data store
      final user = dataStore.users.firstWhere(
        (user) => user.email == _email,
        // Return a fallback user with an 'unknown' role if not found
        orElse: () => LocalUser(
            id: '',
            name: 'Unknown',
            email: '',
            roleId: 'unknown',
            department: ''),
      );

      if (user.roleId == 'unknown' || !user.isActive) {
        // User not found or is inactive
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Invalid email or password'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Switch the current user in the data store
      dataStore.switchUser(user);

      // Navigate based on the user's role
      if (user.roleId == 'superAdmin') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: dataStore,
            child: const SuperAdminDashboard(),
          ),
        ));
      } else if (user.roleId == 'admin') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: dataStore,
            child: AdminDashboardScreen(
              userDepartment: user.department,
              onUpdateItem: dataStore.updateItem,
            ),
          ),
        ));
      } else {
        // This handles the 'operator' role
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const RootScreen(),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/Q-AutoLogo.svg',
                    height: 80,
                    width: 80,
                    placeholderBuilder: (context) => Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: theme.primaryColor),
                  ),
                  const SizedBox(height: 24),
                  Text('Asset Management Portal',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 48.0),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                          Icon(Icons.email_outlined, color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val!.isEmpty || !val.contains('@')
                        ? 'Enter a valid email'
                        : null,
                    onChanged: (val) => setState(() => _email = val.trim()),
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon:
                          Icon(Icons.lock_outline, color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    obscureText: true,
                    validator: (val) => val!.length < 6
                        ? 'Password must be 6+ characters'
                        : null,
                    onChanged: (val) => setState(() => _password = val),
                  ),
                  const SizedBox(height: 32.0),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('Sign In',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
