import 'package:flutter/material.dart';
import '../../widgets/permission_guard.dart';

import '../../widgets/offline_indicator.dart';
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

  late final List<Widget> _pages = <Widget>[
    const DashboardScreen(),
    const ItemsScreen(),
    const AlertsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
            ItemManagementOnly(
              child: ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Print QR Codes'),
                subtitle: const Text('Generate and print QR codes for items'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(BulkQrPrintScreen.routeName);
                },
              ),
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
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
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
      bottomNavigationBar: BottomAppBar(
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
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
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
                icon: Icons.notifications_none,
                activeIcon: Icons.notifications,
                label: 'Alerts',
                activeColor: colorScheme.primary,
              ),
              _NavigationButton(
                index: 3,
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
