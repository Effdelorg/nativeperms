package com.effdel.native_perms

import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.effdel.native_perms.PermissionMapper as P

/**
 * Orchestrates check / request flows. Two paths:
 *   1. Runtime permissions → ActivityCompat.requestPermissions, result via
 *      RequestPermissionsResultListener.
 *   2. Settings-intent permissions (manageExternalStorage, scheduleExactAlarm,
 *      systemAlertWindow, ignoreBatteryOptimizations, requestInstallPackages,
 *      accessNotificationPolicy) → startActivityForResult, result via
 *      ActivityResultListener; resolved status is read after the user returns.
 *
 * Pre-Android-13 notification permission is settings-driven (no runtime grant);
 * we surface NotificationManagerCompat.areNotificationsEnabled() and treat
 * a request as a check, matching permission_handler.
 */
internal class PermissionManager(private val context: Context) {

    private var activity: Activity? = null

    private val pendingRuntimeRequests =
        mutableMapOf<Int, Pair<List<Int>, (Map<Int, Int>) -> Unit>>()
    private val pendingSettingsRequests =
        mutableMapOf<Int, Pair<Int, (Int) -> Unit>>()

    private val runtimeRequestCode = java.util.concurrent.atomic.AtomicInteger(0xFE10)
    private val settingsRequestCode = java.util.concurrent.atomic.AtomicInteger(0xFE40)

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    fun checkPermissionStatus(permission: Int): Int = when (permission) {
        P.NOTIFICATION -> notificationStatus()
        P.IGNORE_BATTERY_OPTIMIZATIONS -> ignoreBatteryStatus()
        P.MANAGE_EXTERNAL_STORAGE -> manageExternalStorageStatus()
        P.SYSTEM_ALERT_WINDOW -> if (Settings.canDrawOverlays(context)) P.STATUS_GRANTED else P.STATUS_DENIED
        P.REQUEST_INSTALL_PACKAGES -> requestInstallPackagesStatus()
        P.ACCESS_NOTIFICATION_POLICY -> accessNotificationPolicyStatus()
        P.SCHEDULE_EXACT_ALARM -> scheduleExactAlarmStatus()
        P.UNKNOWN -> P.STATUS_DENIED
        // iOS-only — return granted-equivalent so caller code sees no false denial.
        P.APP_TRACKING_TRANSPARENCY,
        P.CRITICAL_ALERTS,
        P.MEDIA_LIBRARY, // covered above when mapped to READ_MEDIA_AUDIO 33+, but kept as a safety net
        P.PHOTOS_ADD_ONLY,
        P.SPEECH,
        P.REMINDERS,
        P.ASSISTANT,
        P.BACKGROUND_REFRESH -> P.STATUS_GRANTED
        else -> runtimeStatus(permission)
    }

    fun shouldShowRequestRationale(permission: Int): Boolean {
        val act = activity ?: return false
        val strings = P.manifestStrings(permission)
        if (strings.isEmpty()) return false
        return strings.any { ActivityCompat.shouldShowRequestPermissionRationale(act, it) }
    }

    fun requestPermissions(
        permissions: List<Int>,
        callback: (Map<Int, Int>) -> Unit,
    ) {
        if (permissions.isEmpty()) {
            callback(emptyMap())
            return
        }
        val act = activity
        if (act == null) {
            callback(permissions.associateWith { P.STATUS_DENIED })
            return
        }
        val requested = permissions.distinct()

        // Partition: settings-intent vs runtime.
        val settingsPerms = requested.filter { isSettingsIntentPermission(it) }
        val runtimePerms = requested.filter { !isSettingsIntentPermission(it) }

        val results = mutableMapOf<Int, Int>()

        fun finishIfDone() {
            if (results.size == requested.size) callback(results.toMap())
        }

        fun launchNextSettingsPermission(index: Int) {
            if (index >= settingsPerms.size) {
                finishIfDone()
                return
            }
            val permission = settingsPerms[index]
            launchSettingsIntent(act, permission) { status ->
                results[permission] = status
                launchNextSettingsPermission(index + 1)
            }
        }

        fun finishRuntimeThenSettings() {
            if (settingsPerms.isEmpty()) {
                finishIfDone()
            } else {
                launchNextSettingsPermission(0)
            }
        }

        // Pure passthroughs (no Android equivalent / always-granted).
        for (p in runtimePerms) {
            val strings = P.manifestStrings(p)
            if (strings.isEmpty()) {
                results[p] = checkPermissionStatus(p)
            }
        }

        val needRuntime = runtimePerms.filter { P.manifestStrings(it).isNotEmpty() }
        if (needRuntime.isNotEmpty()) {
            // Pre-resolve any that are already granted (no need to prompt).
            val (alreadyGranted, mustRequest) = needRuntime.partition {
                runtimeStatus(it) == P.STATUS_GRANTED
            }
            for (p in alreadyGranted) results[p] = P.STATUS_GRANTED

            if (mustRequest.isEmpty()) {
                finishRuntimeThenSettings()
            } else {
                val flatStrings = mustRequest.flatMap { P.manifestStrings(it) }.distinct().toTypedArray()
                val requestCode = runtimeRequestCode.getAndIncrement() and 0xFFFF
                pendingRuntimeRequests[requestCode] = Pair(mustRequest) { mapResults ->
                    results.putAll(mapResults)
                    finishRuntimeThenSettings()
                }
                ActivityCompat.requestPermissions(act, flatStrings, requestCode)
            }
        } else {
            finishRuntimeThenSettings()
        }
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        val pending = pendingRuntimeRequests.remove(requestCode) ?: return false
        val (originalPerms, callback) = pending
        val act = activity

        val nameToResult = permissions.zip(grantResults.toList()).toMap()

        val out = mutableMapOf<Int, Int>()
        for (p in originalPerms) {
            val strings = P.manifestStrings(p)
            val granted = runtimeGrantSatisfied(p) {
                nameToResult[it] == PackageManager.PERMISSION_GRANTED
            }
            val anyDenied = strings.any { nameToResult[it] == PackageManager.PERMISSION_DENIED }
            out[p] = when {
                granted -> P.STATUS_GRANTED
                anyDenied && act != null && strings.none {
                    ActivityCompat.shouldShowRequestPermissionRationale(act, it)
                } -> P.STATUS_PERMANENTLY_DENIED
                else -> P.STATUS_DENIED
            }
        }
        callback(out)
        return true
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val pending = pendingSettingsRequests.remove(requestCode) ?: return false
        val (permission, callback) = pending
        callback(checkPermissionStatus(permission))
        return true
    }

