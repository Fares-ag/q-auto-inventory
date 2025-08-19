// lib/widgets/root_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/widgets/dashboard_screen.dart';
import 'package:flutter_application_1/widgets/items_screen.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:flutter_application_1/widgets/user_profile_screen.dart';
import 'package:flutter_application_1/widgets/alerts_screen.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The main screen of the application that holds the bottom navigation bar
/// and orchestrates the navigation between the primary pages (Dashboard, Items, etc.).
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  /// Tracks the index of the currently selected tab in the bottom navigation bar.
  int _selectedIndex = 0;

  /// Controls the PageView, allowing for programmatic page transitions.
  final PageController _pageController = PageController();

  /// Handles tap events on the bottom navigation bar items.
  void _onItemTapped(int index) {
    // Special case for the 'Menu' tab (index 3). It pushes a new screen
    // instead of switching the PageView.
    if (index == 3) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: LocalDataStore(),
          child: const UserProfileScreen(),
        ),
      ));
      return; // Exit the function to prevent changing the page view.
    }

    // Special case for the 'Alerts' tab (index 2). It also pushes a new screen.
    if (index == 2) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: LocalDataStore(),
          child: const AlertsScreen(),
        ),
      ));
      return; // Exit the function.
    }

    // For Dashboard (0) and Items (1), update the state and animate the PageView.
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  /// Navigates to the details screen for a given item.
  /// This function is passed down to child widgets that need to trigger this navigation.
  void _navigateToItemDetails(ItemModel item) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value:
            LocalDataStore(), // Provide the data store to the details screen.
        child: ItemDetailsScreen(
          item: item,
          onUpdateItem: (updatedItem) =>
              LocalDataStore().updateItem(updatedItem),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Provides the LocalDataStore instance to all descendant widgets in the tree.
    // This is the root of the app's state management via Provider.
    return ChangeNotifierProvider<LocalDataStore>.value(
      value: LocalDataStore(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        // Consumer widget listens for changes in LocalDataStore and rebuilds the UI.
        body: Consumer<LocalDataStore>(
          builder: (context, dataStore, child) {
            // Retrieve the latest data from the data store.
            final items = dataStore.items;
            final openIssues = dataStore.issues
                .where((issue) => issue.status == IssueStatus.Open)
                .toList();
            final recentHistory = dataStore.history;

            // Stack allows layering widgets, used here to show an "Offline Mode" banner
            // on top of the main content.
            return Stack(
              children: [
                PageView(
                  controller: _pageController,
                  // Updates the selected index when the user swipes between pages.
                  onPageChanged: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  // The list of main screens managed by the PageView.
                  children: [
                    DashboardScreen(
                      allItems: items,
                      openIssues: openIssues,
                      recentHistory: recentHistory.take(5).toList(),
                      onNavigateToItems: () =>
                          _onItemTapped(1), // Navigate to Items screen.
                      onUpdateItem: dataStore.updateItem,
                    ),
                    ItemsScreen(
                      items: items,
                      onUpdateItem: dataStore.updateItem,
                      navigateToItemDetails: _navigateToItemDetails,
                    ),
                    // These are placeholders in the PageView; their actual screens are pushed
                    // as new routes in the _onItemTapped method.
                    const AlertsScreen(),
                    const UserProfileScreen(),
                  ],
                ),
                // Conditionally display an "Offline Mode" banner if the device is offline.
                if (!dataStore.isOnline)
                  Positioned(
                    top: MediaQuery.of(context).padding.top +
                        56, // Position below app bar.
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Center(
                        child: Text(
                          'Offline Mode (changes not saved)',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Scan QR Code')),
                body: Stack(
                  children: [
                    MobileScanner(
                      onDetect: (capture) {
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty &&
                            barcodes.first.rawValue != null) {
                          ItemModel item;
                          try {
                            item = LocalDataStore().items.firstWhere(
                                (i) => i.qrCodeId == barcodes.first.rawValue);
                            Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                              builder: (context) =>
                                  ChangeNotifierProvider.value(
                                value: LocalDataStore(),
                                child: ItemDetailsScreen(
                                  item: item,
                                  onUpdateItem: (updatedItem) =>
                                      LocalDataStore().updateItem(updatedItem),
                                ),
                              ),
                            ));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('No item found for scanned QR code.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                    Center(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 48,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Align QR code within the frame',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
          },
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          elevation: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined),
              _buildNavItem(1, 'Items', Icons.inventory_2_outlined),
              const SizedBox(width: 48),
              _buildNavItem(2, 'Alerts', Icons.warning_outlined),
              _buildNavItem(3, 'Menu', Icons.menu),
            ],
          ),
        ),
      ),
    );
  }

  /// A helper widget to build each navigation item in the BottomAppBar.
  Widget _buildNavItem(int index, String label, IconData icon) {
    // An item is considered selected if its index matches the current state.
    // The 'Menu' item (index 3) is never shown as selected because it pushes a new screen.
    bool isSelected = (_selectedIndex == index) && (index != 3);
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
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
