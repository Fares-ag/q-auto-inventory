// lib/widgets/common/detail_item.dart

import 'package:flutter/material.dart';

class DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const DetailItem({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
