import 'dart:async';

import 'package:flutter/material.dart';

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
    if (_isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.orange,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_off, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'You are offline. Some features may not be available.',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

