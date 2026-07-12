import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_upload_widget.dart';

const Map<String, Map<String, String>> _assetClassMeta = {
  'Office Equipment': {'cocd': '8000', 'sap': '2600', 'apc': '110170'},
  'Company Vehicle (Own Used)': {
    'cocd': '8200',
    'sap': '2400',
    'apc': '110150'
  },
  'Furniture and fixes - office high value': {
    'cocd': '8000',
    'sap': '3000',
    'apc': '110210'
  },
  'IT Hardware': {'cocd': '8000', 'sap': '3400', 'apc': '110250'},
  'Machinery (Own Used) - High Value': {
    'cocd': '8000',
    'sap': '2000',
    'apc': '110110'
  },
  'Intagible Assets': {'cocd': '8000', 'sap': '1102', 'apc': '110200'},
  'Vehicle for Leasing': {'cocd': '8100', 'sap': '2300', 'apc': '110140'},
  'Commercial Vehicle - Asset': {
    'cocd': '8000',
    'sap': '2350',
    'apc': '110190'
  },
  'Furniture and Fixes - Properties': {
    'cocd': '8000',
    'sap': '3001',
    'apc': '110210'
  },
  'Installation & Improvements': {
    'cocd': '8000',
    'sap': '3200',
    'apc': '110230'
  },
  'Communication Equipment': {'cocd': '8000', 'sap': '3300', 'apc': '110240'},
  'Computers': {'cocd': '8000', 'sap': '3400', 'apc': '110250'},
  'Tools': {'cocd': '8000', 'sap': '3500', 'apc': '110260'},
  'Signage': {'cocd': '8000', 'sap': '3600', 'apc': '110270'},
  'Low-value assets - Furniture & Fixes Office': {
    'cocd': '8500',
    'sap': '5000',
    'apc': '110410'
  },
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
  final _subDepartmentController = TextEditingController();
  final _itemTypeController = TextEditingController();
  final _modelCodeController = TextEditingController();
  final _modelDescController = TextEditingController();
  final _modelYearController = TextEditingController();
  final _assetTypeController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _ownerController = TextEditingController();
  final _plantController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _vehicleIdController = TextEditingController();
  final _mileageController = TextEditingController();
  final _maintenanceScheduleController = TextEditingController();
  final _assetNumberController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedDepartmentId;
  String? _selectedLocationId;
  String? _selectedStatus = 'pending';
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  DateTime? _registrationDate;
  DateTime? _lastMaintenanceDate;
  DateTime? _nextMaintenanceDate;
  String? _uploadedImageUrl;
  String? _selectedAssetClass;
  double? _purchasePrice;
  int? _shelfLife;
  int? _mileage;
  bool _isAvailable = true;
  bool _isTagged = false;
  bool _isWrittenOff = false;

  List<Category> _categories = [];
  List<Department> _departments = [];
  List<Location> _locations = [];
  bool _isLoading = false;
  bool _assetIdLoading = true;
  String? _assetIdPatternNote;
  bool _useAutoAssetId = true;
  bool _programmaticAssetIdUpdate = false;

  @override
  void initState() {
    super.initState();
    _assetIdController.addListener(_onAssetIdEdited);
    _loadDropdownData();
    _loadSuggestedAssetId();
  }

  void _onAssetIdEdited() {
    if (_programmaticAssetIdUpdate || !_useAutoAssetId) return;
    setState(() => _useAutoAssetId = false);
  }

  Future<void> _loadDropdownData() async {
    final catalog = context.read<CatalogService>();
    final deptService = context.read<DepartmentService>();

    final categories = await catalog.listCategories();
    final departments =
        await deptService.listDepartments(includeInactive: false);
    final locations = await catalog.listLocations();

    setState(() {
      _categories = categories;
      _departments = departments;
      _locations = locations;
    });
  }

  Future<void> _loadSuggestedAssetId() async {
    if (!mounted) return;
    setState(() {
      _assetIdLoading = true;
      _assetIdPatternNote = null;
    });
    try {
      final catalog = context.read<CatalogService>();
      final suggestion = await catalog.suggestNextAssetIdForForm();
      if (!mounted) return;
      _programmaticAssetIdUpdate = true;
      setState(() {
        _assetIdController.text = suggestion.id;
        _assetIdPatternNote = suggestion.patternNote;
        _assetIdLoading = false;
        _useAutoAssetId = true;
      });
      _programmaticAssetIdUpdate = false;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _assetIdPatternNote = 'Could not suggest an ID. Enter one manually.';
        _assetIdLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asset ID suggestion failed: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, int dateType) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        switch (dateType) {
          case 0: // Purchase Date
            _purchaseDate = picked;
            break;
          case 1: // Warranty Expiry
            _warrantyExpiry = picked;
            break;
          case 2: // Registration Date
            _registrationDate = picked;
            break;
          case 3: // Last Maintenance
            _lastMaintenanceDate = picked;
            break;
          case 4: // Next Maintenance
            _nextMaintenanceDate = picked;
            break;
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
      final bool reservedAutomatically = _useAutoAssetId;
      final String assetId = reservedAutomatically
          ? await catalog.reserveNextAssetId()
          : _assetIdController.text.trim();

      if (assetId.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asset ID is required')),
          );
        }
        return;
      }

      final priceText = _purchasePriceController.text.trim();
      final shelfText = _shelfLifeController.text.trim();
      _purchasePrice = priceText.isEmpty ? null : double.tryParse(priceText);
      _shelfLife = shelfText.isEmpty ? null : int.tryParse(shelfText);

      final mileageText = _mileageController.text.trim();
      _mileage = mileageText.isEmpty ? null : int.tryParse(mileageText);

      final item = InventoryItem(
        id: '',
        assetId: assetId,
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
        customFields: null, // Use direct fields instead
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
        licensePlate: _licensePlateController.text.trim().isEmpty
            ? null
            : _licensePlateController.text.trim(),
        vendor: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
        plant: _plantController.text.trim().isEmpty
            ? null
            : _plantController.text.trim(),
        owner: _ownerController.text.trim().isEmpty
            ? null
            : _ownerController.text.trim(),
        vehicleId: _vehicleIdController.text.trim().isEmpty
            ? null
            : _vehicleIdController.text.trim(),
        // New Firestore fields
        subDepartment: _subDepartmentController.text.trim().isEmpty
            ? null
            : _subDepartmentController.text.trim(),
        isAvailable: _isAvailable,
        isTagged: _isTagged,
        isWrittenOff: _isWrittenOff,
        itemType: _itemTypeController.text.trim().isEmpty
            ? null
            : _itemTypeController.text.trim(),
        modelCode: _modelCodeController.text.trim().isEmpty
            ? null
            : _modelCodeController.text.trim(),
        modelDesc: _modelDescController.text.trim().isEmpty
            ? null
            : _modelDescController.text.trim(),
        modelYear: _modelYearController.text.trim().isEmpty
            ? null
            : _modelYearController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        assetType: _assetTypeController.text.trim().isEmpty
            ? null
            : _assetTypeController.text.trim(),
        warranty: _warrantyController.text.trim().isEmpty
            ? null
            : _warrantyController.text.trim(),
        mileage: _mileage,
        registrationDate: _registrationDate,
        serialNumber: _serialNumberController.text.trim().isEmpty
            ? null
            : _serialNumberController.text.trim(),
        lastMaintenanceDate: _lastMaintenanceDate,
        nextMaintenanceDate: _nextMaintenanceDate,
        maintenanceSchedule: _maintenanceScheduleController.text.trim().isEmpty
            ? null
            : _maintenanceScheduleController.text.trim(),
        assetNumber: _assetNumberController.text.trim().isEmpty
            ? null
            : _assetNumberController.text.trim(),
      );

      await catalog.createItem(item);
      if (!reservedAutomatically) {
        await catalog.advanceAssetCounterAfterCreate(item.assetId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item created successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating item: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _formSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final bg = isDark ? AppTheme.darkCard : AppTheme.lightSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? const <BoxShadow>[] : AppTheme.shadowSm,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _assetIdController.removeListener(_onAssetIdEdited);
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
    _subDepartmentController.dispose();
    _itemTypeController.dispose();
    _modelCodeController.dispose();
    _modelDescController.dispose();
    _modelYearController.dispose();
    _assetTypeController.dispose();
    _warrantyController.dispose();
    _serialNumberController.dispose();
    _ownerController.dispose();
    _plantController.dispose();
    _licensePlateController.dispose();
    _vehicleIdController.dispose();
    _mileageController.dispose();
    _maintenanceScheduleController.dispose();
    _assetNumberController.dispose();
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _formSection(context, title: 'Identity', children: [
            TextFormField(
              controller: _assetIdController,
              decoration: InputDecoration(
                labelText: 'Asset ID *',
                hintText: 'e.g. FA-0001',
                helperText: _assetIdPatternNote,
                suffixIcon: _assetIdLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        tooltip: 'Suggest next ID from inventory',
                        onPressed: _loadSuggestedAssetId,
                      ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Asset ID is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Asset Number (optional)
            TextFormField(
              controller: _assetNumberController,
              decoration: const InputDecoration(
                labelText: 'Asset Number',
                hintText: 'Optional asset number',
                helperText: 'Optional: Additional asset identifier',
              ),
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
            ]),
            _formSection(context, title: 'Classification & placement', children: [
            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
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
              initialValue: _selectedDepartmentId,
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
              onChanged: (value) =>
                  setState(() => _selectedDepartmentId = value),
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
              initialValue: _selectedLocationId,
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
              initialValue: _selectedStatus,
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
                onPressed: () => _selectDate(context, 0),
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
                onPressed: () => _selectDate(context, 1),
              ),
            ),
            const SizedBox(height: 16),
            ]),
            _formSection(context, title: 'Specs & ownership', children: [
            // Sub Department
            TextFormField(
              controller: _subDepartmentController,
              decoration: const InputDecoration(
                labelText: 'Sub Department',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Item Type
            TextFormField(
              controller: _itemTypeController,
              decoration: const InputDecoration(
                labelText: 'Item Type',
                hintText: 'e.g., other, vehicle, equipment',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Asset Type
            TextFormField(
              controller: _assetTypeController,
              decoration: const InputDecoration(
                labelText: 'Asset Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Model Information
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _modelCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Model Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelYearController,
                    decoration: const InputDecoration(
                      labelText: 'Model Year',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _modelDescController,
              decoration: const InputDecoration(
                labelText: 'Model Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Serial Number
            TextFormField(
              controller: _serialNumberController,
              decoration: const InputDecoration(
                labelText: 'Serial Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Owner
            TextFormField(
              controller: _ownerController,
              decoration: const InputDecoration(
                labelText: 'Owner',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Plant
            TextFormField(
              controller: _plantController,
              decoration: const InputDecoration(
                labelText: 'Plant',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ]),
            _formSection(context, title: 'Vehicle', children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _licensePlateController,
                    decoration: const InputDecoration(
                      labelText: 'License Plate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _vehicleIdController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mileageController,
                    decoration: const InputDecoration(
                      labelText: 'Mileage (km)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ListTile(
                    title: const Text('Registration Date'),
                    subtitle: Text(_registrationDate == null
                        ? 'Not set'
                        : '${_registrationDate!.day}/${_registrationDate!.month}/${_registrationDate!.year}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () => _selectDate(context, 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ]),
            _formSection(context, title: 'Maintenance', children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Last Maintenance'),
                    subtitle: Text(_lastMaintenanceDate == null
                        ? 'Not set'
                        : '${_lastMaintenanceDate!.day}/${_lastMaintenanceDate!.month}/${_lastMaintenanceDate!.year}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () => _selectDate(context, 3),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ListTile(
                    title: const Text('Next Maintenance'),
                    subtitle: Text(_nextMaintenanceDate == null
                        ? 'Not set'
                        : '${_nextMaintenanceDate!.day}/${_nextMaintenanceDate!.month}/${_nextMaintenanceDate!.year}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () => _selectDate(context, 4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _maintenanceScheduleController,
              decoration: const InputDecoration(
                labelText: 'Maintenance Schedule',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Warranty
            TextFormField(
              controller: _warrantyController,
              decoration: const InputDecoration(
                labelText: 'Warranty',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ]),
            _formSection(context, title: 'Status & accounting', children: [
            CheckboxListTile(
              title: const Text('Available'),
              value: _isAvailable,
              onChanged: (value) => setState(() => _isAvailable = value ?? true),
            ),
            CheckboxListTile(
              title: const Text('Tagged'),
              value: _isTagged,
              onChanged: (value) => setState(() => _isTagged = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Written Off'),
              value: _isWrittenOff,
              onChanged: (value) => setState(() => _isWrittenOff = value ?? false),
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
              initialValue: _selectedAssetClass,
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
            ]),
            _formSection(context, title: 'Photo', children: [
            ImageUploadWidget(
              itemId: 'temp',
              currentImageUrl: _uploadedImageUrl,
              onImageUploaded: (url) {
                setState(() => _uploadedImageUrl = url);
              },
            ),
            const SizedBox(height: 16),
            ]),
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
