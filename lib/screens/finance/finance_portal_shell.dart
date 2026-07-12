import 'package:flutter/material.dart';

import '../../widgets/offline_indicator.dart';
import '../../widgets/swipeable_tab_view.dart';
import '../items/items_screen.dart';
import '../profile/profile_screen.dart';
import '../qr/qr_scanner_screen.dart';
import 'finance_dashboard_screen.dart';

/// Finance Portal Shell - Custom navigation for finance users
class FinancePortalShell extends StatefulWidget {
  const FinancePortalShell({super.key});

  @override
  State<FinancePortalShell> createState() => _FinancePortalShellState();
}

class _FinancePortalShellState extends State<FinancePortalShell> {
  static const int _tabCount = 3;

  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  /// Only build tabs after first visit. Adjacent tabs are pre-marked so the
  /// swipe-peek frame never renders an empty SizedBox while sliding.
  final Set<int> _visitedTabs = {0, 1};
  final Map<int, Widget> _pageCache = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _pageForIndex(int index) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    return _pageCache.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return const FinanceDashboardScreen();
        case 1:
          return const ItemsScreen();
        case 2:
          return const ProfileScreen();
        default:
          return const FinanceDashboardScreen();
      }
    });
  }

  void _markVisited(int index) {
    _visitedTabs.add(index);
    if (index - 1 >= 0) _visitedTabs.add(index - 1);
    if (index + 1 < _tabCount) _visitedTabs.add(index + 1);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _markVisited(index);
    });
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR Code'),
              subtitle: const Text('Scan a QR code to view item details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          _showQrOptions(context);
        },
        child: const Icon(Icons.qr_code_2, size: 28),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavigationButton(
                index: 0,
                selectedIndex: _selectedIndex,
                onTap: _onItemTapped,
                icon: Icons.account_balance,
                activeIcon: Icons.account_balance,
                label: 'Finance',
                activeColor: colorScheme.primary,
              ),
              _NavigationButton(
                index: 1,
                selectedIndex: _selectedIndex,
                onTap: _onItemTapped,
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: 'Items',
                activeColor: colorScheme.primary,
              ),
              const SizedBox(width: 56),
              _NavigationButton(
                index: 2,
                selectedIndex: _selectedIndex,
                onTap: _onItemTapped,
                icon: Icons.menu,
                activeIcon: Icons.menu_open,
                label: 'Menu',
                activeColor: colorScheme.primary,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.activeColor,
  });

  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == selectedIndex;
    final Color color = isSelected ? activeColor : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

