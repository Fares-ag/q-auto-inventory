import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/network_utils.dart';

typedef OfflineJob = Future<void> Function();

/// Minimal in-memory offline queue.
/// If offline, jobs are queued and retried when connectivity is restored.
class OfflineQueueService {
  OfflineQueueService() {
    _startNetworkMonitor();
  }

  final List<OfflineJob> _queue = <OfflineJob>[];
  bool _isFlushing = false;

  Future<void> enqueue(OfflineJob job) async {
    final online = await NetworkUtils.hasInternetConnection();
    if (online) {
      try {
        await job();
        return;
      } catch (e, s) {
        debugPrint('Immediate job failed, queueing: $e\n$s');
      }
    }
    _queue.add(job);
  }

  Future<void> _startNetworkMonitor() async {
    // Polling-based minimal monitor; can be replaced with connectivity callbacks.
    Timer.periodic(const Duration(seconds: 5), (t) async {
      if (_isFlushing || _queue.isEmpty) return;
      final online = await NetworkUtils.hasInternetConnection();
      if (online) {
        await _flush();
      }
    });
  }

  Future<void> _flush() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      while (_queue.isNotEmpty) {
        final job = _queue.removeAt(0);
        try {
          await job();
        } catch (e, s) {
          debugPrint('Retry failed, re-queueing: $e\n$s');
          // Put it back to retry later and break to avoid busy loop.
          _queue.insert(0, job);
          break;
        }
      }
    } finally {
      _isFlushing = false;
    }
  }
}


