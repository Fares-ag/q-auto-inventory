import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/item_details_service.dart';
import 'package:flutter_application_1/models/information_model.dart';
import 'package:flutter_application_1/widgets/item_details/information_card.dart';

/// A widget for the information section in item details
class InformationSection extends StatelessWidget {
  final String itemId;
  final TextEditingController titleController;
  final TextEditingController bodyController;

  const InformationSection({
    super.key,
    required this.itemId,
    required this.titleController,
    required this.bodyController,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Information>>(
      stream: ItemDetailsService.getInformationStream(itemId),
      builder: (context, snapshot) {
        final informationEntries = snapshot.data ?? [];
        return Column(
          children: [
            // Display existing information entries
            ...informationEntries.reversed
                .map((info) => InformationCard(information: info))
                .toList(),
            if (informationEntries.isNotEmpty) const SizedBox(height: 16),
            // New input fields for adding a new entry
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Information Title',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: bodyController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter additional information...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

