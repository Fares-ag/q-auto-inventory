import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_application_1/widgets/items_screen.dart';
import 'package:flutter_application_1/widgets/dashboard_screen.dart';
import 'package:flutter_application_1/widgets/items_detail.dart'; // ADDED for QRScannerPage
import 'package:flutter_application_1/widgets/menu_screen.dart';
import 'package:flutter_application_1/widgets/alerts_screen.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/item_service.dart';
import 'package:flutter_application_1/config/app_theme.dart';
import 'package:flutter_application_1/providers/app_state_provider.dart';
import 'package:flutter_application_1/providers/item_provider.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _updateItem(ItemModel updatedItem) async {
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      await itemProvider.updateItem(updatedItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update item: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // UPDATED: Scan function now uses Firestore to find items
  void _handleScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRScannerPage(
          onScan: (scannedCode) async {
            try {
              final foundItem = await ItemService.getItemByQrCode(scannedCode);
              if (foundItem != null && mounted) {
                _navigateToItemDetails(foundItem);
              } else if (mounted) {
                _showScannedDialog(scannedCode);
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error searching for item: ${e.toString()}'),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
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
      body: Consumer2<AppStateProvider, ItemProvider>(
        builder: (context, appState, itemProvider, child) {
          // Show loading indicator on initial load
          if (appState.isLoading && appState.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Handle errors
          if (appState.error != null && appState.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading data',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.error!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => appState.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Use IndexedStack to preserve state and prevent rebuilds
          return IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardScreen(
                allItems: appState.items,
                recentHistory: appState.recentHistory.take(10).toList(),
                openIssues: appState.openIssues,
                onNavigateToItems: () => _onItemTapped(1),
              ),
              ItemsScreen(
                items: appState.items,
                onUpdateItem: _updateItem,
                navigateToItemDetails: _navigateToItemDetails,
              ),
              const AlertsScreen(),
              const MenuScreen(),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _handleScan,
          child:
              const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
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
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color:
                    isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                    isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
