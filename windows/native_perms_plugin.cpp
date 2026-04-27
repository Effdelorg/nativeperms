#include "native_perms_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace native_perms {

namespace {
// PermissionStatus / ServiceStatus indices mirror the Dart enums.
constexpr int kStatusGranted = 1;
constexpr int kServiceNotApplicable = 2;
}  // namespace

void NativePermsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "dev.effdel.native_perms/methods",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NativePermsPlugin>();
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

NativePermsPlugin::NativePermsPlugin() {}
NativePermsPlugin::~NativePermsPlugin() {}

void NativePermsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = method_call.method_name();

  if (method == "checkPermissionStatus") {
    result->Success(flutter::EncodableValue(kStatusGranted));
  } else if (method == "requestPermissions") {
    flutter::EncodableMap out;
    const auto* args =
        std::get_if<flutter::EncodableList>(method_call.arguments());
    if (args != nullptr) {
      for (const auto& v : *args) {
        const int* perm = std::get_if<int>(&v);
        if (perm != nullptr) {
          out[flutter::EncodableValue(*perm)] =
              flutter::EncodableValue(kStatusGranted);
        }
      }
    }
    result->Success(flutter::EncodableValue(out));
  } else if (method == "shouldShowRequestPermissionRationale") {
    result->Success(flutter::EncodableValue(false));
  } else if (method == "checkServiceStatus") {
    result->Success(flutter::EncodableValue(kServiceNotApplicable));
  } else if (method == "openAppSettings") {
    result->Success(flutter::EncodableValue(false));
  } else {
    result->NotImplemented();
  }
}

}  // namespace native_perms
