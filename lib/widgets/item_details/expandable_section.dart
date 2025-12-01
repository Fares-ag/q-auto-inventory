import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/app_theme.dart';
import 'package:flutter_application_1/widgets/common/gradient_button.dart';

/// A reusable expandable section widget
class ExpandableSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget expandedContent;
  final bool hasSaveButton;
  final VoidCallback? onSave;
  final String? saveButtonText;

  const ExpandableSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.isExpanded,
    required this.onTap,
    required this.expandedContent,
    this.hasSaveButton = false,
    this.onSave,
    this.saveButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: expandedContent,
            ),
            if (hasSaveButton && onSave != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GradientButton(
                  text: saveButtonText ?? 'Save',
                  onPressed: onSave,
                  icon: Icons.save,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}


