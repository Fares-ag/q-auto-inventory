import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/firestore_models.dart';
import '../../providers/data_providers.dart';
import '../../providers/service_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';

class ApprovalQueueScreen extends ConsumerWidget {
  const ApprovalQueueScreen({super.key});

  Future<void> _handleDecision(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
    bool approve,
  ) async {
    final catalog = ref.read(catalogServiceProvider);
    final status = approve ? 'active' : 'rejected';
    await catalog.updateItemStatus(item.id, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              approve ? 'Approved ${item.name}' : 'Rejected ${item.name}'),
          backgroundColor:
              approve ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Uses Riverpod StreamProvider — no more context.watch<CatalogService>()
    // so only approval-queue changes cause rebuilds, not the whole CatalogService.
    final approvalsAsync = ref.watch(pendingApprovalsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Queue'),
        actions: [
          approvalsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: items.isEmpty
                      ? AppTheme.successContainer
                      : AppTheme.warningContainer,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  '${items.length} pending',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: items.isEmpty
                            ? AppTheme.success
                            : AppTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ItemManagementOnly(
        showError: true,
        child: approvalsAsync.when(
          loading: () => const Padding(
            padding: AppSpacing.pagePadding,
            child: SkeletonList(itemCount: 8, itemHeight: 80),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48, color: cs.error),
                  AppSpacing.gapLg,
                  Text('Failed to load approvals',
                      style: Theme.of(context).textTheme.titleMedium),
                  AppSpacing.gapSm,
                  Text(err.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'All caught up!',
                message: 'No items are awaiting approval.',
                iconColor: AppTheme.success,
              );
            }
            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: items.length,
              separatorBuilder: (_, __) => AppSpacing.gapSm,
              itemBuilder: (context, index) {
                final item = items[index];
                return _ApprovalCard(
                  item: item,
                  onApprove: () =>
                      _handleDecision(context, ref, item, true),
                  onReject: () =>
                      _handleDecision(context, ref, item, false),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final InventoryItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppTheme.warningContainer, width: 1.5),
      ),
      child: Padding(
        padding: AppSpacing.cardPaddingSmall,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.warningContainer,
                borderRadius: AppSpacing.roundedMd,
              ),
              child: const Icon(Icons.pending_actions_rounded,
                  color: AppTheme.warning, size: 20),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall),
                  AppSpacing.gapXs,
                  Text(
                    'Category: ${item.categoryId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded),
                  color: AppTheme.success,
                  tooltip: 'Approve',
                  onPressed: onApprove,
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_rounded),
                  color: AppTheme.error,
                  tooltip: 'Reject',
                  onPressed: onReject,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
