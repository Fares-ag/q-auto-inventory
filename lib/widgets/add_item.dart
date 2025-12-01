import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/config/app_theme.dart';
import 'package:flutter_application_1/services/item_service.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'dart:io';
import 'dart:math';

// AddItemWidget is a stateful widget for the form to add a new item.
// It is designed to be displayed as a modal bottom sheet.
class AddItemWidget extends StatefulWidget {
  // A callback function to pass the saved data back to the parent widget.
  final Function(ItemData)? onSave;
  // A callback function to close the modal.
  final VoidCallback? onClose;

  const AddItemWidget({
    Key? key,
    this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  _AddItemWidgetState createState() => _AddItemWidgetState();
}

class _AddItemWidgetState extends State<AddItemWidget> {
  // GlobalKey is used to manage the state of the Form widget for validation.
  final _formKey = GlobalKey<FormState>();
  // TextEditingControllers are used to read and manage the text in the form fields.
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _categoryController = TextEditingController();
  final _variantsController = TextEditingController();
  final _supplierController = TextEditingController();
  final _companyController = TextEditingController();
  
  // Item type selection
  ItemType _selectedItemType = ItemType.other;

  // A variable to store the selected image file.
  File? _selectedImage;
  // The ImagePicker is a utility for picking images from the gallery or camera.
  final ImagePicker _picker = ImagePicker();
  // A boolean to show a loading spinner when saving.
  bool _isLoading = false;

  @override
  void dispose() {
    // It's important to dispose of the controllers to free up memory.
    _nameController.dispose();
    _descriptionController.dispose();
    _serialNumberController.dispose();
    _categoryController.dispose();
    _variantsController.dispose();
    _supplierController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  // This function displays a modal bottom sheet for the user to choose an image source.
  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading:
                        const Icon(Icons.photo_library, color: Colors.blue),
                    title: const Text('Choose from Gallery'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _getImageFromSource(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.photo_camera, color: Colors.green),
                    title: const Text('Take a Photo'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _getImageFromSource(ImageSource.camera);
                    },
                  ),
                  // Conditionally show an option to remove the photo.
                  if (_selectedImage != null)
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Remove Photo'),
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.grey),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      _showErrorSnackBar('Failed to open image picker');
    }
  }

  // This function handles the actual image picking based on the source.
  Future<void> _getImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image');
    }
  }

  // Helper function to show an error snack bar.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper function to show a success snack bar.
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Generate a unique barcode for the item
  /// Format: ITM-{timestamp}-{random}
  String _generateBarcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'ITM-$timestamp-$random';
  }

  // This function is called when the 'Save' button is pressed.
  Future<void> _saveItem() async {
    // Validate the form. If it's invalid, the function stops here.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter an item name');
      return;
    }

    // Set loading state to true to show the progress indicator.
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate a unique barcode for the item
      final generatedBarcode = _generateBarcode();
      final manualBarcode = _serialNumberController.text.trim();
      
      // Use manual serial number if provided, otherwise use auto-generated barcode
      final barcode = manualBarcode.isNotEmpty 
          ? manualBarcode 
          : generatedBarcode;
      final isAutoGenerated = manualBarcode.isEmpty;
      
      // Create a new ItemModel from the form's data
      final now = DateTime.now();
      final newItem = ItemModel(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        variants: _variantsController.text.trim().isNotEmpty 
            ? _variantsController.text.trim() 
            : '1 Variant', // Only use default if empty
        supplier: _supplierController.text.trim(),
        company: _companyController.text.trim(),
        date: _formatDate(now),
        itemType: _selectedItemType,
        isTagged: true, // Always tagged since we always generate a barcode
        isSeenToday: false,
        isWrittenOff: false,
        qrCodeId: barcode, // Always set a barcode (auto-generated or manual)
      );

      // Save to Firestore first to get the item ID
      final itemId = await ItemService.createItem(newItem);

      // Upload image if one is selected
      String? imageUrl;
      if (_selectedImage != null) {
        try {
          imageUrl = await StorageService.uploadImage(
            imageFile: _selectedImage!,
            itemId: itemId,
          );
          
          // Update the item with the image URL
          final updatedItem = newItem.copyWith(
            id: itemId,
            imageUrl: imageUrl,
          );
          await ItemService.updateItem(updatedItem);
        } catch (e) {
          // If image upload fails, item is still saved but without image
          debugPrint('Failed to upload image: $e');
          // Continue - item is saved, just without image
        }
      }

      // Show success message with barcode info
      final barcodeMessage = isAutoGenerated
          ? 'Item saved successfully! Auto-generated barcode: $barcode'
          : 'Item saved successfully with barcode: $barcode';
      _showSuccessSnackBar(barcodeMessage);

      // Clear the form fields and state.
      _clearForm();

      // Close the modal after a short delay to show the success message.
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && widget.onClose != null) {
          widget.onClose!();
        }
      });
    } catch (e) {
      _showErrorSnackBar('Failed to save item: ${e.toString()}');
    } finally {
      // Reset loading state.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Format DateTime to string
  String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final weekday = weekdays[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$weekday $day $month $year, $hour:$minute';
  }

  // Clears all form fields and the selected image.
  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _serialNumberController.clear();
    _categoryController.clear();
    _variantsController.clear();
    _supplierController.clear();
    _companyController.clear();
    setState(() {
      _selectedImage = null;
      _selectedItemType = ItemType.other;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and close button.
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                    child: const Text(
                      'Add Item',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main form content, wrapped in a scrollable view.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Section
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedImage = null;
                                            });
                                          },
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt_outlined,
                                        size: 32,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Take a photo of your item',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to add photo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Name',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Description (Optional)',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          hintText: 'Category *',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _variantsController,
                        decoration: InputDecoration(
                          hintText: 'Variants (Optional)',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _supplierController,
                        decoration: InputDecoration(
                          hintText: 'Supplier *',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a supplier';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _companyController,
                        decoration: InputDecoration(
                          hintText: 'Company *',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a company';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Item Type Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<ItemType>(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Item Type *',
                          ),
                          initialValue: _selectedItemType,
                          items: ItemType.values.map((ItemType type) {
                            return DropdownMenuItem<ItemType>(
                              value: type,
                              child: Text(
                                type.name[0].toUpperCase() + type.name.substring(1),
                              ),
                            );
                          }).toList(),
                          onChanged: (ItemType? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedItemType = newValue;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an item type';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _serialNumberController,
                        decoration: InputDecoration(
                          hintText: 'Barcode/Serial Number (Optional - Auto-generated if empty)',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          helperText: 'Leave empty to auto-generate a unique barcode',
                          helperStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            // The Save button.
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _isLoading ? null : AppTheme.primaryGradient,
                    color: _isLoading ? Colors.grey[400] : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isLoading ? null : [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                        ),
                      ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data model for the item, used to pass data between widgets.
class ItemData {
  final String name;
  final String description;
  final String serialNumber;
  final File? image;
  final DateTime createdAt;

  ItemData({
    required this.name,
    required this.description,
    required this.serialNumber,
    this.image,
    required this.createdAt,
  });

  @override
  String toString() {
    return 'ItemData(name: $name, description: $description, serialNumber: $serialNumber, hasImage: ${image != null}, createdAt: $createdAt)';
  }
}
