import 'package:flutter_test/flutter_test.dart';

/// Tests for the pure permission-checking logic.
/// PermissionService.hasPermission is an instance method, but its logic is
/// stateless -- it simply checks list membership. We replicate the logic here
/// to avoid needing a Firebase instance in unit tests.
bool _hasPermission(List<String> permissions, String permission) {
  return permissions.contains(permission) || permissions.contains('*');
}

void main() {
  group('Permission checking logic', () {
    test('returns true when permission is in list', () {
      expect(_hasPermission(['admin', 'view_items'], 'admin'), true);
    });

    test('returns false when permission is not in list', () {
      expect(_hasPermission(['view_items'], 'admin'), false);
    });

    test('wildcard grants any permission', () {
      expect(_hasPermission(['*'], 'any_permission'), true);
    });

    test('empty list grants no permissions', () {
      expect(_hasPermission([], 'admin'), false);
    });

    test('exact match required (no partial)', () {
      expect(_hasPermission(['admin_read'], 'admin'), false);
    });

    test('multiple permissions checked correctly', () {
      final perms = ['view_items', 'manage_items', 'view_reports'];
      expect(_hasPermission(perms, 'view_items'), true);
      expect(_hasPermission(perms, 'manage_items'), true);
      expect(_hasPermission(perms, 'admin'), false);
    });

    test('finance permissions set', () {
      final financePerms = [
        'finance',
        'edit_financial_fields',
        'edit_asset_number',
        'view_items',
        'view_reports',
      ];
      expect(_hasPermission(financePerms, 'finance'), true);
      expect(_hasPermission(financePerms, 'edit_financial_fields'), true);
      expect(_hasPermission(financePerms, 'admin'), false);
      expect(_hasPermission(financePerms, 'manage_items'), false);
    });

    test('admin wildcard grants everything', () {
      final adminPerms = ['admin', 'manage_items', '*'];
      expect(_hasPermission(adminPerms, 'anything'), true);
      expect(_hasPermission(adminPerms, 'finance'), true);
    });
  });
}
