import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../services/offline_queue_service.dart';
import '../utils/network_utils.dart';

/// Widget that shows an offline indicator when device is offline
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Check connectivity every 5 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await NetworkUtils.hasInternetConnection();
    if (mounted && _isOnline != isOnline) {
      setState(() => _isOnline = isOnline);
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<OfflineQueueService>();
    if (_isOnline) {
      if (queue.queuedCount == 0) {
        return const SizedBox.shrink();
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Theme.of(context).colorScheme.primary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sync, color: Theme.of(context).colorScheme.onPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              queue.isFlushing
                  ? 'Syncing ${queue.queuedCount} queued action(s)...'
                  : '${queue.queuedCount} action(s) queued to sync',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).colorScheme.secondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Theme.of(context).colorScheme.onPrimary, size: 20),
          const SizedBox(width: 8),
          Text(
            queue.queuedCount > 0
                ? 'Offline. ${queue.queuedCount} action(s) queued.'
                : 'You are offline. Some features may not be available.',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

