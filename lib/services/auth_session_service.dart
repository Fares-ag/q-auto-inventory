import 'package:firebase_auth/firebase_auth.dart';

import 'cache_service.dart';
import 'permission_service.dart';

Future<void> signOutAndClearSession({
  FirebaseAuth? auth,
  PermissionService? permissionService,
}) async {
  permissionService?.clearSessionCache();
  await CacheService.instance.clear();
  await (auth ?? FirebaseAuth.instance).signOut();
}

bool isUserRecordDisabled(Map<String, dynamic>? data) {
  if (data == null) return false;
  final isDisabled = data['isDisabled'] as bool? ?? false;
  final isActive = data['isActive'] as bool? ?? true;
  return isDisabled || !isActive;
}
