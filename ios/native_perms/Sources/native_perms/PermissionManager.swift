import AVFoundation
import AppTrackingTransparency
import CoreBluetooth
import CoreLocation
import CoreMotion
import Contacts
import EventKit
import Foundation
import MediaPlayer
import Photos
import Speech
import UIKit
import UserNotifications

/// Dispatches permission check / request calls to the right iOS API per
/// permission. Async-callback shape so multiple in-flight requests aggregate
/// cleanly.
final class PermissionManager {

    // MARK: - check (sync where possible)

    func checkPermissionStatus(_ permission: Int, completion: @escaping (Int) -> Void) {
        switch permission {
        case P.camera:
            completion(mapAVAuth(AVCaptureDevice.authorizationStatus(for: .video)))
        case P.microphone:
            completion(microphoneStatus())
        case P.location, P.locationWhenInUse:
            completion(mapCLAuth(LocationDelegate.shared.currentStatus, isAlways: false))
        case P.locationAlways:
            completion(mapCLAuth(LocationDelegate.shared.currentStatus, isAlways: true))
        case P.notification:
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                completion(self.mapUNSettings(settings))
            }
        case P.criticalAlerts:
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if #available(iOS 12.0, *) {
                    switch settings.criticalAlertSetting {
                    case .enabled: completion(P.granted)
                    case .disabled: completion(P.denied)
                    case .notSupported: completion(P.restricted)
                    @unknown default: completion(P.denied)
                    }
                } else { completion(P.denied) }
            }
        case P.photos:
            completion(photoStatus(addOnly: false))
        case P.photosAddOnly:
            completion(photoStatus(addOnly: true))
        case P.mediaLibrary:
            completion(mapMPAuth(MPMediaLibrary.authorizationStatus()))
        case P.contacts:
            completion(mapCNAuth(CNContactStore.authorizationStatus(for: .contacts)))
        case P.calendar:
            completion(eventStoreStatus(write: false))
        case P.calendarFullAccess:
            completion(eventStoreStatus(write: false))
        case P.calendarWriteOnly:
            completion(eventStoreStatus(write: true))
        case P.reminders:
            completion(reminderStatus())
        case P.speech:
            completion(mapSFAuth(SFSpeechRecognizer.authorizationStatus()))
        case P.sensors, P.sensorsAlways:
            if #available(iOS 11.0, *) {
                completion(mapCMAuth(CMMotionActivityManager.authorizationStatus()))
            } else { completion(P.granted) }
        case P.bluetooth, P.bluetoothScan, P.bluetoothConnect:
            completion(bluetoothStatus())
        case P.appTrackingTransparency:
            if #available(iOS 14, *) {
                completion(mapATTAuth(ATTrackingManager.trackingAuthorizationStatus))
            } else { completion(P.granted) }
        case P.assistant:
            // INPreferences requires the com.apple.developer.siri entitlement;
            // calling it without throws NSException. iOS exposes no public API
            // to detect entitlements at runtime, so we report denied. Apps that
            // ship the Siri capability use SiriKit (INPreferences) directly.
            completion(P.denied)
        case P.backgroundRefresh:
            switch UIApplication.shared.backgroundRefreshStatus {
            case .available: completion(P.granted)
            case .denied: completion(P.denied)
            case .restricted: completion(P.restricted)
            @unknown default: completion(P.denied)
            }
        // Android-only / not applicable on iOS — match upstream's granted/restricted.
        case P.phone, P.sms, P.storage, P.videos, P.audio,
             P.ignoreBatteryOptimizations, P.systemAlertWindow,
             P.requestInstallPackages, P.accessNotificationPolicy,
             P.scheduleExactAlarm, P.accessMediaLocation,
             P.activityRecognition, P.nearbyWifiDevices,
             P.bluetoothAdvertise:
            completion(P.granted)
        case P.manageExternalStorage:
            completion(P.restricted)
        case P.unknown:
            completion(P.denied)
        default:
            completion(P.denied)
        }
    }

    // MARK: - request

    func requestPermissions(_ permissions: [Int], completion: @escaping ([Int: Int]) -> Void) {
        if permissions.isEmpty { completion([:]); return }
        var seen = Set<Int>()
        let requested = permissions.filter { seen.insert($0).inserted }
        var results: [Int: Int] = [:]

        func requestNext(_ index: Int) {
            guard index < requested.count else {
                completion(results)
                return
            }
            let permission = requested[index]
            requestSingle(permission) { status in
                DispatchQueue.main.async {
                    results[permission] = status
                    requestNext(index + 1)
                }
            }
        }

        requestNext(0)
    }

    private func requestSingle(_ permission: Int, completion: @escaping (Int) -> Void) {
        switch permission {
        case P.camera:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted ? P.granted : P.permanentlyDenied)
            }
        case P.microphone:
            requestMicrophone(completion: completion)
        case P.locationWhenInUse, P.location:
            LocationDelegate.shared.request(always: false, completion: completion)
        case P.locationAlways:
            LocationDelegate.shared.request(always: true, completion: completion)
        case P.notification:
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, _ in
                if granted { completion(P.granted); return }
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    completion(self.mapUNSettings(settings))
                }
            }
        case P.criticalAlerts:
            var opts: UNAuthorizationOptions = [.alert, .badge, .sound]
            if #available(iOS 12.0, *) { opts.insert(.criticalAlert) }
            UNUserNotificationCenter.current().requestAuthorization(options: opts) { granted, _ in
                completion(granted ? P.granted : P.denied)
            }
        case P.photos:
            requestPhotos(addOnly: false, completion: completion)
        case P.photosAddOnly:
            requestPhotos(addOnly: true, completion: completion)
        case P.mediaLibrary:
            MPMediaLibrary.requestAuthorization { status in
                completion(self.mapMPAuth(status))
            }
        case P.contacts:
            CNContactStore().requestAccess(for: .contacts) { granted, _ in
                completion(granted ? P.granted : P.permanentlyDenied)
            }
        case P.calendar:
            requestEventStore(write: false, completion: completion)
        case P.calendarFullAccess:
            requestEventStore(write: false, completion: completion)
        case P.calendarWriteOnly:
            requestEventStore(write: true, completion: completion)
        case P.reminders:
            requestReminders(completion: completion)
        case P.speech:
            SFSpeechRecognizer.requestAuthorization { status in
                completion(self.mapSFAuth(status))
            }
        case P.sensors, P.sensorsAlways:
            if #available(iOS 11.0, *) {
                let mgr = CMMotionActivityManager()
                let cal = Calendar.current
                let now = Date()
                let yesterday = cal.date(byAdding: .day, value: -1, to: now) ?? now
                mgr.queryActivityStarting(from: yesterday, to: now, to: .main) { _, _ in
                    completion(self.mapCMAuth(CMMotionActivityManager.authorizationStatus()))
                }
            } else { completion(P.granted) }
        case P.bluetooth, P.bluetoothScan, P.bluetoothConnect:
            BluetoothAuthDelegate.shared.request(completion: completion)
        case P.appTrackingTransparency:
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    completion(self.mapATTAuth(status))
                }
            } else { completion(P.granted) }
        case P.assistant:
            // See checkPermissionStatus — INPreferences requires the Siri
            // entitlement and crashes without it.
            completion(P.denied)
        default:
            checkPermissionStatus(permission, completion: completion)
        }
    }

    // MARK: - mappers

    private func mapAVAuth(_ s: AVAuthorizationStatus) -> Int {
        switch s {
        case .authorized: return P.granted
        case .denied: return P.permanentlyDenied
        case .restricted: return P.restricted
        case .notDetermined: return P.denied
        @unknown default: return P.denied
        }
    }

    private func microphoneStatus() -> Int {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return P.granted
            case .denied: return P.permanentlyDenied
            case .undetermined: return P.denied
            @unknown default: return P.denied
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted: return P.granted
            case .denied: return P.permanentlyDenied
            case .undetermined: return P.denied
            @unknown default: return P.denied
            }
        }
    }

    private func requestMicrophone(completion: @escaping (Int) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                completion(granted ? P.granted : P.permanentlyDenied)
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                completion(granted ? P.granted : P.permanentlyDenied)
            }
        }
    }

    private func mapCLAuth(_ s: CLAuthorizationStatus, isAlways: Bool) -> Int {
        switch s {
        case .authorizedAlways: return P.granted
        case .authorizedWhenInUse: return isAlways ? P.denied : P.granted
        case .denied: return P.permanentlyDenied
        case .restricted: return P.restricted
        case .notDetermined: return P.denied
        @unknown default: return P.denied
        }
    }

    private func mapUNSettings(_ s: UNNotificationSettings) -> Int {
        switch s.authorizationStatus {
        case .authorized: return P.granted
        case .denied: return P.permanentlyDenied
        case .notDetermined: return P.denied
        case .provisional: return P.provisional
        case .ephemeral: return P.granted
        @unknown default: return P.denied
        }
    }

    private func photoStatus(addOnly: Bool) -> Int {
        if #available(iOS 14, *) {
            let level: PHAccessLevel = addOnly ? .addOnly : .readWrite
            return mapPHAuth(PHPhotoLibrary.authorizationStatus(for: level))
        } else {
            return mapPHAuth(PHPhotoLibrary.authorizationStatus())
        }
    }

    private func requestPhotos(addOnly: Bool, completion: @escaping (Int) -> Void) {
        if #available(iOS 14, *) {
            let level: PHAccessLevel = addOnly ? .addOnly : .readWrite
            PHPhotoLibrary.requestAuthorization(for: level) { status in
                completion(self.mapPHAuth(status))
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                completion(self.mapPHAuth(status))
            }
        }
    }

    private func mapPHAuth(_ s: PHAuthorizationStatus) -> Int {
        switch s {
        case .authorized: return P.granted
        case .limited: return P.limited
        case .denied: return P.permanentlyDenied
        case .restricted: return P.restricted
        case .notDetermined: return P.denied
        @unknown default: return P.denied
        }
    }

    private func mapMPAuth(_ s: MPMediaLibraryAuthorizationStatus) -> Int {
        switch s {
        case .authorized: return P.granted
        case .denied: return P.permanentlyDenied
        case .restricted: return P.restricted
        case .notDetermined: return P.denied
        @unknown default: return P.denied
        }
    }

    private func mapCNAuth(_ s: CNAuthorizationStatus) -> Int {
        switch s {
        case .authorized: return P.granted
        case .denied: return P.permanentlyDenied
        case .restricted: return P.restricted
        case .notDetermined: return P.denied
        @unknown default: return P.denied
        }
    }

    private func eventStoreStatus(write: Bool) -> Int {
        let raw = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            switch raw {
            case .fullAccess: return P.granted
            case .writeOnly: return write ? P.granted : P.denied
            case .authorized: return P.granted
            case .denied: return P.permanentlyDenied
            case .restricted: return P.restricted
            case .notDetermined: return P.denied
            @unknown default: return P.denied
            }
        } else {
            return mapLegacyEKAuth(raw)
        }
    }

    private func requestEventStore(write: Bool, completion: @escaping (Int) -> Void) {
        let store = EKEventStore()
        if #available(iOS 17.0, *) {
            if write {
                store.requestWriteOnlyAccessToEvents { granted, _ in
                    completion(granted ? P.granted : P.permanentlyDenied)
                }
            } else {
                store.requestFullAccessToEvents { granted, _ in
                    completion(granted ? P.granted : P.permanentlyDenied)
                }
            }
        } else {
            store.requestAccess(to: .event) { granted, _ in
                completion(granted ? P.granted : P.permanentlyDenied)
            }
        }
    }

    private func reminderStatus() -> Int {
        let raw = EKEventStore.authorizationStatus(for: .reminder)
        if #available(iOS 17.0, *) {
            switch raw {
            case .fullAccess, .authorized: return P.granted
            case .writeOnly: return P.denied
            case .denied: return P.permanentlyDenied
            case .restricted: return P.restricted
            case .notDetermined: return P.denied
            @unknown default: return P.denied
            }
        } else {
            return mapLegacyEKAuth(raw)
        }
    }

    private func requestReminders(completion: @escaping (Int) -> Void) {
        let store = EKEventStore()
        if #available(iOS 17.0, *) {
            store.requestFullAccessToReminders { granted, _ in
                completion(granted ? P.granted : P.permanentlyDenied)
            }
        } else {
            store.requestAccess(to: .reminder) { granted, _ in
                completion(granted ? P.granted : P.permanentlyDenied)
            }
        }
    }

    private func mapLegacyEKAuth(_ raw: EKAuthorizationStatus) -> Int {
        switch raw {
        case .authorized: return P.granted
        case .denied: return P.permanentlyDenied
        case .restricted: return P.restricted
        case .notDetermined: return P.denied
        default: return P.denied
        }
    }

    private func mapSFAuth(_ s: SFSpeechRecognizerAuthorizationStatus) -> Int {
        switch s {
        case .authorized: return P.granted
        case .denied: return P.permanentlyDenied
        case .restricted: return P.restricted
        case .notDetermined: return P.denied
        @unknown default: return P.denied
        }
    }

    @available(iOS 11.0, *)
    private func mapCMAuth(_ s: CMAuthorizationStatus) -> Int {
        switch s {
        case .authorized: return P.granted
        case .denied: return P.permanentlyDenied
        case .restricted: return P.restricted
        case .notDetermined: return P.denied
        @unknown default: return P.denied
        }
    }

    private func bluetoothStatus() -> Int {
        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .allowedAlways: return P.granted
            case .denied: return P.permanentlyDenied
            case .restricted: return P.restricted
            case .notDetermined: return P.denied
            @unknown default: return P.denied
            }
        } else {
            return P.granted
        }
    }

    @available(iOS 14, *)
    private func mapATTAuth(_ s: ATTrackingManager.AuthorizationStatus) -> Int {
        switch s {
        case .authorized: return P.granted
        case .denied: return P.permanentlyDenied
        case .restricted: return P.restricted
        case .notDetermined: return P.denied
        @unknown default: return P.denied
        }
    }

}

