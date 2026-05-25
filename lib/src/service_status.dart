/// State of a system service backing a permission (location services on/off,
/// bluetooth radio on/off, …).
enum ServiceStatus {
  /// Service exists on this device but is currently turned off.
  disabled,

  /// Service exists and is turned on.
  enabled,

  /// Concept of a service does not apply to this permission on this platform.
  notApplicable,
}

extension ServiceStatusGetters on ServiceStatus {
  bool get isDisabled => this == ServiceStatus.disabled;
  bool get isEnabled => this == ServiceStatus.enabled;
  bool get isNotApplicable => this == ServiceStatus.notApplicable;
}

extension FutureServiceStatusGetters on Future<ServiceStatus> {
  Future<bool> get isDisabled async => (await this).isDisabled;
  Future<bool> get isEnabled async => (await this).isEnabled;
  Future<bool> get isNotApplicable async => (await this).isNotApplicable;
}
