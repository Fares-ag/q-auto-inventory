import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

import '../models/firestore_models.dart';
import '../services/firebase_services.dart';
import '../services/image_upload_service.dart';
import '../services/offline_queue_service.dart';
import '../utils/network_utils.dart';
import '../utils/date_formatter.dart';
import 'empty_state.dart';
import 'signature_pad.dart';

class TransactionHistorySection extends StatefulWidget {
  const TransactionHistorySection({super.key, required this.itemId});

  final String itemId;

  @override
  State<TransactionHistorySection> createState() => _TransactionHistorySectionState();
}

class _TransactionHistorySectionState extends State<TransactionHistorySection> {
  Future<void> _checkIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to check in items')),
        );
      }
      return;
    }

    final notesController = TextEditingController();
    Uint8List? signatureBytes;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Check In Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final signature = await Navigator.of(context).push<Uint8List>(
                      MaterialPageRoute(
                        builder: (_) => SignaturePad(
                          title: 'Check In Signature',
                          onSignatureSaved: (sig) {
                            Navigator.of(context).pop(sig);
                          },
                        ),
                      ),
                    );
                    if (signature != null) {
                      setState(() => signatureBytes = signature);
                    }
                  },
                  icon: Icon(signatureBytes == null ? Icons.edit : Icons.check_circle),
                  label: Text(signatureBytes == null ? 'Add Signature' : 'Signature Added'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Check In'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        if (signatureBytes != null) {
          // Upload signature to Firebase Storage
          final uploadService = ImageUploadService();
          // Create a temporary file for signature
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(signatureBytes!);
          // TODO: Store signatureUrl in history entry when HistoryEntry model supports it
          await uploadService.uploadItemImage('signatures/${widget.itemId}', file);
        }

        final historyService = context.read<HistoryService>();
        final queue = context.read<OfflineQueueService>();
        final online = await NetworkUtils.hasInternetConnection();
        final job = () => historyService.recordCheckIn(
              widget.itemId,
              user.uid,
              notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
            );
        if (online) {
          await job();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item checked in')),
            );
          }
        } else {
          await queue.enqueue(job);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Offline: action queued to sync')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        // Dispose controller after use
        notesController.dispose();
      }
    } else {
      // Dispose controller if dialog was cancelled
      notesController.dispose();
    }
  }

  Future<void> _checkOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to check out items')),
        );
      }
      return;
    }

    final notesController = TextEditingController();
    Uint8List? signatureBytes;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Check Out Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final signature = await Navigator.of(context).push<Uint8List>(
                      MaterialPageRoute(
                        builder: (_) => SignaturePad(
                          title: 'Check Out Signature',
                          onSignatureSaved: (sig) {
                            Navigator.of(context).pop(sig);
                          },
                        ),
                      ),
                    );
                    if (signature != null) {
                      setState(() => signatureBytes = signature);
                    }
                  },
                  icon: Icon(signatureBytes == null ? Icons.edit : Icons.check_circle),
                  label: Text(signatureBytes == null ? 'Add Signature' : 'Signature Added'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Check Out'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        if (signatureBytes != null) {
          // Upload signature to Firebase Storage
          final uploadService = ImageUploadService();
          // Create a temporary file for signature
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(signatureBytes!);
          // TODO: Store signatureUrl in history entry when HistoryEntry model supports it
          await uploadService.uploadItemImage('signatures/${widget.itemId}', file);
        }

        final historyService = context.read<HistoryService>();
        final queue = context.read<OfflineQueueService>();
        final online = await NetworkUtils.hasInternetConnection();
        final job = () => historyService.recordCheckOut(
              widget.itemId,
              user.uid,
              notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
            );
        if (online) {
          await job();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item checked out')),
            );
          }
        } else {
          await queue.enqueue(job);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Offline: action queued to sync')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        // Dispose controller after use
        notesController.dispose();
      }
    } else {
      // Dispose controller if dialog was cancelled
      notesController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyService = context.read<HistoryService>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _checkIn,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Check In'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _checkOut,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Check Out'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<HistoryEntry>>(
          future: historyService.getItemHistory(widget.itemId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) {
              return const EmptyState(
                icon: Icons.history,
                title: 'No Transactions',
                message: 'Check in or check out items to see transaction history here',
              );
            }
            return Column(
              children: entries.map((entry) {
                final isCheckIn = entry.action == 'check_in';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      isCheckIn ? Icons.check_circle : Icons.exit_to_app,
                      color: isCheckIn ? Colors.green : Colors.orange,
                    ),
                    title: Text(entry.action.replaceAll('_', ' ').toUpperCase()),
                    subtitle: Text(entry.notes ?? 'No notes'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormatter.formatDate(entry.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          DateFormatter.formatTime(entry.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