// MARK: - CLLocationManager delegate (callback-based for first-time auth requests)

private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    static let shared = LocationDelegate()
    private let manager = CLLocationManager()
    private var pending: ((Int) -> Void)?
    private var pendingIsAlways: Bool = false

    var currentStatus: CLAuthorizationStatus {
        if #available(iOS 14, *) { return manager.authorizationStatus }
        return CLLocationManager.authorizationStatus()
    }

    private override init() {
        super.init()
        manager.delegate = self
    }

    func request(always: Bool, completion: @escaping (Int) -> Void) {
        let current = currentStatus
        // Already-decided cases: short-circuit.
        switch current {
        case .authorizedAlways:
            completion(P.granted); return
        case .authorizedWhenInUse where !always:
            completion(P.granted); return
        case .denied:
            completion(P.permanentlyDenied); return
        case .restricted:
            completion(P.restricted); return
        default: break
        }
        pending = completion
        pendingIsAlways = always
        if always {
            manager.requestAlwaysAuthorization()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    }

    @available(iOS 14, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        deliver(manager.authorizationStatus)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        deliver(status)
    }

    private func deliver(_ status: CLAuthorizationStatus) {
        guard let cb = pending else { return }
        if status == .notDetermined { return } // wait for user to decide
        pending = nil
        let isAlways = pendingIsAlways
        switch status {
        case .authorizedAlways: cb(P.granted)
        case .authorizedWhenInUse: cb(isAlways ? P.denied : P.granted)
        case .denied: cb(P.permanentlyDenied)
        case .restricted: cb(P.restricted)
        case .notDetermined: cb(P.denied)
        @unknown default: cb(P.denied)
        }
    }
}

// MARK: - CBCentralManager delegate for iOS 13.1+ bluetooth auth (request implies usage prompt)

private final class BluetoothAuthDelegate: NSObject, CBCentralManagerDelegate {
    static let shared = BluetoothAuthDelegate()
    private var manager: CBCentralManager?
    private var pending: ((Int) -> Void)?

    func request(completion: @escaping (Int) -> Void) {
        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .allowedAlways:
                completion(P.granted); return
            case .denied:
                completion(P.permanentlyDenied); return
            case .restricted:
                completion(P.restricted); return
            default: break
            }
        }
        pending = completion
        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: nil, options: [
                CBCentralManagerOptionShowPowerAlertKey: false
            ])
        } else {
            // Re-fire the state callback path.
            centralManagerDidUpdateState(manager!)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let cb = pending else { return }
        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .allowedAlways:
                pending = nil; cb(P.granted)
            case .denied:
                pending = nil; cb(P.permanentlyDenied)
            case .restricted:
                pending = nil; cb(P.restricted)
            case .notDetermined:
                return
            @unknown default:
                pending = nil; cb(P.denied)
            }
        } else {
            pending = nil
            cb(central.state == .poweredOn ? P.granted : P.denied)
        }
    }
}
