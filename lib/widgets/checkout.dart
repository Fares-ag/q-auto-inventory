// lib/widgets/checkout.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:provider/provider.dart';
import 'add_user_dialog.dart';

class CheckoutWidget extends StatefulWidget {
  final String itemDepartment;
  // FIXED: The onSave callback now passes Uint8List?
  final Function(String assignTo, Uint8List? assigneeSignature,
      Uint8List? operatorSignature) onSave;
  final VoidCallback? onClose;

  const CheckoutWidget({
    Key? key,
    required this.itemDepartment,
    required this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  State<CheckoutWidget> createState() => _CheckoutWidgetState();
}

class _CheckoutWidgetState extends State<CheckoutWidget> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<SignatureState> _assigneeSignatureKey =
      GlobalKey<SignatureState>();
  final GlobalKey<SignatureState> _operatorSignatureKey =
      GlobalKey<SignatureState>();

  LocalUser? _selectedUser;
  bool _isLoading = false;

  void _saveCheckout() async {
    if (!_formKey.currentState!.validate() || _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a user to assign the item to.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final assigneeSignaturePad = _assigneeSignatureKey.currentState;
      final operatorSignaturePad = _operatorSignatureKey.currentState;

      if (assigneeSignaturePad == null ||
          assigneeSignaturePad.points.isEmpty ||
          operatorSignaturePad == null ||
          operatorSignaturePad.points.isEmpty) {
        throw 'Both signatures are required.';
      }

      final ui.Image assigneeImage = await assigneeSignaturePad.getData();
      final ByteData? assigneeByteData =
          await assigneeImage.toByteData(format: ui.ImageByteFormat.png);

      final ui.Image operatorImage = await operatorSignaturePad.getData();
      final ByteData? operatorByteData =
          await operatorImage.toByteData(format: ui.ImageByteFormat.png);

      // FIXED: Pass the signature data as Uint8List
      widget.onSave(
        _selectedUser!.email,
        assigneeByteData?.buffer.asUint8List(),
        operatorByteData?.buffer.asUint8List(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _addNewUser(LocalUser newUser) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    dataStore.addUser(newUser);
    setState(() {
      _selectedUser = newUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context);
    final departmentUsers = dataStore.users
        .where((user) => user.department == widget.itemDepartment)
        .toList();
    final allDepartments =
        dataStore.departments.where((d) => d.isActive).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Checkout Item',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose),
                    ],
                  ),
                  const SizedBox(height: 30),
                  DropdownButtonFormField<LocalUser>(
                    value: _selectedUser,
                    decoration: const InputDecoration(
                      labelText: 'Assign To',
                      border: OutlineInputBorder(),
                    ),
                    items: departmentUsers.map((LocalUser user) {
                      return DropdownMenuItem<LocalUser>(
                        value: user,
                        child: Text(user.name),
                      );
                    }).toList(),
                    onChanged: (LocalUser? newValue) {
                      setState(() {
                        _selectedUser = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a user' : null,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add New User'),
                      onPressed: () {
                        showAddUserDialog(context, allDepartments, _addNewUser);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Assignee Signature',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  _buildSignaturePad(_assigneeSignatureKey),
                  const SizedBox(height: 20),
                  const Text('Operator Signature',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  _buildSignaturePad(_operatorSignatureKey),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _saveCheckout,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Confirm Checkout',
                              style: TextStyle(fontSize: 18)),
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

  Widget _buildSignaturePad(GlobalKey<SignatureState> key) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Signature(key: key, strokeWidth: 3.0),
    );
  }
}
