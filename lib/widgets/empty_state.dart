import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/app_spacing.dart';

/// Canonical empty state widget. Use this everywhere instead of
/// ad-hoc Column(icon + Text) patterns so the UX is consistent.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconColor,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? iconColor;

  /// Use compact=true for smaller contexts (e.g., inside a card).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? cs.primary.withOpacity(0.4);
    final iconSize = compact ? 48.0 : 72.0;
    final padding = compact ? AppSpacing.xl2 : AppSpacing.xl4;
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleLarge;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl2),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: effectiveIconColor),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            Text(
              title,
              style: titleStyle?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTextSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl2),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
