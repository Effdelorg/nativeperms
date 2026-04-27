/// Drop-in compatible with `permission_handler ^12.0.x`. To migrate, swap the
/// dependency name and change the import line; no other code changes needed.
library native_perms;

export 'src/permission.dart' show Permission, PermissionWithService;
export 'src/permission_status.dart'
    show
        PermissionStatus,
        PermissionStatusGetters,
        FuturePermissionStatusGetters;
export 'src/service_status.dart'
    show ServiceStatus, ServiceStatusGetters, FutureServiceStatusGetters;
export 'src/extensions.dart'
    show PermissionActions, PermissionListActions, openAppSettings;
export 'src/native_perms_platform_interface.dart' show NativePermsPlatform;
