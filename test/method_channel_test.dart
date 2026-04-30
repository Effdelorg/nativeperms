import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nativeprems/nativeprems.dart';
import 'package:nativeprems/src/nativeprems_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelNativePerms platform = MethodChannelNativePerms();
  final List<MethodCall> calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    NativePermsPlatform.instance = platform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel,
        (MethodCall call) async {
      calls.add(call);
      switch (call.method) {
        case 'checkPermissionStatus':
          return PermissionStatus.granted.index;
        case 'requestPermissions':
          final List<int> wire = (call.arguments as List).cast<int>();
          return <int, int>{
            for (final int v in wire) v: PermissionStatus.granted.index,
          };
        case 'shouldShowRequestPermissionRationale':
          return true;
        case 'checkServiceStatus':
          return ServiceStatus.enabled.index;
        case 'openAppSettings':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, null);
  });

  test('checkPermissionStatus encodes Permission.value', () async {
    final PermissionStatus s = await platform.checkPermissionStatus(
      Permission.camera,
    );
    expect(s, PermissionStatus.granted);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'checkPermissionStatus');
    expect(calls.single.arguments, Permission.camera.value);
  });

  test('requestPermissions encodes a list of values, decodes a map', () async {
    final Map<Permission, PermissionStatus> result =
        await platform.requestPermissions(
      <Permission>[Permission.camera, Permission.microphone],
    );
    expect(result[Permission.camera], PermissionStatus.granted);
    expect(result[Permission.microphone], PermissionStatus.granted);
    expect(calls.single.arguments,
        <int>[Permission.camera.value, Permission.microphone.value]);
  });

  test('shouldShowRequestPermissionRationale short-circuits off-Android',
      () async {
    // In test env defaultTargetPlatform is android by default (TargetPlatform.android),
    // so we explicitly verify both directions via debugDefaultTargetPlatformOverride.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      await platform.shouldShowRequestPermissionRationale(Permission.camera),
      isFalse,
    );
    expect(calls, isEmpty);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      await platform.shouldShowRequestPermissionRationale(Permission.camera),
      isTrue,
    );
    expect(calls.single.method, 'shouldShowRequestPermissionRationale');

    debugDefaultTargetPlatformOverride = null;
  });

  test('checkServiceStatus encodes Permission.value', () async {
    final ServiceStatus s = await platform.checkServiceStatus(
      Permission.location,
    );
    expect(s, ServiceStatus.enabled);
    expect(calls.single.arguments, Permission.location.value);
  });

  test('openAppSettings round-trips bool', () async {
    expect(await platform.openAppSettings(), isTrue);
    expect(calls.single.method, 'openAppSettings');
  });

  test('PermissionActions extension routes through the platform', () async {
    expect(await Permission.camera.status, PermissionStatus.granted);
    expect(await Permission.camera.request(), PermissionStatus.granted);
  });

  test('PermissionListActions extension routes through the platform',
      () async {
    final Map<Permission, PermissionStatus> result =
        await <Permission>[Permission.camera, Permission.notification]
            .request();
    expect(result, hasLength(2));
  });

  test('PermissionWithService.serviceStatus routes through the platform',
      () async {
    expect(await Permission.location.serviceStatus, ServiceStatus.enabled);
  });

  test('top-level openAppSettings works', () async {
    expect(await openAppSettings(), isTrue);
  });
}
