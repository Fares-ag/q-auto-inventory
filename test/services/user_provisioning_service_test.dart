import 'package:flutter_test/flutter_test.dart';
import 'package:q_auto_inventory/services/auth_session_service.dart';
import 'package:q_auto_inventory/services/user_provisioning_service.dart';

void main() {
  group('UserProvisioningResult', () {
    test('fromMap parses uid and temporary password', () {
      final result = UserProvisioningResult.fromMap({
        'uid': 'abc123',
        'temporaryPassword': 'TempPass1!',
      });

      expect(result.uid, 'abc123');
      expect(result.temporaryPassword, 'TempPass1!');
    });
  });

  group('isUserRecordDisabled', () {
    test('returns false for null data', () {
      expect(isUserRecordDisabled(null), isFalse);
    });

    test('returns true when isDisabled is true', () {
      expect(isUserRecordDisabled({'isDisabled': true}), isTrue);
    });
  });
}
