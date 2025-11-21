import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';

class EditItemScreen extends StatefulWidget {
  const EditItemScreen({super.key, required this.item});

  final InventoryItem item;

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.item.name);
  late final _descriptionController = TextEditingController(text: widget.item.description ?? '');
  late final _quantityController = TextEditingController(text: widget.item.quantity?.toString() ?? '');
  late final _assetIdController = TextEditingController(text: widget.item.assetId);
  
  String? _selectedCategoryId;
  String? _selectedDepartmentId;
  String? _selectedLocationId;
  String? _selectedStatus;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  
  List<Category> _categories = [];
  List<Department> _departments = [];
  List<Location> _locations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.item.categoryId;
    _selectedDepartmentId = widget.item.departmentId;
    _selectedLocationId = widget.item.locationId;
    _selectedStatus = widget.item.status;
    _purchaseDate = widget.item.purchaseDate;
    _warrantyExpiry = widget.item.warrantyExpiry;
    _loadDropdownData();
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

  Future<void> _selectDate(BuildContext context, bool isPurchase) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isPurchase 
          ? (_purchaseDate ?? DateTime.now())
          : (_warrantyExpiry ?? DateTime.now()),
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
      
      final updates = <String, dynamic>{
        'assetId': _assetIdController.text.trim(),
        'name': _nameController.text.trim(),
        'categoryId': _selectedCategoryId!,
        'departmentId': _selectedDepartmentId!,
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
        if (_quantityController.text.trim().isNotEmpty)
          'quantity': int.tryParse(_quantityController.text.trim()),
        if (_selectedStatus != null) 'status': _selectedStatus,
        if (_selectedLocationId != null) 'locationId': _selectedLocationId,
        if (_purchaseDate != null)
          'purchaseDate': _purchaseDate,
        if (_warrantyExpiry != null)
          'warrantyExpiry': _warrantyExpiry,
      };

      await catalog.updateItem(widget.item.id, updates);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.item.name}'),
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
            // Asset ID
            TextFormField(
              controller: _assetIdController,
              decoration: const InputDecoration(
                labelText: 'Asset ID *',
                border: OutlineInputBorder(),
              ),
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
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Status
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
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
            
            // Purchase Date
            ListTile(
              title: const Text('Purchase Date'),
              subtitle: Text(_purchaseDate == null
                  ? 'Not set'
                  : '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_purchaseDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _purchaseDate = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Warranty Expiry
            ListTile(
              title: const Text('Warranty Expiry'),
              subtitle: Text(_warrantyExpiry == null
                  ? 'Not set'
                  : '${_warrantyExpiry!.day}/${_warrantyExpiry!.month}/${_warrantyExpiry!.year}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_warrantyExpiry != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _warrantyExpiry = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _saveItem,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

