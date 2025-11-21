import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../widgets/image_upload_widget.dart';

const Map<String, Map<String, String>> _assetClassMeta = {
  'Office Equipment': {'cocd': '8000', 'sap': '2600', 'apc': '110170'},
  'Company Vehicle (Own Used)': {'cocd': '8200', 'sap': '2400', 'apc': '110150'},
  'Furniture and fixes - office high value': {'cocd': '8000', 'sap': '3000', 'apc': '110210'},
  'IT Hardware': {'cocd': '8000', 'sap': '3400', 'apc': '110250'},
  'Machinery (Own Used) - High Value': {'cocd': '8000', 'sap': '2000', 'apc': '110110'},
  'Intagible Assets': {'cocd': '8000', 'sap': '1102', 'apc': '110200'},
  'Vehicle for Leasing': {'cocd': '8100', 'sap': '2300', 'apc': '110140'},
  'Commercial Vehicle - Asset': {'cocd': '8000', 'sap': '2350', 'apc': '110190'},
  'Furniture and Fixes - Properties': {'cocd': '8000', 'sap': '3001', 'apc': '110210'},
  'Installation & Improvements': {'cocd': '8000', 'sap': '3200', 'apc': '110230'},
  'Communication Equipment': {'cocd': '8000', 'sap': '3300', 'apc': '110240'},
  'Computers': {'cocd': '8000', 'sap': '3400', 'apc': '110250'},
  'Tools': {'cocd': '8000', 'sap': '3500', 'apc': '110260'},
  'Signage': {'cocd': '8000', 'sap': '3600', 'apc': '110270'},
  'Low-value assets - Furniture & Fixes Office': {'cocd': '8500', 'sap': '5000', 'apc': '110410'},
  'Rental': {'cocd': '8600', 'sap': '2302', 'apc': '110160'},
  'Limousine Rental': {'cocd': '8700', 'sap': '2302', 'apc': '110160'},
  'UBER': {'cocd': '8800', 'sap': '2304', 'apc': '110160'},
};

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _assetIdController = TextEditingController();
  final _variantsController = TextEditingController();
  final _supplierController = TextEditingController();
  final _companyController = TextEditingController();
  final _assignedToController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _shelfLifeController = TextEditingController();
  final _cocdController = TextEditingController();
  final _sapController = TextEditingController();
  final _apcController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedDepartmentId;
  String? _selectedLocationId;
  String? _selectedStatus = 'pending';
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  String? _uploadedImageUrl;
  String? _selectedAssetClass;
  double? _purchasePrice;
  int? _shelfLife;
  
  List<Category> _categories = [];
  List<Department> _departments = [];
  List<Location> _locations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _loadNextAssetId();
  }

  Future<void> _loadDropdownData() async {
    final catalog = context.read<CatalogService>();
    final deptService = context.read<DepartmentService>();
    
    final categories = await catalog.listCategories();
    final departments = await deptService.listDepartments(includeInactive: false);
    final locations = await catalog.listLocations();
    
    setState(() {
      _categories = categories;
      _departments = departments;
      _locations = locations;
    });
  }

  Future<void> _loadNextAssetId() async {
    final catalog = context.read<CatalogService>();
    final nextId = await catalog.generateNextAssetId();
    setState(() {
      _assetIdController.text = nextId;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isPurchase) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        if (isPurchase) {
          _purchaseDate = picked;
        } else {
          _warrantyExpiry = picked;
        }
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final catalog = context.read<CatalogService>();
      final priceText = _purchasePriceController.text.trim();
      final shelfText = _shelfLifeController.text.trim();
      _purchasePrice = priceText.isEmpty ? null : double.tryParse(priceText);
      _shelfLife = shelfText.isEmpty ? null : int.tryParse(shelfText);
      
      final customFields = <String, dynamic>{};
      if (_companyController.text.trim().isNotEmpty) {
        customFields['company'] = _companyController.text.trim();
      }

      final item = InventoryItem(
        id: '',
        assetId: _assetIdController.text.trim(),
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId!,
        departmentId: _selectedDepartmentId!,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        quantity: _quantityController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_quantityController.text.trim()),
        status: _selectedStatus,
        locationId: _selectedLocationId,
        assignedTo: _assignedToController.text.trim().isEmpty
            ? null
            : _assignedToController.text.trim(),
        purchaseDate: _purchaseDate,
        warrantyExpiry: _warrantyExpiry,
        thumbnailUrl: _uploadedImageUrl,
        customFields: customFields.isEmpty ? null : customFields,
        supplier: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
        variants: _variantsController.text.trim().isEmpty
            ? null
            : _variantsController.text.trim(),
        purchasePrice: _purchasePrice,
        shelfLifeYears: _shelfLife,
        coCd: _cocdController.text.isEmpty ? null : _cocdController.text,
        sapClass: _sapController.text.isEmpty ? null : _sapController.text,
        assetClassDesc: _selectedAssetClass,
        apcAccount: _apcController.text.isEmpty ? null : _apcController.text,
        licensePlate: null,
        vendor: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
        plant: null,
        owner: null,
        vehicleId: null,
      );

      await catalog.createItem(item);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item created successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _assetIdController.dispose();
    _variantsController.dispose();
    _supplierController.dispose();
    _companyController.dispose();
    _assignedToController.dispose();
    _purchasePriceController.dispose();
    _shelfLifeController.dispose();
    _cocdController.dispose();
    _sapController.dispose();
    _apcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveItem,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _assetIdController,
              decoration: const InputDecoration(
                labelText: 'Asset ID *',
                hintText: 'ASSET-001',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Asset ID is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                hintText: 'Enter item name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Item name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _variantsController,
              decoration: const InputDecoration(
                labelText: 'Variants',
                hintText: 'Color, size, options…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Supplier',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _assignedToController,
              decoration: const InputDecoration(
                labelText: 'Assigned To',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .where((c) => c.isActive)
                  .map((category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategoryId = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Department
            DropdownButtonFormField<String>(
              value: _selectedDepartmentId,
              decoration: const InputDecoration(
                labelText: 'Department *',
                border: OutlineInputBorder(),
              ),
              items: _departments
                  .where((d) => d.isActive)
                  .map((dept) => DropdownMenuItem(
                        value: dept.id,
                        child: Text(dept.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedDepartmentId = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a department';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Location
            DropdownButtonFormField<String>(
              value: _selectedLocationId,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ..._locations.map((loc) => DropdownMenuItem(
                      value: loc.id,
                      child: Text(loc.name),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedLocationId = value),
            ),
            const SizedBox(height: 16),
            
            // Quantity
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: '1',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Status
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _purchasePriceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) =>
                  setState(() => _purchasePrice = double.tryParse(value)),
            ),
            const SizedBox(height: 16),
            
            // Purchase Date
            ListTile(
              title: const Text('Purchase Date'),
              subtitle: Text(_purchaseDate == null
                  ? 'Not set'
                  : '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(height: 8),
            
            // Warranty Expiry
            ListTile(
              title: const Text('Warranty Expiry'),
              subtitle: Text(_warrantyExpiry == null
                  ? 'Not set'
                  : '${_warrantyExpiry!.day}/${_warrantyExpiry!.month}/${_warrantyExpiry!.year}'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, false),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _shelfLifeController,
              decoration: const InputDecoration(
                labelText: 'Shelf Life (Years)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  setState(() => _shelfLife = int.tryParse(value)),
            ),
            const SizedBox(height: 24),
            
            DropdownButtonFormField<String>(
              value: _selectedAssetClass,
              decoration: const InputDecoration(
                labelText: 'Asset Class',
                border: OutlineInputBorder(),
              ),
              items: _assetClassMeta.keys
                  .map((label) =>
                      DropdownMenuItem(value: label, child: Text(label)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAssetClass = value;
                  final meta = value == null ? null : _assetClassMeta[value];
                  _cocdController.text = meta?['cocd'] ?? '';
                  _sapController.text = meta?['sap'] ?? '';
                  _apcController.text = meta?['apc'] ?? '';
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cocdController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'CoCD',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _sapController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'SAP Class',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apcController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'APC Account',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Take Item Photo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ImageUploadWidget(
              itemId: 'temp',
              currentImageUrl: _uploadedImageUrl,
              onImageUploaded: (url) {
                setState(() => _uploadedImageUrl = url);
              },
            ),
            const SizedBox(height: 24),
            
            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _saveItem,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Create Item'),
            ),
          ],
        ),
      ),
    );
  }
}

