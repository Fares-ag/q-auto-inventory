// lib/widgets/item_creation_success_screen.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Screen shown after successfully creating a new item.
/// Displays a QR code representing the item's ID and provides
/// an option to print the label for physical tagging.
class ItemCreationSuccessScreen extends StatelessWidget {
  final String itemId; // The unique ID of the newly created item

  const ItemCreationSuccessScreen({Key? key, required this.itemId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Item Created Successfully"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          // Close this screen and navigate back to the main/root screen
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instruction text for the user
              const Text(
                "Print this QR code and attach it to your new item.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              // QR code widget representing the item's unique ID
              QrImageView(
                data: itemId,
                version: QrVersions.auto,
                size: 250.0,
              ),
              const SizedBox(height: 20),
              // Display the item ID below the QR code
              Text(
                "ID: $itemId",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              // Button to trigger printing functionality (currently placeholder)
              ElevatedButton.icon(
                onPressed: () {
                  // Show a temporary snackbar for print action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Printing functionality would be here.")),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text("Print Label"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
