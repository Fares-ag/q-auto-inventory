import '../models/firestore_models.dart';
import 'cache_service.dart';
import 'firebase_services.dart';

/// Wrapper around DepartmentService that adds caching for performance
class CachedDepartmentService {
  CachedDepartmentService(this._departmentService);

  final DepartmentService _departmentService;
  final _cache = CacheService.instance;

  Future<List<Department>> listDepartments({bool includeInactive = true}) async {
    final cacheKey = '${CacheKeys.departments}_${includeInactive ? 'all' : 'active'}';
    
    final cached = _cache.get<List<Department>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    final departments = await _departmentService.listDepartments(
      includeInactive: includeInactive,
    );
    
    // Cache departments longer as they change infrequently
    _cache.set(cacheKey, departments, ttl: const Duration(minutes: 30));
    return departments;
  }

  Stream<List<Department>> watchDepartments() {
    return _departmentService.watchDepartments();
  }

  Future<String> addDepartment(String name, {String? description}) async {
    final id = await _departmentService.addDepartment(name, description: description);
    _cache.remove(CacheKeys.departments);
    return id;
  }

  Future<void> updateDepartment(
    String id, {
    String? name,
    String? description,
    String? managerId,
  }) async {
    await _departmentService.updateDepartment(
      id,
      name: name,
      description: description,
      managerId: managerId,
    );
    _cache.remove(CacheKeys.departments);
  }

  Future<void> setDepartmentStatus(String id, bool isActive) async {
    await _departmentService.setDepartmentStatus(id, isActive);
    _cache.remove(CacheKeys.departments);
  }

  Future<void> deleteDepartment(String id) async {
    await _departmentService.deleteDepartment(id);
    _cache.remove(CacheKeys.departments);
  }

  Future<List<SubDepartment>> listSubDepartments(String departmentId) {
    return _departmentService.listSubDepartments(departmentId);
  }
}

