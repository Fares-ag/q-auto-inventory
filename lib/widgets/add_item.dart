// lib/widgets/add_item.dart

// Import Flutter's material library for UI components.
import 'package:flutter/material.dart';
// Import the data model for an inventory item.
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/qr_code_service.dart';
import 'dart:io';

/// A StatefulWidget that provides a form for adding a new inventory item.
class AddItemWidget extends StatefulWidget {
  // A callback function that is triggered when the user saves a new item.
  final Function(ItemModel) onSave;
  // An optional callback function to close the widget/modal.
  final VoidCallback? onClose;

  const AddItemWidget({
    Key? key,
    required this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  _AddItemWidgetState createState() => _AddItemWidgetState();
}

/// The State class for [AddItemWidget], containing the form's logic and UI.
class _AddItemWidgetState extends State<AddItemWidget> {
  // A GlobalKey for the Form widget, used for validation and state management.
  final _formKey = GlobalKey<FormState>();

  // --- TextEditingControllers for each form field ---
  // These controllers manage the text input for their respective TextFormFields.
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
  final _locationController = TextEditingController();

  // --- State Variables ---
  DateTime? _purchaseDate; // Stores the selected purchase date.
  bool _isLoading = false; // Tracks the loading state for the save button.
  String?
      _selectedAssetClassDesc; // Stores the value from the asset class dropdown.

  // A computed property to determine if the selected asset class is a vehicle.
  bool get _isVehicle => _selectedAssetClassDesc?.contains('Vehicle') ?? false;

  // A predefined list of asset classes for the dropdown menu.
  final List<String> _assetClasses = [
    'Office Equipment',
    'Company Vehicle (Own Used)',
    'Furniture and Fixtures- Office High Value',
    'IT Hardware',
    'Machinery(Own Used) - High Value',
    'Intangible Assets',
    'Vehicle for Leasing',
    'Commercial Vehicle - Asset',
    'Furniture and Fixtures- Properties',
    'Installation & Improvements',
    'Communication Equipment',
    'Computers',
    'Tools',
    'Signage',
    'Low-value assets - Furniture & Fixtures Office',
    'Rental',
    'Limousine Rental',
    'UBER',
  ];

  // A map that associates each asset class with its corresponding SAP data.
  // This is used to auto-populate fields when an asset class is selected.
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
    'Intangible Assets': {
      'CoCD': '8000',
      'Class': '1102',
      'APC acct': '110200'
    },
    'Vehicle for Leasing': {
      'CoCD': '8100',
      'Class': '2300',
      'APC acct': '110140'
    },
    'Commercial Vehicle - Asset': {
      'CoCD': '8000',
      'Class': '2350',
      'APC acct': '110190'
    },
    'Furniture and Fixtures- Properties': {
      'CoCD': '8000',
      'Class': '3001',
      'APC acct': '110210'
    },
    'Installation & Improvements': {
      'CoCD': '8000',
      'Class': '3200',
      'APC acct': '110230'
    },
    'Communication Equipment': {
      'CoCD': '8000',
      'Class': '3300',
      'APC acct': '110240'
    },
    'Computers': {'CoCD': '8000', 'Class': '3400', 'APC acct': '110250'},
    'Tools': {'CoCD': '8000', 'Class': '3500', 'APC acct': '110260'},
    'Signage': {'CoCD': '8000', 'Class': '3600', 'APC acct': '110270'},
    'Low-value assets - Furniture & Fixtures Office': {
      'CoCD': '8500',
      'Class': '5000',
      'APC acct': '110410'
    },
    'Rental': {'CoCD': '8600', 'Class': '2302', 'APC acct': '110160'},
    'Limousine Rental': {'CoCD': '8700', 'Class': '2303', 'APC acct': '110160'},
    'UBER': {'CoCD': '8800', 'Class': '2304', 'APC acct': '110160'},
  };

  /// Called when a new asset class is selected from the dropdown.
  void _onAssetClassChanged(String? newValue) {
    if (newValue != null) {
      // Look up the associated SAP data for the selected class.
      final associations = _assetClassAssociations[newValue];
      if (associations != null) {
        // Auto-populate the related text fields.
        _coCdController.text = associations['CoCD'] ?? '';
        _sapClassController.text = associations['Class'] ?? '';
        _apcAcctController.text = associations['APC acct'] ?? '';
      }
    }
    // Update the state to reflect the new selection and rebuild the UI.
    setState(() {
      _selectedAssetClassDesc = newValue;
    });
  }

  /// The dispose method is called when the widget is removed from the widget tree.
  /// It's important to dispose of controllers to free up resources.
  @override
  void dispose() {
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
    _locationController.dispose();
    super.dispose();
  }

  /// Displays the date picker and updates the state with the selected date.
  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000), // Earliest selectable date.
      lastDate: DateTime.now(), // Latest selectable date.
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  /// Validates the form, creates an [ItemModel], and calls the onSave callback.
  Future<void> _saveItem() async {
    // Check if the form is valid and a purchase date has been selected.
    if (!_formKey.currentState!.validate() || _purchaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Please fill all required fields, including purchase date.'),
        backgroundColor: Colors.red,
      ));
      return; // Stop execution if validation fails.
    }

    // Set loading state to true to show a progress indicator.
    setState(() => _isLoading = true);

    // Generate and save QR code for the new item
    final qrCodeId = _idController.text.trim();
    final qrCodeUrl = await QrCodeService.generateAndSaveQrCode(qrCodeId);
    print('[AddItemWidget] QR code file path returned: $qrCodeUrl');

    // Create a new ItemModel instance from the form data.
    final newItem = ItemModel(
      id: qrCodeId,
      name: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      itemType: ItemType.other, // Hardcoded for now.
      purchaseDate: _purchaseDate!, // '!' is safe due to the check above.
      variants: _variantsController.text.trim(),
      supplier: _supplierController.text.trim(),
      company: _companyController.text.trim(),
      qrCodeId: qrCodeId,
      qrCodeUrl: qrCodeUrl,
      isTagged: qrCodeUrl != null,
      department: _departmentController.text.trim(),
      assignedStaff: _ownerController.text.trim(),
      purchasePrice: double.tryParse(_purchasePriceController.text.trim()),
      assetClassDesc: _selectedAssetClassDesc,
      coCd: _coCdController.text.trim(),
      sapClass: _sapClassController.text.trim(),
      apcAcct: _apcAcctController.text.trim(),
      // Conditionally add vehicle-specific data.
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
    );

    // Call the onSave callback provided by the parent widget.
    widget.onSave(newItem);

    setState(() => _isLoading = false);
  }

  /// The main build method that constructs the widget's UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header Section ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Item',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  // Close button.
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.grey[100], shape: BoxShape.circle),
                      child:
                          Icon(Icons.close, color: Colors.grey[600], size: 24),
                    ),
                  ),
                ],
              ),
            ),
            // --- Form Section ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildAssetClassDropdown(),
                      const SizedBox(height: 20),
                      _buildTextField(_coCdController, 'CoCD',
                          isRequired: false, isReadOnly: true),
                      const SizedBox(height: 20),
                      _buildTextField(_sapClassController, 'Class',
                          isRequired: false, isReadOnly: true),
                      const SizedBox(height: 20),
                      _buildTextField(_apcAcctController, 'APC acct',
                          isRequired: false, isReadOnly: true),
                      const SizedBox(height: 20),
                      _buildTextField(_idController, 'Asset No.',
                          isRequired: true, isReadOnly: false),
                      const SizedBox(height: 20),
                      _buildTextField(_descriptionController, 'Description',
                          isRequired: true),
                      const SizedBox(height: 20),
                      _buildTextField(_ownerController, 'Owner',
                          isRequired: false),
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
                      // Conditionally display vehicle-specific fields.
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
                      ],
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
            // --- Footer / Submit Button ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // Disable button when loading.
                  onPressed: _isLoading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  // Show a progress indicator or text based on the loading state.
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('Submit for Approval',
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

  /// Helper method to build the dropdown for asset classes.
  Widget _buildAssetClassDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Asset Class',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      value: _selectedAssetClassDesc,
      items: _assetClasses.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: _onAssetClassChanged,
      validator: (value) => value == null ? 'This field is required' : null,
    );
  }

  /// A helper method to reduce boilerplate code for creating a [TextFormField].
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
      // Validator function to check if the field is empty.
      validator: (value) =>
          (value == null || value.trim().isEmpty) && isRequired
              ? 'This field is required'
              : null,
    );
  }

  /// A helper method to build the custom date picker input field.
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
              // Display placeholder text or the selected date.
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
