#include "include/nativeprems/nativeprems_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "nativeprems_plugin.h"

void NativePermsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  nativeprems::NativePermsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
