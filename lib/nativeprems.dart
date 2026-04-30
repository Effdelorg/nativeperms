/// Public API for checking permission status, requesting permissions, checking
/// service status, and opening app settings.
library nativeprems;

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
export 'src/nativeprems_platform_interface.dart' show NativePermsPlatform;
