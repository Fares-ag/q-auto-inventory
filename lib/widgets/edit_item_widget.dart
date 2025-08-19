import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'dart:io';

/// Widget for editing an existing item.
/// Supports updating various fields including purchase info, asset class, and vehicle-specific fields.
class EditItemWidget extends StatefulWidget {
  final ItemModel item; // Item to edit
  final Function(ItemModel) onSave; // Callback when saving changes
  final VoidCallback? onClose; // Optional callback when closing the widget

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
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  // Controllers for all editable fields
  final _idController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _variantsController = TextEditingController();
  final _supplierController = TextEditingController();
  final _companyController = TextEditingController();
  final _departmentController = TextEditingController();
  final _ownerController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _coCdController = TextEditingController();
  final _sapClassController = TextEditingController();
  final _apcAcctController = TextEditingController();
  final _licPlateController = TextEditingController();
  final _plntController = TextEditingController();
  final _modelCodeController = TextEditingController();
  final _modelDescController = TextEditingController();
  final _modelYearController = TextEditingController();
  final _assetTypeController = TextEditingController();

  DateTime? _purchaseDate; // Selected purchase date
  bool _isLoading = false; // Loading state while saving

  String? _selectedAssetClassDesc; // Currently selected asset class
  bool get _isVehicle =>
      _selectedAssetClassDesc?.contains('Vehicle') ??
      false; // Checks if the asset is a vehicle

  // List of asset classes for the dropdown
  final List<String> _assetClasses = [
    'Office Equipment',
    'Company Vehicle (Own Used)',
    'Furniture and Fixtures- Office High Value',
    'IT Hardware',
    'Machinery(Own Used) - High Value',
  ];

  // Default associations for each asset class
  final Map<String, Map<String, String>> _assetClassAssociations = {
    'Office Equipment': {'CoCD': '8000', 'Class': '2600', 'APC acct': '110170'},
    'Company Vehicle (Own Used)': {
      'CoCD': '8200',
      'Class': '2400',
      'APC acct': '110150'
    },
    'Furniture and Fixtures- Office High Value': {
      'CoCD': '8000',
      'Class': '3000',
      'APC acct': '110210'
    },
    'IT Hardware': {'CoCD': '8000', 'Class': '3400', 'APC acct': '110250'},
    'Machinery(Own Used) - High Value': {
      'CoCD': '8000',
      'Class': '2000',
      'APC acct': '110110'
    },
  };

  /// Updates dependent fields (CoCD, Class, APC acct) when asset class changes
  void _onAssetClassChanged(String? newValue) {
    if (newValue != null) {
      final associations = _assetClassAssociations[newValue];
      if (associations != null) {
        _coCdController.text = associations['CoCD'] ?? '';
        _sapClassController.text = associations['Class'] ?? '';
        _apcAcctController.text = associations['APC acct'] ?? '';
      }
    }
    setState(() {
      _selectedAssetClassDesc = newValue;
    });
  }

  @override
  void initState() {
    super.initState();
    // Pre-populate all text fields and selections with existing item data
    _idController.text = widget.item.id;
    _descriptionController.text = widget.item.name;
    _categoryController.text = widget.item.category;
    _variantsController.text = widget.item.variants;
    _supplierController.text = widget.item.supplier;
    _companyController.text = widget.item.company;
    _departmentController.text = widget.item.department ?? '';
    _ownerController.text = widget.item.assignedStaff ?? '';
    _purchasePriceController.text = widget.item.purchasePrice?.toString() ?? '';
    _coCdController.text = widget.item.coCd ?? '';
    _sapClassController.text = widget.item.sapClass ?? '';
    _apcAcctController.text = widget.item.apcAcct ?? '';
    _licPlateController.text = widget.item.licPlate ?? '';
    _plntController.text = widget.item.plnt ?? '';
    _modelCodeController.text = widget.item.modelCode ?? '';
    _modelDescController.text = widget.item.modelDesc ?? '';
    _modelYearController.text = widget.item.modelYear ?? '';
    _assetTypeController.text = widget.item.assetType ?? '';
    _purchaseDate = widget.item.purchaseDate;
    _selectedAssetClassDesc = widget.item.assetClassDesc;
  }

  @override
  void dispose() {
    // Dispose all controllers to free resources
    _idController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _variantsController.dispose();
    _supplierController.dispose();
    _companyController.dispose();
    _departmentController.dispose();
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
    super.dispose();
  }

  /// Opens a date picker to select purchase date
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