    // --- internals --------------------------------------------------------

    private fun runtimeStatus(permission: Int): Int {
        val strings = P.manifestStrings(permission)
        if (strings.isEmpty()) return P.STATUS_GRANTED
        val granted = runtimeGrantSatisfied(permission) {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
        return if (granted) P.STATUS_GRANTED else P.STATUS_DENIED
    }

    private fun runtimeGrantSatisfied(
        permission: Int,
        isGranted: (String) -> Boolean,
    ): Boolean {
        val strings = P.manifestStrings(permission)
        if (strings.isEmpty()) return true
        return when (permission) {
            P.LOCATION,
            P.LOCATION_WHEN_IN_USE -> strings.any(isGranted)
            else -> strings.all(isGranted)
        }
    }

    private fun notificationStatus(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    context,
                    "android.permission.POST_NOTIFICATIONS",
                ) == PackageManager.PERMISSION_GRANTED
            ) P.STATUS_GRANTED else P.STATUS_DENIED
        } else {
            if (NotificationManagerCompat.from(context).areNotificationsEnabled()) {
                P.STATUS_GRANTED
            } else {
                P.STATUS_DENIED
            }
        }
    }

    private fun ignoreBatteryStatus(): Int {
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val granted = pm?.isIgnoringBatteryOptimizations(context.packageName) == true
        return if (granted) P.STATUS_GRANTED else P.STATUS_DENIED
    }

    private fun manageExternalStorageStatus(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (android.os.Environment.isExternalStorageManager()) P.STATUS_GRANTED else P.STATUS_DENIED
        } else {
            // On <R the legacy WRITE_EXTERNAL_STORAGE runtime grant is the closest equivalent.
            if (ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
                ) == PackageManager.PERMISSION_GRANTED
            ) P.STATUS_GRANTED else P.STATUS_DENIED
        }
    }

    private fun requestInstallPackagesStatus(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (context.packageManager.canRequestPackageInstalls()) P.STATUS_GRANTED else P.STATUS_DENIED
        } else P.STATUS_GRANTED
    }

    private fun accessNotificationPolicyStatus(): Int {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        return if (nm?.isNotificationPolicyAccessGranted == true) P.STATUS_GRANTED else P.STATUS_DENIED
    }

    private fun scheduleExactAlarmStatus(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            if (am?.canScheduleExactAlarms() == true) P.STATUS_GRANTED else P.STATUS_DENIED
        } else P.STATUS_GRANTED
    }

    private fun isSettingsIntentPermission(permission: Int): Boolean = when (permission) {
        P.IGNORE_BATTERY_OPTIMIZATIONS,
        P.MANAGE_EXTERNAL_STORAGE,
        P.SYSTEM_ALERT_WINDOW,
        P.REQUEST_INSTALL_PACKAGES,
        P.ACCESS_NOTIFICATION_POLICY,
        P.SCHEDULE_EXACT_ALARM -> true
        else -> false
    }

    private fun launchSettingsIntent(
        act: Activity,
        permission: Int,
        callback: (Int) -> Unit,
    ) {
        val intent: Intent? = when (permission) {
            P.IGNORE_BATTERY_OPTIMIZATIONS -> Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:${context.packageName}"),
            )
            P.MANAGE_EXTERNAL_STORAGE -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Intent(
                    Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:${context.packageName}"),
                )
            } else null
            P.SYSTEM_ALERT_WINDOW -> Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}"),
            )
            P.REQUEST_INSTALL_PACKAGES -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${context.packageName}"),
                )
            } else null
            P.ACCESS_NOTIFICATION_POLICY -> Intent(
                Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS,
            )
            P.SCHEDULE_EXACT_ALARM -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                Intent(
                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                    Uri.parse("package:${context.packageName}"),
                )
            } else null
            else -> null
        }
        if (intent == null) {
            callback(checkPermissionStatus(permission))
            return
        }
        val rc = settingsRequestCode.getAndIncrement() and 0xFFFF
        pendingSettingsRequests[rc] = Pair(permission, callback)
        try {
            act.startActivityForResult(intent, rc)
        } catch (_: Throwable) {
            pendingSettingsRequests.remove(rc)
            callback(P.STATUS_DENIED)
        }
    }
}
