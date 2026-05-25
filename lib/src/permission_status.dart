/// Result of a permission check or request.
enum PermissionStatus {
  /// User denied access; can be requested again.
  denied,

  /// User granted access.
  granted,

  /// Permission is restricted by system policy (e.g. parental controls);
  /// cannot be requested.
  restricted,

  /// User granted limited access (e.g. iOS 14+ photos limited selection).
  limited,

  /// User denied access and selected "don't ask again" (Android), or denied
  /// after first request (iOS); requesting again will not prompt.
  permanentlyDenied,

  /// iOS notifications: provisional authorization (quiet delivery).
  provisional,
}

/// Convenience getters for readable permission status checks.
extension PermissionStatusGetters on PermissionStatus {
  bool get isDenied => this == PermissionStatus.denied;
  bool get isGranted => this == PermissionStatus.granted;
  bool get isRestricted => this == PermissionStatus.restricted;
  bool get isLimited => this == PermissionStatus.limited;
  bool get isPermanentlyDenied => this == PermissionStatus.permanentlyDenied;
  bool get isProvisional => this == PermissionStatus.provisional;
}

/// Convenience getters on async statuses for one-line use:
/// `if (await Permission.camera.status.isGranted) ...`
extension FuturePermissionStatusGetters on Future<PermissionStatus> {
  Future<bool> get isDenied async => (await this).isDenied;
  Future<bool> get isGranted async => (await this).isGranted;
  Future<bool> get isRestricted async => (await this).isRestricted;
  Future<bool> get isLimited async => (await this).isLimited;
  Future<bool> get isPermanentlyDenied async => (await this).isPermanentlyDenied;
  Future<bool> get isProvisional async => (await this).isProvisional;
}
