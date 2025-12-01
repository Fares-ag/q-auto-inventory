import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/item_details_service.dart';
import 'package:flutter_application_1/widgets/item_details/item_issue_card.dart';
import 'package:flutter_application_1/widgets/common/gradient_button.dart';
import 'package:flutter_application_1/models/issue_model.dart';

/// A widget for the issues section in item details
class IssuesSection extends StatelessWidget {
  final String itemId;
  final VoidCallback onRaiseIssue;

  const IssuesSection({
    super.key,
    required this.itemId,
    required this.onRaiseIssue,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Issue>>(
      stream: ItemDetailsService.getIssuesStream(itemId),
      builder: (context, snapshot) {
        final reportedIssues = snapshot.data ?? [];
        return Column(
          children: [
            ...reportedIssues
                .map((issue) => ItemIssueCard(issue: issue))
                .toList(),
            const SizedBox(height: 16),
            GradientButton(
              text: 'Add New Issue',
              onPressed: onRaiseIssue,
              icon: Icons.warning_amber,
            ),
          ],
        );
      },
    );
  }
}

