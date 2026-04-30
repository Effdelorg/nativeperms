package com.effdel.nativeprems

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings

internal object AppSettingsManager {
    fun openAppSettings(context: Context): Boolean = try {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", context.packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
        true
    } catch (_: Throwable) {
        false
    }
}
