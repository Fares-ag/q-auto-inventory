import 'package:flutter/material.dart';

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 8, this.itemHeight = 64});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4);
    return ListView.separated(
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: itemHeight,
            color: base,
          ),
        );
      },
    );
  }
}
