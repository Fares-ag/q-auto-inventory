// lib/widgets/common/expandable_section.dart

import 'package:flutter/material.dart';

class ExpandableSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget child;

  const ExpandableSection({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onTap,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.remove : Icons.add),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}
