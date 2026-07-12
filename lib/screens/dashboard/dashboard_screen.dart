import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/firestore_models.dart';
import '../../providers/data_providers.dart';
import '../../providers/permission_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_spacing.dart';
import '../../utils/operator_layout.dart';
import '../../widgets/charts/enhanced_dashboard_charts.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';
import '../items/all_items_screen.dart';
import '../items/bulk_assign_screen.dart';
import '../../navigation/app_router.dart';

String? _dashboardActivitySubtitle(
    HistoryEntry entry, List<InventoryItem> items) {
  if (items.isEmpty) return entry.displaySubtitle;
  String? itemName;
  for (final i in items) {
    if (i.id == entry.itemId) {
      itemName = i.name;
      break;
    }
  }
  final detail = entry.displaySubtitle;
  if (itemName != null && itemName.isNotEmpty) {
    if (detail == null || detail.isEmpty) return itemName;
    if (detail.contains(itemName)) return detail;
    return '$itemName · $detail';
  }
  return detail;
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDataProvider);

    final title = userAsync.when(
      loading: () => 'Dashboard',
      error: (_, __) => 'Dashboard',
      data: (u) {
        final r = u?.role?.toLowerCase() ?? '';
        if (r.contains('finance')) return 'Finance Dashboard';
        if (r.contains('admin')) return 'Admin Dashboard';
        if (r.contains('operator')) return 'Operator Dashboard';
        return 'Dashboard';
      },
    );

    final compact = userAsync.maybeWhen(
      data: (u) => isOperatorLayoutRole(u?.role),
      orElse: () => false,
    );
    final sectionGap = compact ? AppSpacing.gapLg : AppSpacing.gapXl2;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(dashboardItemsProvider);
            ref.invalidate(dashboardHistoryProvider);
            ref.invalidate(dashboardIssuesCountProvider);
            ref.invalidate(departmentsProvider);
            ref.invalidate(categoriesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                  child: _DashboardHeader(title: title, compact: compact)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _OverviewSection(compact: compact),
                ),
              ),
              SliverToBoxAdapter(child: sectionGap),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _SectionHeader(title: 'Analytics'),
                ),
              ),
              SliverToBoxAdapter(child: AppSpacing.gapMd),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _ChartsSection(),
                ),
              ),
              SliverToBoxAdapter(child: sectionGap),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _SectionHeader(title: 'Quick Actions'),
                ),
              ),
              SliverToBoxAdapter(child: AppSpacing.gapMd),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _QuickActionsSection(),
                ),
              ),
              SliverToBoxAdapter(child: sectionGap),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _SectionHeader(title: 'Recent Activity'),
                ),
              ),
              SliverToBoxAdapter(child: AppSpacing.gapMd),
              const _ActivitySection(),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: rootShellTabScrollBottomInset(context,
                      compact: compact),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashboard header ──────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.title, this.compact = false});
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        compact ? AppSpacing.md : AppSpacing.xl,
        AppSpacing.lg,
        compact ? AppSpacing.lg : AppSpacing.xl2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                AppSpacing.gapXs,
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Icon(Icons.inventory_2_rounded,
                color: cs.primary, size: 24),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      );
}

// ── Overview stat grid - resolves stats + issues + departments independently ─

