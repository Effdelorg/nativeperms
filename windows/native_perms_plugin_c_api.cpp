#include "include/native_perms/native_perms_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "native_perms_plugin.h"

void NativePermsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  native_perms::NativePermsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
