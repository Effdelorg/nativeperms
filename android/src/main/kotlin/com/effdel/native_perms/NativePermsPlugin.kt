package com.effdel.native_perms

import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class NativePermsPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var manager: PermissionManager
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "dev.effdel.native_perms/methods")
        channel.setMethodCallHandler(this)
        manager = PermissionManager(binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        manager.setActivity(binding.activity)
        binding.addRequestPermissionsResultListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun detachActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        manager.setActivity(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermissionStatus" -> {
                val perm = call.arguments as Int
                result.success(manager.checkPermissionStatus(perm))
            }
            "requestPermissions" -> {
                @Suppress("UNCHECKED_CAST")
                val perms = (call.arguments as List<Int>)
                manager.requestPermissions(perms) { map ->
                    result.success(map)
                }
            }
            "shouldShowRequestPermissionRationale" -> {
                val perm = call.arguments as Int
                result.success(manager.shouldShowRequestRationale(perm))
            }
            "checkServiceStatus" -> {
                val perm = call.arguments as Int
                val ctx = activityBinding?.activity ?: return result.success(
                    PermissionMapper.SERVICE_NOT_APPLICABLE,
                )
                result.success(ServiceManager.checkServiceStatus(ctx, perm))
            }
            "openAppSettings" -> {
                val ctx = activityBinding?.activity ?: return result.success(false)
                result.success(AppSettingsManager.openAppSettings(ctx))
            }
            else -> result.notImplemented()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean = manager.onRequestPermissionsResult(requestCode, permissions, grantResults)

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean =
        manager.onActivityResult(requestCode, resultCode, data)
}