class _OverviewSection extends ConsumerWidget {
  const _OverviewSection({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final issuesAsync = ref.watch(dashboardIssuesCountProvider);
    final deptsAsync = ref.watch(departmentsProvider);

    final stats = statsAsync.valueOrNull ?? const DashboardStats.empty();
    final issuesCount = issuesAsync.valueOrNull ?? 0;
    final deptsCount = deptsAsync.valueOrNull?.length ?? 0;
    final isLoading = statsAsync.isLoading;

    final tiles = [
      _StatConfig(
        label: 'Total',
        value: stats.total.toString(),
        icon: Icons.inventory_2_rounded,
        color: AppTheme.primary,
        bg: AppTheme.primaryContainer,
        loading: isLoading,
      ),
      _StatConfig(
        label: 'Assigned',
        value: stats.assigned.toString(),
        icon: Icons.person_pin_rounded,
        color: AppTheme.statusAssigned,
        bg: AppTheme.statusAssignedBg,
        loading: isLoading,
      ),
      _StatConfig(
        label: 'Unassigned',
        value: stats.unassigned.toString(),
        icon: Icons.inbox_rounded,
        color: AppTheme.statusMaintenance,
        bg: AppTheme.statusMaintenanceBg,
        loading: isLoading,
      ),
      _StatConfig(
        label: 'Tagged',
        value: stats.tagged.toString(),
        icon: Icons.qr_code_rounded,
        color: AppTheme.info,
        bg: AppTheme.infoContainer,
        loading: isLoading,
      ),
      _StatConfig(
        label: 'Issues',
        value: issuesCount.toString(),
        icon: Icons.warning_amber_rounded,
        color: AppTheme.error,
        bg: AppTheme.errorContainer,
        loading: issuesAsync.isLoading,
      ),
      _StatConfig(
        label: 'Departments',
        value: deptsCount.toString(),
        icon: Icons.business_rounded,
        color: AppTheme.success,
        bg: AppTheme.successContainer,
        loading: deptsAsync.isLoading,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: compact ? AppSpacing.sm : AppSpacing.md,
        crossAxisSpacing: compact ? AppSpacing.sm : AppSpacing.md,
        // Fixed height avoids overflow from headlineSmall + label + padding when
        // aspect ratio would make cells too short (common on operator / phones).
        mainAxisExtent: compact ? 122 : 128,
      ),
      itemCount: tiles.length,
      itemBuilder: (ctx, i) => _StatCard(config: tiles[i]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.config});
  final _StatConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppTheme.lightBorder, width: 1),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: config.bg,
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Icon(config.icon, color: config.color, size: 18),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: config.loading
                  ? const _StatValuePlaceholder()
                  : FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        config.value,
                        maxLines: 1,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: config.color,
                                ),
                      ),
                    ),
            ),
          ),
          Text(
            config.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatValuePlaceholder extends StatelessWidget {
  const _StatValuePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 24,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Charts section - resolves once items + departments are ready ────────────

class _ChartsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(dashboardItemsProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final historyAsync = ref.watch(dashboardHistoryProvider);

    if (itemsAsync.isLoading || deptsAsync.isLoading) {
      return const SkeletonCard(height: 220);
    }
    if (itemsAsync.hasError) {
      return _SectionError(
        message: 'Failed to load chart data',
        onRetry: () => ref.invalidate(dashboardItemsProvider),
      );
    }

    final items = itemsAsync.valueOrNull ?? const [];
    final depts = deptsAsync.valueOrNull ?? const [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final history = historyAsync.valueOrNull ?? const [];
    final mergedHistory =
        mergeDashboardActivity(history, items, limit: 80);

    return RepaintBoundary(
      child: EnhancedDashboardCharts(
        items: items,
        departments: depts,
        categories: categories,
        history: mergedHistory,
      ),
    );
  }
}

// ── Quick actions - structure instant, items used only for "View All" tap ────

class _QuickActionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _ActionConfig(
        label: 'Add Item',
        icon: Icons.add_rounded,
        color: AppTheme.primary,
        bg: AppTheme.primaryContainer,
        requiresPermission: true,
        onTap: () => Navigator.of(context).pushNamed('/items/add'),
      ),
      _ActionConfig(
        label: 'Pending',
        icon: Icons.pending_actions_rounded,
        color: AppTheme.warning,
        bg: AppTheme.warningContainer,
        onTap: () => Navigator.of(context).pushNamed('/approvals'),
      ),
      _ActionConfig(
        label: 'View All',
        icon: Icons.view_list_rounded,
        color: AppTheme.info,
        bg: AppTheme.infoContainer,
        onTap: () {
          // Read on tap so we don't block the dashboard render on items load.
          final items = ref.read(dashboardItemsProvider).valueOrNull ?? const [];
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AllItemsScreen(items: items)),
          );
        },
      ),
      _ActionConfig(
        label: 'Bulk Assign',
        icon: Icons.grid_view_rounded,
        color: AppTheme.success,
        bg: AppTheme.successContainer,
        requiresPermission: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BulkAssignScreen()),
        ),
      ),
      _ActionConfig(
        label: 'Reports',
        icon: Icons.bar_chart_rounded,
        color: AppTheme.statusPending,
        bg: AppTheme.statusPendingBg,
        requiresReports: true,
        onTap: () => Navigator.of(context).pushNamed(AppRouter.reportsRoute),
      ),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions.map((a) {
        final btn = _ActionChip(config: a);
        if (a.requiresPermission) return ItemManagementOnly(child: btn);
        if (a.requiresReports) return ReportsOnly(child: btn);
        return btn;
      }).toList(),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.config});
  final _ActionConfig config;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: config.onTap,
      borderRadius: AppSpacing.roundedLg,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: config.bg,
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(color: config.color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 18, color: config.color),
            AppSpacing.hGapSm,
            Text(
              config.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: config.color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity section - independently resolved history ───────────────────────

class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(dashboardHistoryProvider);
    final items = ref.watch(dashboardItemsProvider).valueOrNull ?? const [];

    return historyAsync.when(
      loading: () => const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverToBoxAdapter(
          child: SkeletonList(itemCount: 4, itemHeight: 56),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _SectionError(
            message: 'Failed to load recent activity',
            onRetry: () => ref.invalidate(dashboardHistoryProvider),
          ),
        ),
      ),
      data: (history) {
        final rows = mergeDashboardActivity(history, items, limit: 12);
        if (rows.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.history_rounded,
              title: 'No recent activity',
              message: 'Actions you take will appear here.',
              compact: true,
            ),
          );
        }
        return SliverList.separated(
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _ActivityTile(
              entry: rows[i],
              resolvedSubtitle: _dashboardActivitySubtitle(rows[i], items),
            ),
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry, this.resolvedSubtitle});
  final HistoryEntry entry;
  final String? resolvedSubtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = entry.timestamp != null
        ? entry.timestamp!.toLocal().toString().split(' ').first
        : '';

    final subtitle = resolvedSubtitle ?? entry.displaySubtitle;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppTheme.lightBorder, width: 1),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Icon(Icons.history_rounded, size: 16, color: cs.primary),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Flexible(
            child: Text(
              dateStr,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable per-section error ──────────────────────────────────────────────

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: AppSpacing.roundedLg,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 20),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _StatConfig {
  const _StatConfig({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    this.loading = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final bool loading;
}

class _ActionConfig {
  const _ActionConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
    this.requiresPermission = false,
    this.requiresReports = false,
  });
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  final bool requiresPermission;
  final bool requiresReports;
}
