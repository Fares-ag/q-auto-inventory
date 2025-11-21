import 'package:flutter/material.dart';

import '../utils/network_utils.dart';

/// Widget that displays network error with retry option
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({
    super.key,
    required this.onRetry,
    this.message,
    this.error,
  });

  final VoidCallback onRetry;
  final String? message;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final errorMessage = message ??
        (error != null ? NetworkUtils.getErrorMessage(error!) : 'Network error');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.orange[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

