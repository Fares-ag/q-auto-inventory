import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/firebase_services.dart';
import '../services/image_upload_service.dart';

class ImageUploadWidget extends StatefulWidget {
  const ImageUploadWidget({
    super.key,
    required this.itemId,
    this.currentImageUrl,
    this.onImageUploaded,
  });

  final String itemId;
  final String? currentImageUrl;
  final ValueChanged<String>? onImageUploaded;

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final imageFile = File(image.path);
      final uploadService = ImageUploadService();
      final downloadUrl = await uploadService.uploadItemImage(widget.itemId, imageFile);

      if (widget.itemId != 'temp') {
        final catalog = context.read<CatalogService>();
        await catalog.updateItem(widget.itemId, {
          'thumbnailUrl': downloadUrl,
        });
      }

      if (widget.onImageUploaded != null) {
        widget.onImageUploaded!(downloadUrl);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.currentImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
              ),
            ),
          )
        else
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Icon(Icons.image, size: 64, color: Colors.grey),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _isUploading ? null : () => _pickAndUploadImage(fromCamera: false),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : () => _pickAndUploadImage(fromCamera: true),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
          ],
        ),
        if (_isUploading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('Uploading image...', style: TextStyle(fontSize: 12)),
        ],
      ],
    );
  }
}

