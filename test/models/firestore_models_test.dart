import 'package:flutter_test/flutter_test.dart';
import 'package:q_auto_inventory/models/firestore_models.dart';

void main() {
  group('InventoryItem', () {
    test('fromJson parses minimal fields', () {
      final item = InventoryItem.fromJson('doc1', {
        'name': 'Laptop',
        'assetId': 'ASSET-1',
        'categoryId': 'Electronics',
        'departmentId': 'IT',
      });

      expect(item.id, 'doc1');
      expect(item.name, 'Laptop');
      expect(item.assetId, 'ASSET-1');
      expect(item.categoryId, 'Electronics');
      expect(item.departmentId, 'IT');
      expect(item.status, isNull);
      expect(item.tags, isEmpty);
    });

    test('fromJson uses fallback field names', () {
      final item = InventoryItem.fromJson('doc2', {
        'name': 'Monitor',
        'qrCodeId': 'QR-42',
        'category': 'Peripherals',
        'department': 'Design',
        'assignedStaff': 'user123',
        'location': 'Building A',
      });

      expect(item.assetId, 'QR-42');
      expect(item.categoryId, 'Peripherals');
      expect(item.departmentId, 'Design');
      expect(item.assignedTo, 'user123');
      expect(item.locationId, 'Building A');
    });

    test('fromJson falls back to doc id for name/assetId', () {
      final item = InventoryItem.fromJson('fallback-id', {});
      expect(item.name, 'fallback-id');
      expect(item.assetId, 'fallback-id');
    });

    test('fromJson parses numeric and boolean fields', () {
      final item = InventoryItem.fromJson('x', {
        'name': 'Chair',
        'assetId': 'A-1',
        'categoryId': 'Furniture',
        'departmentId': 'Office',
        'quantity': 5,
        'purchasePrice': 299.99,
        'shelfLifeYears': 10,
        'mileage': 50000,
        'isAvailable': true,
        'isTagged': false,
        'isWrittenOff': false,
      });

      expect(item.quantity, 5);
      expect(item.purchasePrice, 299.99);
      expect(item.shelfLifeYears, 10);
      expect(item.mileage, 50000);
      expect(item.isAvailable, true);
      expect(item.isTagged, false);
      expect(item.isWrittenOff, false);
    });

    test('fromJson parses imageUrls list fallback for thumbnailUrl', () {
      final item = InventoryItem.fromJson('x', {
        'name': 'X',
        'assetId': 'A',
        'categoryId': 'C',
        'departmentId': 'D',
        'imageUrls': ['https://img.example.com/1.jpg'],
      });

      expect(item.thumbnailUrl, 'https://img.example.com/1.jpg');
    });

    test('toJson round-trips correctly', () {
      final original = InventoryItem.fromJson('rt', {
        'name': 'Printer',
        'assetId': 'ASSET-99',
        'categoryId': 'Office',
        'departmentId': 'Admin',
        'status': 'active',
        'quantity': 3,
        'purchasePrice': 450.0,
        'tags': ['networked', 'color'],
      });

      final json = original.toJson();
      expect(json['name'], 'Printer');
      expect(json['assetId'], 'ASSET-99');
      expect(json['status'], 'active');
      expect(json['quantity'], 3);
      expect(json['purchasePrice'], 450.0);
    });

    test('toJson omits null optional fields', () {
      final item = InventoryItem.fromJson('sparse', {
        'name': 'Bare',
        'assetId': 'B-1',
        'categoryId': 'C',
        'departmentId': 'D',
      });

      final json = item.toJson();
      expect(json.containsKey('description'), false);
      expect(json.containsKey('status'), false);
      expect(json.containsKey('purchasePrice'), false);
      expect(json.containsKey('thumbnailUrl'), false);
    });
  });

  group('Category', () {
    test('fromJson parses all fields', () {
      final cat = Category.fromJson('cat1', {
        'name': 'Electronics',
        'description': 'Electronic devices',
        'parentId': 'root',
        'sortOrder': 1,
        'isActive': true,
      });

      expect(cat.id, 'cat1');
      expect(cat.name, 'Electronics');
      expect(cat.description, 'Electronic devices');
      expect(cat.parentId, 'root');
      expect(cat.sortOrder, 1);
      expect(cat.isActive, true);
    });

    test('fromJson defaults name to id when missing', () {
      final cat = Category.fromJson('auto-name', {});
      expect(cat.name, 'auto-name');
      expect(cat.isActive, true);
    });

    test('toJson round-trips', () {
      final cat = Category.fromJson('c', {
        'name': 'Furniture',
        'isActive': false,
      });
      final json = cat.toJson();
      expect(json['name'], 'Furniture');
      expect(json['isActive'], false);
      expect(json.containsKey('parentId'), false);
    });
  });

  group('Department', () {
    test('fromJson parses all fields', () {
      final dept = Department.fromJson('d1', {
        'name': 'Engineering',
        'code': 'ENG',
        'description': 'Engineering department',
        'managerId': 'mgr1',
        'isActive': true,
      });

      expect(dept.id, 'd1');
      expect(dept.name, 'Engineering');
      expect(dept.code, 'ENG');
      expect(dept.managerId, 'mgr1');
      expect(dept.isActive, true);
    });

    test('defaults name to id', () {
      final dept = Department.fromJson('fallback', {});
      expect(dept.name, 'fallback');
    });

    test('toJson includes all set fields', () {
      final dept = Department.fromJson('d', {
        'name': 'HR',
        'code': 'HR',
        'isActive': false,
      });
      final json = dept.toJson();
      expect(json['name'], 'HR');
      expect(json['code'], 'HR');
      expect(json['isActive'], false);
    });
  });

  group('StaffMember', () {
    test('fromJson parses all fields', () {
      final staff = StaffMember.fromJson('s1', {
        'displayName': 'John Doe',
        'email': 'john@example.com',
        'role': 'Admin',
        'phoneNumber': '+1234567890',
        'departmentId': 'd1',
        'isActive': true,
      });

      expect(staff.displayName, 'John Doe');
      expect(staff.email, 'john@example.com');
      expect(staff.role, 'Admin');
      expect(staff.phoneNumber, '+1234567890');
      expect(staff.isActive, true);
    });

    test('defaults displayName to id', () {
      final staff = StaffMember.fromJson('uid123', {});
      expect(staff.displayName, 'uid123');
      expect(staff.email, '');
    });

    test('toJson round-trips', () {
      final json = StaffMember.fromJson('s', {
        'displayName': 'Alice',
        'email': 'alice@test.com',
        'role': 'Finance',
        'isActive': false,
      }).toJson();

      expect(json['displayName'], 'Alice');
      expect(json['email'], 'alice@test.com');
      expect(json['role'], 'Finance');
      expect(json['isActive'], false);
    });
  });

  group('AppUser', () {
    test('fromJson parses standard fields', () {
      final user = AppUser.fromJson('u1', {
        'email': 'user@test.com',
        'displayName': 'Test User',
        'departmentId': 'dept1',
        'permissionSetId': 'perm1',
        'isDisabled': false,
      });

      expect(user.email, 'user@test.com');
      expect(user.displayName, 'Test User');
      expect(user.departmentId, 'dept1');
      expect(user.isDisabled, false);
    });

    test('fromJson handles alternate Firestore field names', () {
      final user = AppUser.fromJson('u2', {
        'email': 'alt@test.com',
        'name': 'Alt User',
        'department': 'Sales',
        'roleId': 'role1',
        'isActive': false,
      });

      expect(user.displayName, 'Alt User');
      expect(user.departmentId, 'Sales');
      expect(user.permissionSetId, 'role1');
      expect(user.isDisabled, true);
    });

    test('isActive inverts to isDisabled', () {
      final active = AppUser.fromJson('a', {'isActive': true, 'email': 'a@a.com'});
      expect(active.isDisabled, false);

      final inactive = AppUser.fromJson('b', {'isActive': false, 'email': 'b@b.com'});
      expect(inactive.isDisabled, true);
    });
  });

  group('Comment', () {
    test('fromJson and toJson round-trip', () {
      final c = Comment.fromJson('c1', {
        'entityId': 'item1',
        'entityType': 'item',
        'authorId': 'user1',
        'content': 'Looks good',
      });

      expect(c.entityId, 'item1');
      expect(c.content, 'Looks good');

      final json = c.toJson();
      expect(json['entityId'], 'item1');
      expect(json['content'], 'Looks good');
    });
  });

  group('Location', () {
    test('fromJson parses correctly', () {
      final loc = Location.fromJson('loc1', {
        'name': 'Warehouse A',
        'address': '123 Main St',
        'isPrimary': true,
      });

      expect(loc.name, 'Warehouse A');
      expect(loc.address, '123 Main St');
      expect(loc.isPrimary, true);
    });

    test('defaults isPrimary to false', () {
      final loc = Location.fromJson('loc2', {'name': 'Storage'});
      expect(loc.isPrimary, false);
    });
  });

  group('PermissionSet', () {
    test('fromJson parses list permissions', () {
      final ps = PermissionSet.fromJson('ps1', {
        'name': 'Admin',
        'description': 'Full access',
        'permissions': ['admin', 'manage_items', '*'],
      });

      expect(ps.name, 'Admin');
      expect(ps.permissions, contains('admin'));
      expect(ps.permissions, contains('*'));
    });

    test('fromJson parses map permissions (truthy values)', () {
      final ps = PermissionSet.fromJson('ps2', {
        'name': 'Custom',
        'permissions': {'view_items': true, 'edit_items': false, 'manage_staff': true},
      });

      expect(ps.permissions, contains('view_items'));
      expect(ps.permissions, contains('manage_staff'));
      expect(ps.permissions, isNot(contains('edit_items')));
    });
  });

  group('Issue', () {
    test('fromJson defaults status to open', () {
      final issue = Issue.fromJson('i1', {
        'itemId': 'item1',
        'title': 'Broken screen',
      });

      expect(issue.status, 'open');
      expect(issue.title, 'Broken screen');
    });

    test('toJson includes all set fields', () {
      final json = Issue.fromJson('i2', {
        'itemId': 'item2',
        'title': 'Scratch',
        'status': 'closed',
        'priority': 'high',
        'reportedBy': 'user1',
      }).toJson();

      expect(json['status'], 'closed');
      expect(json['priority'], 'high');
      expect(json['reportedBy'], 'user1');
    });
  });

  group('HistoryEntry', () {
    test('fromJson parses correctly', () {
      final entry = HistoryEntry.fromJson('h1', {
        'itemId': 'item1',
        'action': 'check_out',
        'actorId': 'user1',
        'notes': 'Checked out for field work',
      });

      expect(entry.action, 'check_out');
      expect(entry.notes, 'Checked out for field work');
    });

    test('defaults action to update', () {
      final entry = HistoryEntry.fromJson('h2', {
        'itemId': 'x',
        'actorId': 'y',
      });
      expect(entry.action, 'update');
    });
  });

  group('VehicleCheckInOut', () {
    test('fromJson parses correctly', () {
      final record = VehicleCheckInOut.fromJson('v1', {
        'vehicleId': 'car1',
        'userId': 'user1',
        'action': 'checkout',
        'odometer': 45000.5,
        'completed': false,
      });

      expect(record.vehicleId, 'car1');
      expect(record.odometer, 45000.5);
      expect(record.completed, false);
    });
  });

  group('VehicleMaintenance', () {
    test('fromJson parses correctly', () {
      final maint = VehicleMaintenance.fromJson('m1', {
        'vehicleId': 'car1',
        'type': 'oil_change',
        'cost': 150.0,
        'mileage': 60000.0,
      });

      expect(maint.type, 'oil_change');
      expect(maint.cost, 150.0);
      expect(maint.mileage, 60000.0);
    });

    test('defaults type to general', () {
      final maint = VehicleMaintenance.fromJson('m2', {
        'vehicleId': 'car2',
      });
      expect(maint.type, 'general');
    });
  });

  group('SubDepartment', () {
    test('fromJson parses all fields', () {
      final sd = SubDepartment.fromJson('sd1', {
        'departmentId': 'd1',
        'name': 'Frontend',
        'code': 'FE',
        'isActive': true,
      });

      expect(sd.departmentId, 'd1');
      expect(sd.name, 'Frontend');
      expect(sd.code, 'FE');
    });
  });

  group('SystemSettings', () {
    test('fromJson parses all fields', () {
      final settings = SystemSettings.fromJson('config', {
        'companyName': 'Q Auto',
        'qrPrefix': 'QA',
        'supportEmail': 'support@qauto.com',
      });

      expect(settings.companyName, 'Q Auto');
      expect(settings.qrPrefix, 'QA');
      expect(settings.supportEmail, 'support@qauto.com');
    });

    test('toJson omits null fields', () {
      final json = SystemSettings.fromJson('c', {}).toJson();
      expect(json.isEmpty, true);
    });
  });

  group('AssetCounter', () {
    test('fromJson and toJson round-trip', () {
      final counter = AssetCounter.fromJson('default', {
        'prefix': 'ASSET',
        'currentValue': 42,
      });

      expect(counter.prefix, 'ASSET');
      expect(counter.currentValue, 42);

      final json = counter.toJson();
      expect(json['prefix'], 'ASSET');
      expect(json['currentValue'], 42);
    });

    test('defaults prefix to ASSET', () {
      final counter = AssetCounter.fromJson('x', {});
      expect(counter.prefix, 'ASSET');
      expect(counter.currentValue, 0);
    });
  });
}
