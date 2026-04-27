import UIKit

enum AppSettingsManager {
    static func openAppSettings() -> Bool {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            return false
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
    }
}
