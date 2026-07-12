import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';
import '../utils/app_spacing.dart';

/// A shimmer skeleton list — replaces plain opacity-box approach with a
/// smooth wave animation using the [shimmer] package.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 8,
    this.itemHeight = 72,
    this.padding = EdgeInsets.zero,
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppTheme.darkSurfaceVariant : const Color(0xFFE8E8ED);
    final highlight = isDark ? AppTheme.darkCard : Colors.white;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.separated(
        primary: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => AppSpacing.gapSm,
        itemBuilder: (_, __) => _SkeletonTile(height: itemHeight),
      ),
    );
  }
}

/// A shimmer skeleton for card-style layouts (grid view, stat cards, etc.)
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.height = 120,
    this.width = double.infinity,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppTheme.darkSurfaceVariant : const Color(0xFFE8E8ED);
    final highlight = isDark ? AppTheme.darkCard : Colors.white;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: base,
          borderRadius: AppSpacing.roundedLg,
        ),
      ),
    );
  }
}

/// A shimmer skeleton for stat card grids (dashboard overview).
class SkeletonStatGrid extends StatelessWidget {
  const SkeletonStatGrid({
    super.key,
    this.count = 6,
    this.crossAxisCount = 2,
  });

  final int count;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppTheme.darkSurfaceVariant : const Color(0xFFE8E8ED);
    final highlight = isDark ? AppTheme.darkCard : Colors.white;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.2,
        ),
        itemCount: count,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: base,
            borderRadius: AppSpacing.roundedLg,
          ),
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: height * 0.7,
          height: height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedSm,
                ),
              ),
              AppSpacing.gapSm,
              Container(
                height: 12,
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedSm,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