  /// Validates form and saves updated item
  void _saveItem() {
    if (!_formKey.currentState!.validate() || _purchaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Please fill all required fields, including purchase date.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    // Create updated copy of the item
    final updatedItem = widget.item.copyWith(
      name: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      purchaseDate: _purchaseDate!,
      variants: _variantsController.text.trim(),
      supplier: _supplierController.text.trim(),
      company: _companyController.text.trim(),
      department: _departmentController.text.trim(),
      assignedStaff: _ownerController.text.trim(),
      purchasePrice: double.tryParse(_purchasePriceController.text.trim()),
      assetClassDesc: _selectedAssetClassDesc,
      coCd: _coCdController.text.trim(),
      sapClass: _sapClassController.text.trim(),
      apcAcct: _apcAcctController.text.trim(),
      licPlate: _isVehicle ? _licPlateController.text.trim() : null,
      plnt: _plntController.text.trim(),
      modelCode: _modelCodeController.text.trim(),
      modelDesc: _modelDescController.text.trim(),
      modelYear: _modelYearController.text.trim(),
      assetType: _assetTypeController.text.trim(),
      owner: _ownerController.text.trim(),
      vehicleIdNo: _isVehicle ? _idController.text.trim() : null,
      vehicleModel: _isVehicle ? _modelDescController.text.trim() : null,
    );

    widget.onSave(updatedItem); // Trigger callback to save changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Item'),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: widget.onClose),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Read-only asset number field
                      _buildTextField(_idController, 'Asset No.',
                          isReadOnly: true),
                      const SizedBox(height: 20),

                      // Dropdown for selecting asset class
                      _buildAssetClassDropdown(isReadOnly: true),
                      const SizedBox(height: 20),

                      // Pre-populated read-only fields for accounting info
                      _buildTextField(_coCdController, 'CoCD',
                          isReadOnly: true),
                      const SizedBox(height: 20),
                      _buildTextField(_sapClassController, 'Class',
                          isReadOnly: true),
                      const SizedBox(height: 20),
                      _buildTextField(_apcAcctController, 'APC acct',
                          isReadOnly: true),
                      const SizedBox(height: 20),

                      // Editable description and owner fields
                      _buildTextField(_descriptionController, 'Description',
                          isRequired: true),
                      const SizedBox(height: 20),
                      _buildTextField(_ownerController, 'Owner',
                          isRequired: false),
                      const SizedBox(height: 20),

                      // Supplier and plant info
                      _buildTextField(_supplierController, 'Supplier Name',
                          isRequired: true),
                      const SizedBox(height: 20),
                      _buildTextField(_plntController, 'Plnt',
                          isRequired: true),
                      const SizedBox(height: 20),

                      // Vehicle-specific fields
                      if (_isVehicle) ...[
                        _buildTextField(_licPlateController, 'LIC Plate',
                            isRequired: false),
                        const SizedBox(height: 20),
                        _buildTextField(_modelCodeController, 'Model Code',
                            isRequired: false),
                        const SizedBox(height: 20),
                        _buildTextField(
                            _modelDescController, 'Model Description',
                            isRequired: false),
                        const SizedBox(height: 20),
                        _buildTextField(_modelYearController, 'Model Year',
                            isRequired: false),
                        const SizedBox(height: 20),
                        _buildTextField(_assetTypeController, 'Asset Type',
                            isRequired: false),
                      ] else ...[
                        // Non-vehicle fields
                        _buildTextField(_categoryController, 'Category',
                            isRequired: true),
                        const SizedBox(height: 20),
                        _buildTextField(_variantsController, 'Vehicle Model',
                            isRequired: false),
                      ],

                      // Purchase price and date
                      const SizedBox(height: 20),
                      _buildTextField(
                          _purchasePriceController, 'Purchase Price (Optional)',
                          isNumeric: true, isRequired: false),
                      const SizedBox(height: 20),
                      _buildDatePicker(),
                    ],
                  ),
                ),
              ),
            ),

            // Save button at the bottom
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
                        borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)))
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

  /// Builds the dropdown for asset class selection
  Widget _buildAssetClassDropdown({bool isReadOnly = false}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Asset Class',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isReadOnly ? Colors.grey[200] : Colors.grey[50],
      ),
      value: _selectedAssetClassDesc,
      items: _assetClasses.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: isReadOnly ? null : _onAssetClassChanged,
      validator: (value) => value == null ? 'This field is required' : null,
    );
  }

  /// Builds a reusable text field
  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isNumeric = false,
      bool isRequired = true,
      bool isReadOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isReadOnly ? Colors.grey[200] : Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) =>
          (value == null || value.trim().isEmpty) && isRequired
              ? 'This field is required'
              : null,
    );
  }

  /// Builds the purchase date picker widget
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickPurchaseDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
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
