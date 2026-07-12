import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/network_utils.dart';

typedef OfflineJob = Future<void> Function();

/// Minimal in-memory offline queue.
/// If offline, jobs are queued and retried when connectivity is restored.
class OfflineQueueService extends ChangeNotifier {
  OfflineQueueService() {
    _startNetworkMonitor();
  }

  final List<OfflineJob> _queue = <OfflineJob>[];
  bool _isFlushing = false;
  Timer? _monitorTimer;
  bool _disposed = false;

  int get queuedCount => _queue.length;
  bool get isFlushing => _isFlushing;

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
    if (!_disposed) notifyListeners();
  }

  Future<void> _startNetworkMonitor() async {
    // Polling-based minimal monitor; can be replaced with connectivity callbacks.
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (_disposed || _isFlushing || _queue.isEmpty) return;
      final online = await NetworkUtils.hasInternetConnection();
      if (_disposed) return;
      if (online) {
        await _flush();
      }
    });
  }

  Future<void> _flush() async {
    if (_disposed || _isFlushing) return;
    _isFlushing = true;
    if (!_disposed) notifyListeners();
    try {
      while (_queue.isNotEmpty) {
        final job = _queue.removeAt(0);
        try {
          await job();
          if (!_disposed) notifyListeners();
        } catch (e, s) {
          debugPrint('Retry failed, re-queueing: $e\n$s');
          // Put it back to retry later and break to avoid busy loop.
          _queue.insert(0, job);
          if (!_disposed) notifyListeners();
          break;
        }
      }
    } finally {
      _isFlushing = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _monitorTimer?.cancel();
    super.dispose();
  }
}


