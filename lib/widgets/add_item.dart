// lib/widgets/add_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/services/qr_code_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class AddItemWidget extends StatefulWidget {
  final Function(ItemModel) onSave;
  final VoidCallback? onClose;

  const AddItemWidget({
    Key? key,
    required this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  _AddItemWidgetState createState() => _AddItemWidgetState();
}

class _AddItemWidgetState extends State<AddItemWidget> {
  final _formKey = GlobalKey<FormState>();

  // --- Standard Field Controllers ---
  final _idController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _variantsController = TextEditingController();
  final _supplierController = TextEditingController();
  final _companyController = TextEditingController();
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
  DateTime? _purchaseDate;
  bool _isLoading = false;
  String? _selectedAssetClassDesc;
  File? _itemImage;
  final ImagePicker _picker = ImagePicker();
  String? _selectedDepartment;
  String? _selectedCategory;

  bool get _isVehicle => _selectedAssetClassDesc?.contains('Vehicle') ?? false;

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

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final permanentFile =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');
      setState(() {
        _itemImage = permanentFile;
      });
    }
  }

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
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final qrCodeId = _idController.text.trim();
    final qrCodeUrl = await QrCodeService.generateAndSaveQrCode(qrCodeId);

    final newItem = ItemModel(
      id: qrCodeId,
      name: _descriptionController.text.trim(),
      category: _selectedCategory ?? 'Uncategorized', // Provide a default
      itemType: ItemType.other,
      purchaseDate: _purchaseDate ?? DateTime.now(), // Provide a default
      variants: _variantsController.text.trim(),
      supplier: _supplierController.text.trim(),
      company: _companyController.text.trim(),
      qrCodeId: qrCodeId,
      qrCodeUrl: qrCodeUrl,
      isTagged: qrCodeUrl != null,
      department: _selectedDepartment,
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
      location: _locationController.text.trim(),
      imageUrl: _itemImage?.path,
      customFields: {},
    );

    widget.onSave(newItem);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    final activeDepartments =
        dataStore.departments.where((d) => d.isActive).toList();
    final allCategories =
        dataStore.categories.where((c) => c.isActive).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New Item',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  Material(
                    color: Colors.white,
                    shape: CircleBorder(),
                    child: InkWell(
                      onTap: widget.onClose,
                      customBorder: CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.close,
                            color: Colors.grey[800], size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 24),
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
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration:
                            _buildInputDecoration('Category (Optional)'),
                        items: allCategories.map((Category category) {
                          return DropdownMenuItem<String>(
                            value: category.name,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        // REMOVED: validator to make it optional
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration:
                            _buildInputDecoration('Department (Optional)'),
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
                        // REMOVED: validator to make it optional
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(_ownerController, 'Assigned to',
                          isRequired: false),
                      const SizedBox(height: 20),
                      _buildTextField(_supplierController, 'Supplier Name',
                          isRequired:
                              false), // UPDATED: isRequired is now false
                      const SizedBox(height: 20),
                      _buildTextField(_plntController, 'Plnt',
                          isRequired: true),
                      const SizedBox(height: 20),
                      _buildTextField(_locationController, 'Location',
                          isRequired: true),
                      const SizedBox(height: 20),
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

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_itemImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _itemImage!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt_outlined),
            label:
                Text(_itemImage == null ? 'Take Item Photo' : 'Retake Photo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetClassDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _buildInputDecoration('Asset Class'),
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
                  ? 'Select Purchase Date (Optional)'
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
