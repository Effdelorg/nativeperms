package com.effdel.nativeprems

import android.Manifest
import android.os.Build

/** Maps the cross-platform Permission(int) wire value to Android manifest strings. */
internal object PermissionMapper {

    // Mirrors lib/src/permission.dart numbering.
    const val CALENDAR = 0
    const val CAMERA = 1
    const val CONTACTS = 2
    const val LOCATION = 3
    const val LOCATION_ALWAYS = 4
    const val LOCATION_WHEN_IN_USE = 5
    const val MEDIA_LIBRARY = 6
    const val MICROPHONE = 7
    const val PHONE = 8
    const val PHOTOS = 9
    const val PHOTOS_ADD_ONLY = 10
    const val REMINDERS = 11
    const val SENSORS = 12
    const val SMS = 13
    const val SPEECH = 14
    const val STORAGE = 15
    const val IGNORE_BATTERY_OPTIMIZATIONS = 16
    const val NOTIFICATION = 17
    const val ACCESS_MEDIA_LOCATION = 18
    const val ACTIVITY_RECOGNITION = 19
    const val UNKNOWN = 20
    const val BLUETOOTH = 21
    const val MANAGE_EXTERNAL_STORAGE = 22
    const val SYSTEM_ALERT_WINDOW = 23
    const val REQUEST_INSTALL_PACKAGES = 24
    const val APP_TRACKING_TRANSPARENCY = 25
    const val ACCESS_NOTIFICATION_POLICY = 26
    const val BLUETOOTH_SCAN = 27
    const val BLUETOOTH_ADVERTISE = 28
    const val BLUETOOTH_CONNECT = 29
    const val NEARBY_WIFI_DEVICES = 30
    const val VIDEOS = 31
    const val AUDIO = 32
    const val SCHEDULE_EXACT_ALARM = 33
    const val SENSORS_ALWAYS = 34
    const val CRITICAL_ALERTS = 35
    const val CALENDAR_WRITE_ONLY = 36
    const val CALENDAR_FULL_ACCESS = 37
    const val ASSISTANT = 38
    const val BACKGROUND_REFRESH = 39

    // PermissionStatus indices (mirror lib/src/permission_status.dart).
    const val STATUS_DENIED = 0
    const val STATUS_GRANTED = 1
    const val STATUS_RESTRICTED = 2
    const val STATUS_LIMITED = 3
    const val STATUS_PERMANENTLY_DENIED = 4
    const val STATUS_PROVISIONAL = 5

    // ServiceStatus indices (mirror lib/src/service_status.dart).
    const val SERVICE_DISABLED = 0
    const val SERVICE_ENABLED = 1
    const val SERVICE_NOT_APPLICABLE = 2

    /**
     * Returns the runtime-permission strings to request for [permission], or
     * an empty list for permissions that are granted via a settings intent
     * (handled separately) or have no Android equivalent.
     */
    fun manifestStrings(permission: Int): List<String> = when (permission) {
        CALENDAR -> listOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR)
        CALENDAR_WRITE_ONLY -> listOf(Manifest.permission.WRITE_CALENDAR)
        CALENDAR_FULL_ACCESS -> listOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR)
        CAMERA -> listOf(Manifest.permission.CAMERA)
        CONTACTS -> listOf(
            Manifest.permission.READ_CONTACTS,
            Manifest.permission.WRITE_CONTACTS,
            Manifest.permission.GET_ACCOUNTS,
        )
        LOCATION, LOCATION_WHEN_IN_USE -> listOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        LOCATION_ALWAYS -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            listOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        } else {
            listOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            )
        }
        MICROPHONE -> listOf(Manifest.permission.RECORD_AUDIO)
        PHONE -> listOf(
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.CALL_PHONE,
            Manifest.permission.READ_CALL_LOG,
            Manifest.permission.WRITE_CALL_LOG,
            Manifest.permission.USE_SIP,
            Manifest.permission.PROCESS_OUTGOING_CALLS,
            Manifest.permission.ADD_VOICEMAIL,
        )
        PHOTOS -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            listOf(Manifest.permission.READ_MEDIA_IMAGES)
        } else {
            listOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        VIDEOS -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            listOf(Manifest.permission.READ_MEDIA_VIDEO)
        } else {
            listOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        AUDIO, MEDIA_LIBRARY -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            listOf(Manifest.permission.READ_MEDIA_AUDIO)
        } else {
            listOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        SENSORS, SENSORS_ALWAYS -> listOf(Manifest.permission.BODY_SENSORS)
        SMS -> listOf(
            Manifest.permission.SEND_SMS,
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.READ_SMS,
            Manifest.permission.RECEIVE_WAP_PUSH,
            Manifest.permission.RECEIVE_MMS,
        )
        STORAGE -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // On 33+ scoped storage is in effect; storage is replaced by the per-media perms.
            // Returning these keeps unavailable permissions predictable.
            listOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO,
                Manifest.permission.READ_MEDIA_AUDIO,
            )
        } else {
            listOf(
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
            )
        }
        ACCESS_MEDIA_LOCATION -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            listOf(Manifest.permission.ACCESS_MEDIA_LOCATION)
        } else emptyList()
        ACTIVITY_RECOGNITION -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            listOf(Manifest.permission.ACTIVITY_RECOGNITION)
        } else emptyList()
        BLUETOOTH -> listOf(Manifest.permission.BLUETOOTH)
        BLUETOOTH_SCAN -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(Manifest.permission.BLUETOOTH_SCAN)
        } else emptyList()
        BLUETOOTH_ADVERTISE -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(Manifest.permission.BLUETOOTH_ADVERTISE)
        } else emptyList()
        BLUETOOTH_CONNECT -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(Manifest.permission.BLUETOOTH_CONNECT)
        } else emptyList()
        NEARBY_WIFI_DEVICES -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            listOf(Manifest.permission.NEARBY_WIFI_DEVICES)
        } else emptyList()
        NOTIFICATION -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            listOf(Manifest.permission.POST_NOTIFICATIONS)
        } else emptyList()
        // Settings-intent or non-runtime permissions: no manifest strings.
        IGNORE_BATTERY_OPTIMIZATIONS,
        MANAGE_EXTERNAL_STORAGE,
        SYSTEM_ALERT_WINDOW,
        REQUEST_INSTALL_PACKAGES,
        ACCESS_NOTIFICATION_POLICY,
        SCHEDULE_EXACT_ALARM,
        APP_TRACKING_TRANSPARENCY,
        SPEECH,
        REMINDERS,
        CRITICAL_ALERTS,
        ASSISTANT,
        BACKGROUND_REFRESH,
        UNKNOWN -> emptyList()
        else -> emptyList()
    }
}
