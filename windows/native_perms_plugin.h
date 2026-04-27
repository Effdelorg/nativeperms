#ifndef FLUTTER_PLUGIN_NATIVE_PERMS_PLUGIN_H_
#define FLUTTER_PLUGIN_NATIVE_PERMS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace native_perms {

class NativePermsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  NativePermsPlugin();
  virtual ~NativePermsPlugin();

  NativePermsPlugin(const NativePermsPlugin&) = delete;
  NativePermsPlugin& operator=(const NativePermsPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace native_perms

#endif  // FLUTTER_PLUGIN_NATIVE_PERMS_PLUGIN_H_
