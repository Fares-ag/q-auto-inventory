import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/app_router.dart';
import '../../providers/permission_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/auth_session_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_spacing.dart';
import '../../utils/date_formatter.dart';
import '../../utils/operator_layout.dart';
import '../../widgets/permission_guard.dart';
import '../settings/settings_screen.dart';
import 'activity_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userDataAsync = ref.watch(currentUserDataProvider);
    final userCreated = user?.metadata.creationTime;
    final lastSignIn = user?.metadata.lastSignInTime;

    final role = userDataAsync.valueOrNull?.role ?? 'Unknown';
    final compact = isOperatorLayoutRole(userDataAsync.valueOrNull?.role);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          compact ? AppSpacing.lg : AppSpacing.xl2,
        ),
        children: [
          _ProfileHeader(
            name: user?.displayName ??
                (user?.email?.split('@').first ?? 'Operator'),
            email: user?.email ?? 'Unknown',
            role: role,
            userId: user?.uid ?? 'Unknown',
            created: userCreated,
            lastSignIn: lastSignIn,
            compact: compact,
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          _MenuTile(
            icon: Icons.history_rounded,
            title: 'View Activity History',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ActivityHistoryScreen())),
          ),
          AppSpacing.gapSm,
          _MenuTile(
            icon: Icons.settings_rounded,
            title: 'Settings',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          AppSpacing.gapSm,
          AdminOnly(
            child: _MenuTile(
              icon: Icons.dashboard_customize_rounded,
              title: 'Super Admin Dashboard',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.superAdminRoute),
            ),
          ),
          SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl2),
          FilledButton.icon(
            onPressed: () async {
              await signOutAndClearSession(
                permissionService: ref.read(permissionServiceProvider),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out')),
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
    required this.userId,
    this.created,
    this.lastSignIn,
    this.compact = false,
  });

  final String name;
  final String email;
  final String role;
  final String userId;
  final DateTime? created;
  final DateTime? lastSignIn;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? null : AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: compact ? 26 : 32,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  initials,
                    style: TextStyle(
                      fontSize: compact ? 20 : 24,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                ),
              ),
              AppSpacing.hGapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    AppSpacing.gapXs,
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    AppSpacing.gapXs,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Text(
                        role,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (created != null) ...[
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            Divider(color: cs.outlineVariant, height: 1),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    label: 'Member since',
                    value: DateFormatter.formatDate(created),
                  ),
                ),
                if (lastSignIn != null)
                  Expanded(
                    child: _InfoRow(
                      label: 'Last sign in',
                      value: DateFormatter.formatRelative(lastSignIn),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
          AppSpacing.gapXs,
          Text(value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  )),
        ],
      );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedLg,
      child: Container(
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
              child: Icon(icon, size: 20, color: cs.primary),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      )),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.lightTextTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
