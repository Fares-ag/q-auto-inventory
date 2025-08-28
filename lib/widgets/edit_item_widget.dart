// lib/widgets/edit_item_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'dart:io';

class EditItemWidget extends StatefulWidget {
  final ItemModel item;
  final Function(ItemModel) onSave;
  final VoidCallback? onClose;

  const EditItemWidget({
    Key? key,
    required this.item,
    required this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  _EditItemWidgetState createState() => _EditItemWidgetState();
}

class _EditItemWidgetState extends State<EditItemWidget> {
  final _formKey = GlobalKey<FormState>();

  // --- Standard Field Controllers ---
  late TextEditingController _idController;
  late TextEditingController _descriptionController;
  late TextEditingController _variantsController;
  late TextEditingController _supplierController;
  late TextEditingController _companyController;
  late TextEditingController _ownerController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _coCdController;
  late TextEditingController _sapClassController;
  late TextEditingController _apcAcctController;
  late TextEditingController _licPlateController;
  late TextEditingController _plntController;
  late TextEditingController _modelCodeController;
  late TextEditingController _modelDescController;
  late TextEditingController _modelYearController;
  late TextEditingController _assetTypeController;
  late TextEditingController _locationController;

  // --- State Variables ---
  DateTime? _purchaseDate;
  bool _isLoading = false;
  String? _selectedAssetClassDesc;
  String? _selectedDepartment;
  String? _selectedCategory;

  bool get _isVehicle => _selectedAssetClassDesc?.contains('Vehicle') ?? false;

  @override
  void initState() {
    super.initState();
    // Pre-populate all fields from the existing item data
    _idController = TextEditingController(text: widget.item.id);
    _descriptionController = TextEditingController(text: widget.item.name);
    _variantsController = TextEditingController(text: widget.item.variants);
    _supplierController = TextEditingController(text: widget.item.supplier);
    _companyController = TextEditingController(text: widget.item.company);
    _ownerController = TextEditingController(text: widget.item.owner ?? '');
    _purchasePriceController = TextEditingController(
        text: widget.item.purchasePrice?.toString() ?? '');
    _coCdController = TextEditingController(text: widget.item.coCd ?? '');
    _sapClassController =
        TextEditingController(text: widget.item.sapClass ?? '');
    _apcAcctController = TextEditingController(text: widget.item.apcAcct ?? '');
    _licPlateController =
        TextEditingController(text: widget.item.licPlate ?? '');
    _plntController = TextEditingController(text: widget.item.plnt ?? '');
    _modelCodeController =
        TextEditingController(text: widget.item.modelCode ?? '');
    _modelDescController =
        TextEditingController(text: widget.item.modelDesc ?? '');
    _modelYearController =
        TextEditingController(text: widget.item.modelYear ?? '');
    _assetTypeController =
        TextEditingController(text: widget.item.assetType ?? '');
    _locationController =
        TextEditingController(text: widget.item.location ?? '');
    _purchaseDate = widget.item.purchaseDate;
    _selectedAssetClassDesc = widget.item.assetClassDesc;
    _selectedDepartment = widget.item.department;
    _selectedCategory = widget.item.category;
  }

  @override
  void dispose() {
    _idController.dispose();
    _descriptionController.dispose();
    _variantsController.dispose();
    _supplierController.dispose();
    _companyController.dispose();
    _ownerController.dispose();
    _purchasePriceController.dispose();
    _coCdController.dispose();
    _sapClassController.dispose();
    _apcAcctController.dispose();
    _licPlateController.dispose();
    _plntController.dispose();
    _modelCodeController.dispose();
    _modelDescController.dispose();
    _modelYearController.dispose();
    _assetTypeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedItem = widget.item.copyWith(
      name: _descriptionController.text.trim(),
      category: _selectedCategory,
      purchaseDate: _purchaseDate,
      variants: _variantsController.text.trim(),
      supplier: _supplierController.text.trim(),
      company: _companyController.text.trim(),
      department: _selectedDepartment,
      assignedStaff: _ownerController.text.trim(),
      purchasePrice: double.tryParse(_purchasePriceController.text.trim()),
      licPlate: _isVehicle ? _licPlateController.text.trim() : null,
      plnt: _plntController.text.trim(),
      modelCode: _modelCodeController.text.trim(),
      modelDesc: _modelDescController.text.trim(),
      modelYear: _modelYearController.text.trim(),
      assetType: _assetTypeController.text.trim(),
      owner: _ownerController.text.trim(),
      vehicleIdNo: _isVehicle ? _idController.text.trim() : null,
      vehicleModel: _isVehicle ? _modelDescController.text.trim() : null,
      location: _locationController.text.trim(),
      customFields: {}, // Custom fields are removed
    );

    widget.onSave(updatedItem);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    final activeDepartments =
        dataStore.departments.where((d) => d.isActive).toList();
    final allCategories =
        dataStore.categories.where((c) => c.isActive).toList();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Edit Item'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(_idController, 'Asset No.',
                          isReadOnly: true),
                      const SizedBox(height: 20),
                      _buildTextField(_descriptionController, 'Description',
                          isRequired: true),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: _buildInputDecoration('Category'),
                        items: allCategories.map((Category cat) {
                          return DropdownMenuItem<String>(
                            value: cat.name,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: _buildInputDecoration('Department'),
                        items: activeDepartments.map((Department dept) {
                          return DropdownMenuItem<String>(
                            value: dept.name,
                            child: Text(dept.name),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDepartment = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a department' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(_ownerController, 'Owner'),
                      const SizedBox(height: 20),
                      _buildTextField(_supplierController, 'Supplier Name',
                          isRequired: true),
                      const SizedBox(height: 20),
                      _buildTextField(_plntController, 'Plnt',
                          isRequired: true),
                      const SizedBox(height: 20),
                      _buildTextField(_locationController, 'Location',
                          isRequired: true),
                      const SizedBox(height: 20),
                      if (_isVehicle) ...[
                        _buildTextField(_licPlateController, 'LIC Plate'),
                        const SizedBox(height: 20),
                        _buildTextField(_modelCodeController, 'Model Code'),
                        const SizedBox(height: 20),
                        _buildTextField(
                            _modelDescController, 'Model Description'),
                        const SizedBox(height: 20),
                        _buildTextField(_modelYearController, 'Model Year'),
                        const SizedBox(height: 20),
                        _buildTextField(_assetTypeController, 'Asset Type'),
                      ],
                      const SizedBox(height: 20),
                      _buildTextField(
                          _purchasePriceController, 'Purchase Price (Optional)',
                          isNumeric: true, isRequired: false),
                      const SizedBox(height: 20),
                      _buildDatePicker(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isNumeric = false,
      bool isRequired = true,
      bool isReadOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: _buildInputDecoration(hint).copyWith(
        fillColor: isReadOnly ? Colors.grey[200] : Colors.white,
      ),
      validator: (value) =>
          (value == null || value.trim().isEmpty) && isRequired
              ? 'This field is required'
              : null,
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickPurchaseDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _purchaseDate == null
                  ? 'Select Purchase Date*'
                  : 'Date: ${_purchaseDate!.toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                  fontSize: 16,
                  color:
                      _purchaseDate == null ? Colors.grey[600] : Colors.black),
            ),
            Icon(Icons.calendar_today_outlined, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
