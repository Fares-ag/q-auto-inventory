import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/firestore_models.dart';
import '../services/firebase_services.dart';
import '../utils/date_formatter.dart';
import 'empty_state.dart';

class CommentsSection extends StatefulWidget {
  const CommentsSection({super.key, required this.itemId});

  final String itemId;

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _commentController = TextEditingController();
  bool _isAdding = false;

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isAdding = true);
    try {
      final commentService = context.read<CommentService>();
      final user = FirebaseAuth.instance.currentUser;
      final comment = Comment(
        id: '',
        entityId: widget.itemId,
        entityType: 'item',
        authorId: user?.uid ?? user?.email ?? 'anonymous',
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );
      await commentService.addComment(comment);
      _commentController.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentService = context.read<CommentService>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<Comment>>(
          stream: commentService.watchComments(widget.itemId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const EmptyState(
                    icon: Icons.comment_outlined,
                    title: 'No Comments',
                    message: 'Be the first to add a comment',
                  );
                }
                return Column(
                  children: comments.map((comment) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(comment.authorId.isNotEmpty ? comment.authorId[0].toUpperCase() : '?'),
                      ),
                      title: Text(comment.authorId),
                      subtitle: Text(comment.content),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormatter.formatRelative(comment.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (comment.createdAt != null)
                            Text(
                              DateFormatter.formatTime(comment.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                            ),
                        ],
                      ),
                    ),
                  )).toList(),
                );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isAdding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onPressed: _isAdding ? null : _addComment,
            ),
          ],
        ),
      ],
    );
  }
}

