import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/firestore_models.dart';
import '../../providers/service_providers.dart';
import '../../providers/permission_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_spacing.dart';
import '../../utils/operator_layout.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_list.dart';

final _alertsDataProvider = FutureProvider.autoDispose<_AlertsData>((ref) async {
  final issueSvc = ref.watch(issueServiceProvider);
  final issues = await issueSvc.listOpenIssues(limit: 20);
  return _AlertsData(openIssues: issues);
});

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(_alertsDataProvider);
    final compact = isOperatorLayoutRole(
        ref.watch(currentUserDataProvider).valueOrNull?.role);
    final sectionGap = compact ? AppSpacing.gapMd : AppSpacing.gapLg;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(_alertsDataProvider),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Padding(
          padding: AppSpacing.pagePadding,
          child: SkeletonList(itemCount: 6, itemHeight: 72),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Failed to load alerts',
              message: err.toString(),
              iconColor: AppTheme.error,
              action: FilledButton.icon(
                onPressed: () => ref.invalidate(_alertsDataProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_alertsDataProvider),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              compact ? AppSpacing.lg + AppSpacing.sm : AppSpacing.xl2,
            ),
            children: [
              Text(
                'Open issues and reminders. Push notifications are not enabled yet.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
              AppSpacing.gapMd,
              _SectionCard(
                title: 'Open Issues',
                count: data.openIssues.length,
                icon: Icons.warning_amber_rounded,
                iconColor: AppTheme.warning,
                child: data.openIssues.isEmpty
                    ? const EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'No open issues',
                        compact: true,
                        iconColor: AppTheme.success,
                      )
                    : Column(
                        children: data.openIssues
                            .map((issue) => _IssueTile(issue: issue))
                            .toList(),
                      ),
              ),
              sectionGap,
              _SectionCard(
                title: 'Upcoming Reminders',
                count: data.upcomingReminders.length,
                icon: Icons.notifications_active_rounded,
                iconColor: AppTheme.info,
                child: data.upcomingReminders.isEmpty
                    ? const EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'No upcoming reminders',
                        compact: true,
                      )
                    : Column(
                        children: data.upcomingReminders
                            .map((r) => _ReminderTile(reminder: r))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertsData {
  const _AlertsData({
    this.openIssues = const [],
    // ignore: unused_element_parameter
    this.upcomingReminders = const [],
  });

  final List<Issue> openIssues;
  final List<ReminderInfo> upcomingReminders;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.icon,
    required this.iconColor,
    this.count,
  });

  final String title;
  final Widget child;
  final IconData icon;
  final Color iconColor;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppTheme.lightBorder, width: 1),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                AppSpacing.hGapMd,
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (count != null && count! > 0) ...[
                  AppSpacing.hGapSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context) {
    final priority = (issue.priority ?? 'medium').toLowerCase();
    final Color priorityColor;
    if (priority == 'high' || priority == 'critical') {
      priorityColor = AppTheme.error;
    } else if (priority == 'medium') {
      priorityColor = AppTheme.warning;
    } else {
      priorityColor = AppTheme.secondary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: AppSpacing.roundedSm,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                Text(
                  'Priority: ${issue.priority ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: priorityColor,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});

  final ReminderInfo reminder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppTheme.infoContainer,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: const Icon(Icons.notifications_rounded,
                size: 16, color: AppTheme.info),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                if (reminder.dueDate != null)
                  Text(
                    reminder.dueDate!.toLocal().toString().split(' ').first,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}

class ReminderInfo {
  const ReminderInfo({required this.title, this.dueDate});

  final String title;
  final DateTime? dueDate;
}
