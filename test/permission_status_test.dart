import 'package:flutter_test/flutter_test.dart';
import 'package:native_perms/native_perms.dart';

void main() {
  group('PermissionStatusGetters', () {
    test('flags only the matching status', () {
      const PermissionStatus s = PermissionStatus.granted;
      expect(s.isGranted, isTrue);
      expect(s.isDenied, isFalse);
      expect(s.isLimited, isFalse);
      expect(s.isPermanentlyDenied, isFalse);
      expect(s.isProvisional, isFalse);
      expect(s.isRestricted, isFalse);
    });

    test('every status has its corresponding getter true', () {
      expect(PermissionStatus.denied.isDenied, isTrue);
      expect(PermissionStatus.granted.isGranted, isTrue);
      expect(PermissionStatus.restricted.isRestricted, isTrue);
      expect(PermissionStatus.limited.isLimited, isTrue);
      expect(
          PermissionStatus.permanentlyDenied.isPermanentlyDenied, isTrue);
      expect(PermissionStatus.provisional.isProvisional, isTrue);
    });
  });

  group('FuturePermissionStatusGetters', () {
    test('await-friendly forms work', () async {
      Future<PermissionStatus> granted() async => PermissionStatus.granted;
      expect(await granted().isGranted, isTrue);
      expect(await granted().isDenied, isFalse);
    });
  });

  group('ServiceStatus', () {
    test('getters', () {
      expect(ServiceStatus.enabled.isEnabled, isTrue);
      expect(ServiceStatus.disabled.isDisabled, isTrue);
      expect(ServiceStatus.notApplicable.isNotApplicable, isTrue);
      expect(ServiceStatus.enabled.isDisabled, isFalse);
    });
  });
}
