import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/attachment_model.dart';
import 'package:flutter_application_1/config/app_theme.dart';

/// A reusable card widget for displaying attachments
class AttachmentCard extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback? onDownload;

  const AttachmentCard({
    super.key,
    required this.attachment,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Show image thumbnail if available
          if (attachment.url != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                attachment.url!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            )
          else
            const Icon(Icons.insert_photo_outlined, color: Colors.grey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Added on ${attachment.timestamp.day}/${attachment.timestamp.month}/${attachment.timestamp.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (attachment.url != null)
                  const Text(
                    'Uploaded',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.successColor,
                    ),
                  ),
              ],
            ),
          ),
          if (onDownload != null)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              onPressed: onDownload,
            ),
        ],
      ),
    );
  }
}

