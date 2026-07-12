import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_auto_inventory/bootstrap/firebase_app_bootstrap.dart';
import 'package:q_auto_inventory/models/firestore_models.dart';
import 'package:q_auto_inventory/services/cache_service.dart';
import 'package:q_auto_inventory/services/image_cache_config.dart';

import 'super_admin_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureImageCache();

  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains('Trying to render a disposed EngineFlutterView') ||
        msg.contains('!isDisposed')) {
      return;
    }
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  final bootstrapperFuture = initializeFirebaseApp();
  await Future.wait([
    bootstrapperFuture,
    CacheService.instance.init(),
  ]);
  final bootstrapper = await bootstrapperFuture;

  CacheService.instance.hydrateFromDisk<InventoryItem>(
    CacheKeys.items(null, null),
    (m) => InventoryItem.fromJson((m['id'] as String?) ?? '', m),
  );
  CacheService.instance.hydrateFromDisk<Department>(
    '${CacheKeys.departments}_active',
    (m) => Department.fromJson((m['id'] as String?) ?? '', m),
  );
  CacheService.instance.hydrateFromDisk<Department>(
    '${CacheKeys.departments}_all',
    (m) => Department.fromJson((m['id'] as String?) ?? '', m),
  );
  CacheService.instance.hydrateFromDisk<Category>(
    '${CacheKeys.categories}_all',
    (m) => Category.fromJson((m['id'] as String?) ?? '', m),
  );
  CacheService.instance.hydrateFromDisk<Category>(
    '${CacheKeys.categories}_active',
    (m) => Category.fromJson((m['id'] as String?) ?? '', m),
  );

  runApp(
    ProviderScope(child: SuperAdminApp(bootstrapper: bootstrapper)),
  );
}
