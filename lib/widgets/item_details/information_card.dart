import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/information_model.dart';

/// A reusable card widget for displaying information entries
class InformationCard extends StatelessWidget {
  final Information information;

  const InformationCard({
    super.key,
    required this.information,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            information.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (information.body.isNotEmpty)
            Text(
              information.body,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Saved on ${information.timestamp.day}/${information.timestamp.month}/${information.timestamp.year} at ${information.timestamp.hour}:${information.timestamp.minute}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

