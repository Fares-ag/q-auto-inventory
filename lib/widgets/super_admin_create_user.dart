// lib/widgets/super_admin_create_user.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
// FIXED: Corrected the typo in the provider import statement
import 'package:provider/provider.dart';

class SuperAdminCreateUser extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  const SuperAdminCreateUser({Key? key, required this.onSave})
      : super(key: key);

  @override
  State<SuperAdminCreateUser> createState() => _SuperAdminCreateUserState();
}

class _SuperAdminCreateUserState extends State<SuperAdminCreateUser> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'operator';
  String? _selectedDepartment;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await Future.delayed(const Duration(seconds: 1));

    final newUser = {
      'uid': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'department': _selectedDepartment,
    };

    widget.onSave(newUser);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create New User'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Enter user details:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter an email' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) => value!.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(
                        value: 'operator', child: Text('Operator')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                        value: 'superAdmin', child: Text('Super Admin')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedRole = newValue);
                    }
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  value: _selectedDepartment,
                  items: dataStore.departments
                      .where((d) => d.isActive)
                      .map((dept) {
                    return DropdownMenuItem(
                        value: dept.name, child: Text(dept.name));
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedDepartment = newValue);
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select a department' : null,
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(_errorMessage,
                        style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create User',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
