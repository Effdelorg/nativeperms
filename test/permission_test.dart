import 'package:flutter_test/flutter_test.dart';
import 'package:nativeprems/nativeprems.dart';

void main() {
  group('Permission', () {
    test('values list has 40 entries (calendar..backgroundRefresh)', () {
      expect(Permission.values, hasLength(40));
    });

    test('integer values are 0..39 contiguous', () {
      for (int i = 0; i < Permission.values.length; i++) {
        expect(Permission.values[i].value, i, reason: 'index $i mismatch');
      }
    });

    test('byValue round-trips', () {
      for (final Permission p in Permission.values) {
        expect(Permission.byValue(p.value), same(p));
      }
    });

    test('byValue throws on out-of-range', () {
      expect(() => Permission.byValue(-1), throwsArgumentError);
      expect(() => Permission.byValue(40), throwsArgumentError);
    });

    test('toString uses the dotted permission name', () {
      expect(Permission.camera.toString(), 'Permission.camera');
      expect(Permission.locationWhenInUse.toString(),
          'Permission.locationWhenInUse');
      expect(Permission.bluetoothScan.toString(), 'Permission.bluetoothScan');
    });

    test('PermissionWithService instances are recognised', () {
      expect(Permission.location, isA<PermissionWithService>());
      expect(Permission.locationAlways, isA<PermissionWithService>());
      expect(Permission.locationWhenInUse, isA<PermissionWithService>());
      expect(Permission.bluetooth, isA<PermissionWithService>());
      expect(Permission.phone, isA<PermissionWithService>());
      expect(Permission.camera, isNot(isA<PermissionWithService>()));
    });

    test('equality is by value', () {
      expect(Permission.camera == Permission.camera, isTrue);
      expect(Permission.camera == Permission.microphone, isFalse);
      expect(Permission.camera.hashCode, Permission.camera.hashCode);
    });
  });
}
