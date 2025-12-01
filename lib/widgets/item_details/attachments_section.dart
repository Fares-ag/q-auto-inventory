import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/item_details_service.dart';
import 'package:flutter_application_1/models/attachment_model.dart';
import 'package:flutter_application_1/widgets/item_details/attachment_card.dart';
import 'package:flutter_application_1/widgets/common/gradient_button.dart';

/// A widget for the attachments section in item details
class AttachmentsSection extends StatelessWidget {
  final String itemId;
  final VoidCallback onAddAttachment;

  const AttachmentsSection({
    super.key,
    required this.itemId,
    required this.onAddAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Attachment>>(
      stream: ItemDetailsService.getAttachmentsStream(itemId),
      builder: (context, snapshot) {
        final attachments = snapshot.data ?? [];
        return Column(
          children: [
            ...attachments
                .map((attachment) => AttachmentCard(attachment: attachment))
                .toList(),
            const SizedBox(height: 16),
            GradientButton(
              text: 'Add Attachment',
              onPressed: onAddAttachment,
              icon: Icons.attachment,
            ),
          ],
        );
      },
    );
  }
}

