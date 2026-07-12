// Core service providers for Riverpod — bridge existing Provider-based
// services so ConsumerWidgets can access them without context.read<T>().

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase_services.dart';
import '../services/permission_service.dart';
import '../services/offline_queue_service.dart';

// ── Firebase primitives ───────────────────────────────────────────────────────

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// ── Services ──────────────────────────────────────────────────────────────────

final offlineQueueProvider = ChangeNotifierProvider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});

final catalogServiceProvider = Provider<CatalogService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final queue = ref.watch(offlineQueueProvider);
  return CatalogService(firestore, offlineQueue: queue);
});

final departmentServiceProvider = Provider<DepartmentService>((ref) {
  return DepartmentService(ref.watch(firestoreProvider));
});

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(ref.watch(firestoreProvider));
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(firestoreProvider));
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService(firestore: ref.watch(firestoreProvider));
});

final commentServiceProvider = Provider<CommentService>((ref) {
  return CommentService(ref.watch(firestoreProvider));
});

final issueServiceProvider = Provider<IssueService>((ref) {
  return IssueService(ref.watch(firestoreProvider));
});

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService(ref.watch(firestoreProvider));
});

final systemSettingsServiceProvider = Provider<SystemSettingsService>((ref) {
  return SystemSettingsService(ref.watch(firestoreProvider));
});

final vehicleServiceProvider = Provider<VehicleService>((ref) {
  return VehicleService(ref.watch(firestoreProvider));
});

final assetCounterServiceProvider = Provider<AssetCounterService>((ref) {
  return AssetCounterService(ref.watch(firestoreProvider));
});
