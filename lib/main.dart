import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/firebase_app_bootstrap.dart';
import 'models/firestore_models.dart';
import 'services/cache_service.dart';
import 'services/image_cache_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureImageCache();

  FlutterError.onError = (details) {
    // Suppress the Flutter web hot-restart artifact where queued
    // requestAnimationFrame callbacks try to render to a disposed
    // EngineFlutterView. It's harmless but spams the console.
    final msg = details.exception.toString();
    if (msg.contains('Trying to render a disposed EngineFlutterView') ||
        msg.contains('!isDisposed')) {
      return;
    }
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
  };

  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFF0A0A0A)),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Hydrate the disk-backed cache and start Firebase concurrently.
  // The cache fetch usually finishes first (~50ms), giving the very first
  // frame previously-loaded data without waiting on Firebase or the network.
  final bootstrapperFuture = initializeFirebaseApp();
  await Future.wait([
    bootstrapperFuture,
    CacheService.instance.init(),
  ]);
  final bootstrapper = await bootstrapperFuture;

  // Pull last session's items/departments/categories straight off disk into
  // memory so screens render with real data on the first frame.
  CacheService.instance.hydrateFromDisk<InventoryItem>(
    CacheKeys.items(null, null),
    (m) => InventoryItem.fromJson(_idOrEmpty(m), m),
  );
  // These suffixes match the keys used by listDepartments/listCategories in
  // firebase_services.dart so that the hydrated copy is hit by the next read.
  CacheService.instance.hydrateFromDisk<Department>(
    '${CacheKeys.departments}_active',
    (m) => Department.fromJson(_idOrEmpty(m), m),
  );
  CacheService.instance.hydrateFromDisk<Department>(
    '${CacheKeys.departments}_all',
    (m) => Department.fromJson(_idOrEmpty(m), m),
  );
  CacheService.instance.hydrateFromDisk<Category>(
    '${CacheKeys.categories}_all',
    (m) => Category.fromJson(_idOrEmpty(m), m),
  );
  CacheService.instance.hydrateFromDisk<Category>(
    '${CacheKeys.categories}_active',
    (m) => Category.fromJson(_idOrEmpty(m), m),
  );

  runApp(
    ProviderScope(
      child: InventoryApp(bootstrapper: bootstrapper),
    ),
  );
}

/// Recovers an `id` from a persisted JSON map. Persisted maps include `id`
/// because we control the encoding via the cache, but tolerate missing ids.
String _idOrEmpty(Map<String, dynamic> m) => (m['id'] as String?) ?? '';
