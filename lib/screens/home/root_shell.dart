import 'package:flutter/material.dart';

import '../../widgets/offline_indicator.dart';
import '../../widgets/swipeable_tab_view.dart';
import '../alerts/alerts_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../items/items_screen.dart';
import '../profile/profile_screen.dart';
import '../qr/bulk_qr_print_screen.dart';
import '../qr/qr_scanner_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  /// Only build tabs the user has visited (or is about to peek via swipe).
  /// Adjacent tabs are eagerly marked so the swipe-preview never shows blank.
  final Set<int> _visitedTabs = {0, 1};
  final Map<int, Widget> _pageCache = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 4 tabs split 2 + FAB + 2: [Dashboard, Items] | QR FAB | [Alerts, Profile]
  static const _tabCount = 4;

  static const List<({IconData icon, IconData activeIcon, String label})>
      _tabs = [
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    (
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Items',
    ),
    (
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
      label: 'Alerts',
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  Widget _pageForIndex(int index) {
    if (!_visitedTabs.contains(index)) return const SizedBox.shrink();
    return _pageCache.putIfAbsent(index, () => switch (index) {
          0 => const DashboardScreen(),
          1 => const ItemsScreen(),
          2 => const AlertsScreen(),
          3 => const ProfileScreen(),
          _ => const DashboardScreen(),
        });
  }

  /// Mark [index] and its immediate neighbours as visited so the swipe-peek
  /// frame doesn't render an empty SizedBox while sliding.
  void _markVisited(int index) {
    _visitedTabs.add(index);
    if (index - 1 >= 0) _visitedTabs.add(index - 1);
    if (index + 1 < _tabCount) _visitedTabs.add(index + 1);
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _markVisited(index);
    });
    // Jump (no animation) so far hops don't render every intermediate page.
    // Adjacent hops still feel snappy because the icon animates and the page
    // cuts cleanly without an awkward slide-through.
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _markVisited(index);
    });
  }

  void _showQrOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.qr_code_scanner_rounded,
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Scan QR Code'),
                subtitle: const Text('View item details by scanning'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.print_rounded,
                      color: Theme.of(context).colorScheme.secondary),
                ),
                title: const Text('Print QR Codes'),
                subtitle: const Text('Generate and print QR codes'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(BulkQrPrintScreen.routeName);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SwipeableTabView(
              controller: _pageController,
              itemCount: _tabCount,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => _pageForIndex(index),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: const CircleBorder(),
        elevation: 2,
        onPressed: () => _showQrOptions(context),
        tooltip: 'QR Code',
        child: const Icon(Icons.qr_code_2_rounded, size: 28),
      ),
      bottomNavigationBar: DecoratedBox(
        // Hairline separator above the tab bar — iOS tab-bar tell-tale.
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                index: 0,
                selectedIndex: _selectedIndex,
                onTap: _onDestinationSelected,
                tab: _tabs[0],
                activeColor: cs.primary,
              ),
              _NavButton(
                index: 1,
                selectedIndex: _selectedIndex,
                onTap: _onDestinationSelected,
                tab: _tabs[1],
                activeColor: cs.primary,
              ),
              // Spacer for the centered FAB notch.
              const SizedBox(width: 56),
              _NavButton(
                index: 2,
                selectedIndex: _selectedIndex,
                onTap: _onDestinationSelected,
                tab: _tabs[2],
                activeColor: cs.primary,
              ),
              _NavButton(
                index: 3,
                selectedIndex: _selectedIndex,
                onTap: _onDestinationSelected,
                tab: _tabs[3],
                activeColor: cs.primary,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.tab,
    required this.activeColor,
  });

  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final ({IconData icon, IconData activeIcon, String label}) tab;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final color = isSelected ? activeColor : Theme.of(context).hintColor;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? tab.activeIcon : tab.icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
