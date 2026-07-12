import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_preloader_service.dart';

/// Widget that starts preloading all assets in the background
/// Should be placed early in the widget tree to start loading immediately
class AssetPreloaderWidget extends StatefulWidget {
  const AssetPreloaderWidget({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AssetPreloaderWidget> createState() => _AssetPreloaderWidgetState();
}

class _AssetPreloaderWidgetState extends State<AssetPreloaderWidget> {
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    // Do not use addPostFrameCallback here: on Flutter web, hot restart can leave
    // stale callbacks that run after the EngineFlutterView is disposed
    // ("Trying to render a disposed EngineFlutterView").
    Future.microtask(() {
      if (!mounted) return;
      _startPreloading();
    });
  }

  Future<void> _startPreloading() async {
    if (_hasStarted || !mounted) return;
    _hasStarted = true;

    try {
      if (!mounted) return;
      final preloader = context.read<DataPreloaderService>();
      
      // Only start if not already preloading/preloaded
      if (!preloader.isPreloading && !preloader.isPreloaded) {
        // Start in background - don't await, let it run
        preloader.preloadAllAssets().catchError((e) {
          debugPrint('Background preload error: $e');
        });
      }
    } catch (e) {
      debugPrint('Failed to start preloader: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

