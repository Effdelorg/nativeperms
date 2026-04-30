package com.effdel.nativeprems

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.location.LocationManager
import android.telephony.TelephonyManager
import androidx.core.location.LocationManagerCompat
import com.effdel.nativeprems.PermissionMapper as P

internal object ServiceManager {
    fun checkServiceStatus(context: Context, permission: Int): Int = when (permission) {
        P.LOCATION, P.LOCATION_ALWAYS, P.LOCATION_WHEN_IN_USE -> {
            val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            if (lm != null && LocationManagerCompat.isLocationEnabled(lm)) {
                P.SERVICE_ENABLED
            } else {
                P.SERVICE_DISABLED
            }
        }
        P.PHONE -> {
            val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            when (tm?.simState) {
                TelephonyManager.SIM_STATE_READY -> P.SERVICE_ENABLED
                TelephonyManager.SIM_STATE_ABSENT,
                TelephonyManager.SIM_STATE_UNKNOWN,
                null -> P.SERVICE_DISABLED
                else -> P.SERVICE_DISABLED
            }
        }
        P.BLUETOOTH -> {
            val adapter: BluetoothAdapter? =
                (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
                    ?: @Suppress("DEPRECATION") BluetoothAdapter.getDefaultAdapter()
            if (adapter != null && adapter.isEnabled) P.SERVICE_ENABLED else P.SERVICE_DISABLED
        }
        else -> P.SERVICE_NOT_APPLICABLE
    }
}
