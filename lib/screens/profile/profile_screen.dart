import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../navigation/app_router.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/permission_guard.dart';
import '../settings/settings_screen.dart';
import 'activity_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userCreated = user?.metadata.creationTime;
    final lastSignIn = user?.metadata.lastSignInTime;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            name: user?.displayName ?? (user?.email?.split('@').first ?? 'Operator'),
            email: user?.email ?? 'Unknown',
            role: 'operator',
            userId: user?.uid ?? 'Unknown',
            created: userCreated,
            lastSignIn: lastSignIn,
          ),
          const SizedBox(height: 16),
          _MenuTile(
            icon: Icons.history,
            title: 'View Activity History',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()),
              );
            },
          ),
          _MenuTile(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
              AdminOnly(
                child: _MenuTile(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Super Admin Dashboard',
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRouter.superAdminRoute);
                  },
                ),
              ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out')),
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
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
  });

  final String name;
  final String email;
  final String role;
  final String userId;
  final DateTime? created;
  final DateTime? lastSignIn;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Role: $role', style: Theme.of(context).textTheme.bodySmall),
                  if (created != null) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Member since',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              Text(
                                DateFormatter.formatDate(created),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        if (lastSignIn != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last sign in',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                Text(
                                  DateFormatter.formatRelative(lastSignIn),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
