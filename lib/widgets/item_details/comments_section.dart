import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/item_details_service.dart';
import 'package:flutter_application_1/models/comment_model.dart';
import 'package:flutter_application_1/widgets/item_details/comment_card.dart';
import 'package:flutter_application_1/widgets/common/gradient_button.dart';

/// A widget for the comments section in item details
class CommentsSection extends StatelessWidget {
  final String itemId;
  final TextEditingController commentController;
  final VoidCallback onSaveComment;

  const CommentsSection({
    super.key,
    required this.itemId,
    required this.commentController,
    required this.onSaveComment,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Comment>>(
      stream: ItemDetailsService.getCommentsStream(itemId),
      builder: (context, snapshot) {
        final comments = snapshot.data ?? [];
        return Column(
          children: [
            ...comments.reversed
                .map((comment) => CommentCard(comment: comment))
                .toList(),
            const SizedBox(height: 16),
            TextFormField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write a new comment...',
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
            GradientButton(
              text: 'Add Comment',
              onPressed: onSaveComment,
              icon: Icons.comment,
            ),
          ],
        );
      },
    );
  }
}

