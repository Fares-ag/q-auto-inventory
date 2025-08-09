import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_application_1/widgets/items_screen.dart';
import 'package:flutter_application_1/widgets/dashboard_screen.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:flutter_application_1/widgets/item_model.dart';
import 'package:flutter_application_1/widgets/issue_model.dart';
import 'package:flutter_application_1/widgets/history_entry_model.dart';

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
      qrCodeId: "qr_12345",
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
      qrCodeId: "qr_67890",
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

  // Method to update an item in the main list
  void _updateItem(ItemModel updatedItem) {
    setState(() {
      final index = dummyItems.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        dummyItems[index] = updatedItem;
      }
    });
  }

  // The main scan function for the floating action button
  Future<void> _handleScan() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.QR);

    if (barcodeScanRes != '-1' && barcodeScanRes.isNotEmpty) {
      final item = dummyItems.firstWhere(
        (i) => i.qrCodeId == barcodeScanRes,
        orElse: () => ItemModel(
            id: '',
            name: '',
            category: '',
            variants: '',
            supplier: '',
            company: '',
            date: '',
            itemType: ItemType.other),
      );

      if (item.id.isNotEmpty) {
        // If an item is found, navigate to its details screen
        _navigateToItemDetails(item);
      } else {
        // If no item is found, show a message
        _showScannedDialog(barcodeScanRes);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan cancelled')),
      );
    }
  }

  void _showScannedDialog(String barcode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code Scanned'),
          content: Text(
              'The scanned QR code is: $barcode. It is not yet tagged to an item.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToItemDetails(ItemModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailsScreen(
          item: item,
          onUpdateItem: _updateItem,
        ),
      ),
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
            onNavigateToItems: () => _onItemTapped(1),
          ),
          ItemsScreen(
            items: dummyItems,
            dummyHistory: dummyHistory,
            dummyIssues: dummyIssues,
            onUpdateItem: _updateItem,
            navigateToItemDetails: _navigateToItemDetails,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: _handleScan,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined),
            _buildNavItem(1, 'Items', Icons.inventory_2_outlined),
            const SizedBox(width: 48), // The space for the FAB
            _buildNavItem(2, 'Alerts', Icons.warning_outlined),
            _buildNavItem(3, 'Menu', Icons.menu),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
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
}
