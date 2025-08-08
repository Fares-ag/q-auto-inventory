import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/items_screen.dart';
import 'package:flutter_application_1/widgets/dashboard_screen.dart';
import 'package:flutter_application_1/widgets/item_model.dart';
import 'package:flutter_application_1/widgets/issue_model.dart';
import 'package:flutter_application_1/widgets/history_entry_model.dart';
import 'dart:math';

// This is the new root screen that manages the persistent bottom navigation.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Dummy data to pass to the screens
  final List<ItemModel> dummyItems = [
    ItemModel(
      id: "21252565",
      name: 'Macbook pro 13"',
      category: "Laptop",
      variants: "2 Variants",
      supplier: "Apple MacBook Air",
      company: "Sawa Technologies",
      date: "Tue 1 Aug 2025, 10:00",
      itemType: ItemType.laptop,
    ),
    ItemModel(
      id: "21252566",
      name: "Mechanical Keyboard",
      category: "Keyboard",
      variants: "1 Variant",
      supplier: "Gaming Keyboard",
      company: "Tech Solutions",
      date: "Mon 31 Jul 2025, 14:30",
      itemType: ItemType.keyboard,
    ),
    ItemModel(
      id: "21252567",
      name: 'Office Chair',
      category: "Furniture",
      variants: "1 Variant",
      supplier: "IKEA",
      company: "Sawa Technologies",
      date: "Thu 3 Aug 2025, 11:00",
      itemType: ItemType.furniture,
      isTagged: true,
      isSeenToday: true,
    ),
    ItemModel(
      id: "21252568",
      name: 'Monitor Stand',
      category: "Accessory",
      variants: "1 Variant",
      supplier: "AmazonBasics",
      company: "Tech Solutions",
      date: "Wed 2 Aug 2025, 09:00",
      itemType: ItemType.monitor,
    ),
    ItemModel(
      id: "21252569",
      name: 'Wacom Tablet',
      category: "Tablet",
      variants: "1 Variant",
      supplier: "Wacom",
      company: "Sawa Technologies",
      date: "Fri 4 Aug 2025, 15:00",
      itemType: ItemType.tablet,
      isWrittenOff: true,
    ),
    ItemModel(
      id: "21252570",
      name: 'Webcam C920',
      category: "Accessory",
      variants: "1 Variant",
      supplier: "Logitech",
      company: "Tech Solutions",
      date: "Fri 4 Aug 2025, 16:00",
      itemType: ItemType.webcam,
      isSeenToday: true,
      isTagged: true,
    ),
  ];

  final List<HistoryEntry> dummyHistory = [
    HistoryEntry(
        title: 'Item Created',
        description: 'Macbook pro 13" added.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
    HistoryEntry(
        title: 'Item Checked Out',
        description: 'Webcam C920 checked out to Joe.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2))),
  ];

  final List<Issue> dummyIssues = [
    Issue(
        issueId: '1',
        description: 'Keyboard is missing a key.',
        priority: 'High',
        createdAt: DateTime.now()),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  _onItemTapped(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text('Items'),
                onTap: () {
                  _onItemTapped(1);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          DashboardScreen(
            allItems: dummyItems,
            recentHistory: dummyHistory,
            openIssues: dummyIssues,
            onNavigateToItems: () {
              _onItemTapped(1);
            },
          ),
          ItemsScreen(
            items: dummyItems,
            dummyHistory: dummyHistory,
            dummyIssues: dummyIssues,
            onScan: () {
              // This is a placeholder for the scan action
              print('Scan action triggered from RootScreen');
            },
            onAdd: (newItem) {
              setState(() {
                dummyItems.add(newItem);
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Items', 0,
                onTap: () => _onItemTapped(0)),
            _buildNavItem(Icons.apps, 'Organise', 1,
                onTap: () {}), // Placeholder
            _buildScanButton(),
            _buildNavItem(Icons.warning_outlined, 'Alerts', 3,
                onTap: () {}), // Placeholder
            _buildNavItem(Icons.menu, 'Menu', 4, onTap: _showMenu),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      {VoidCallback? onTap}) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.black : Colors.grey[500],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () {
        // Placeholder for Scan action
        print('Scan action triggered from RootScreen');
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
