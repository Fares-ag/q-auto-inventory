import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/firestore_models.dart';
import '../services/firebase_services.dart';

class ItemActionDialogs {
  static Future<void> showEditShelfLifeDialog(
    BuildContext context,
    InventoryItem item,
  ) async {
    final shelfLifeController = TextEditingController(
      text: item.customFields?['shelfLife']?.toString() ?? '',
    );
    final expiryDateController = TextEditingController(
      text: item.customFields?['expiryDate']?.toString() ?? '',
    );
    DateTime? expiryDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Shelf Life'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: shelfLifeController,
              decoration: const InputDecoration(
                labelText: 'Shelf Life (e.g., 2 years, 6 months)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: expiryDateController,
              decoration: const InputDecoration(
                labelText: 'Expiry Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (picked != null) {
                  expiryDate = picked;
                  expiryDateController.text =
                      '${picked.day}/${picked.month}/${picked.year}';
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final catalog = context.read<CatalogService>();
        final currentCustomFields = Map<String, dynamic>.from(item.customFields ?? {});
        currentCustomFields['shelfLife'] = shelfLifeController.text.trim();
        if (expiryDate != null) {
          currentCustomFields['expiryDate'] = expiryDate!.toIso8601String();
        }
        await catalog.updateItem(item.id, {
          'customFields': currentCustomFields,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shelf life updated')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        shelfLifeController.dispose();
        expiryDateController.dispose();
      }
    } else {
      shelfLifeController.dispose();
      expiryDateController.dispose();
    }
  }

  static Future<void> showEditConditionDialog(
    BuildContext context,
    InventoryItem item,
  ) async {
    final conditionController = TextEditingController(
      text: item.customFields?['condition']?.toString() ?? '',
    );
    String? selectedCondition = item.customFields?['condition']?.toString();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Condition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'excellent', child: Text('Excellent')),
                DropdownMenuItem(value: 'good', child: Text('Good')),
                DropdownMenuItem(value: 'fair', child: Text('Fair')),
                DropdownMenuItem(value: 'poor', child: Text('Poor')),
                DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
              ],
              onChanged: (value) => selectedCondition = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: conditionController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final catalog = context.read<CatalogService>();
        final currentCustomFields = Map<String, dynamic>.from(item.customFields ?? {});
        currentCustomFields['condition'] = selectedCondition ?? conditionController.text.trim();
        currentCustomFields['conditionNotes'] = conditionController.text.trim();
        await catalog.updateItem(item.id, {
          'customFields': currentCustomFields,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Condition updated')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        conditionController.dispose();
      }
    } else {
      conditionController.dispose();
    }
  }

  static Future<void> showWarrantyDialog(
    BuildContext context,
    InventoryItem item,
  ) async {
    final providerController = TextEditingController(
      text: item.customFields?['warrantyProvider']?.toString() ?? '',
    );
    DateTime? warrantyExpiry = item.warrantyExpiry;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set/Update Warranty'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: providerController,
                decoration: const InputDecoration(
                  labelText: 'Warranty Provider',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Warranty Expiry'),
                subtitle: Text(warrantyExpiry == null
                    ? 'Not set'
                    : '${warrantyExpiry!.day}/${warrantyExpiry!.month}/${warrantyExpiry!.year}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (warrantyExpiry != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => warrantyExpiry = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: warrantyExpiry ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) {
                          setState(() => warrantyExpiry = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final catalog = context.read<CatalogService>();
        final currentCustomFields = Map<String, dynamic>.from(item.customFields ?? {});
        currentCustomFields['warrantyProvider'] = providerController.text.trim();
        final updates = <String, dynamic>{
          'customFields': currentCustomFields,
        };
        if (warrantyExpiry != null) {
          updates['warrantyExpiry'] = warrantyExpiry;
        }
        await catalog.updateItem(item.id, updates);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Warranty updated')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        providerController.dispose();
      }
    } else {
      providerController.dispose();
    }
  }

  static Future<void> showMaintenanceDialog(
    BuildContext context,
    InventoryItem item,
  ) async {
    final notesController = TextEditingController();
    DateTime? nextMaintenance;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Schedule Maintenance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Next Maintenance Date'),
                subtitle: Text(nextMaintenance == null
                    ? 'Not set'
                    : '${nextMaintenance!.day}/${nextMaintenance!.month}/${nextMaintenance!.year}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (nextMaintenance != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => nextMaintenance = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: nextMaintenance ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setState(() => nextMaintenance = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Maintenance Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final catalog = context.read<CatalogService>();
        final currentCustomFields = Map<String, dynamic>.from(item.customFields ?? {});
        currentCustomFields['lastMaintenance'] = DateTime.now().toIso8601String();
        currentCustomFields['maintenanceNotes'] = notesController.text.trim();
        if (nextMaintenance != null) {
          currentCustomFields['nextMaintenance'] = nextMaintenance!.toIso8601String();
        }
        final updates = <String, dynamic>{
          'customFields': currentCustomFields,
        };
        if (nextMaintenance != null) {
          updates['lastServicedAt'] = DateTime.now();
        }
        await catalog.updateItem(item.id, updates);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maintenance scheduled')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        notesController.dispose();
      }
    } else {
      notesController.dispose();
    }
  }

  static Future<void> showAddReminderDialog(
    BuildContext context,
    InventoryItem item,
  ) async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? reminderDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Reminder Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Reminder Date'),
                subtitle: Text(reminderDate == null
                    ? 'Not set'
                    : '${reminderDate!.day}/${reminderDate!.month}/${reminderDate!.year}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: reminderDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setState(() => reminderDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: titleController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      try {
        final catalog = context.read<CatalogService>();
        final currentCustomFields = Map<String, dynamic>.from(item.customFields ?? {});
        final reminders = (currentCustomFields['reminders'] as List?) ?? [];
        reminders.add({
          'title': titleController.text.trim(),
          'date': reminderDate?.toIso8601String(),
          'notes': notesController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
        currentCustomFields['reminders'] = reminders;
        await catalog.updateItem(item.id, {
          'customFields': currentCustomFields,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder added')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        titleController.dispose();
        notesController.dispose();
      }
    } else {
      titleController.dispose();
      notesController.dispose();
    }
  }
}

