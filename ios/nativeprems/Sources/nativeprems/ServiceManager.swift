import CoreBluetooth
import CoreLocation
import Foundation

/// Service status (radio/service on/off) per permission. Most iOS permissions
/// have no separate service backing — those return notApplicable.
enum ServiceManager {
    static func checkServiceStatus(_ permission: Int, completion: @escaping (Int) -> Void) {
        switch permission {
        case P.location, P.locationAlways, P.locationWhenInUse:
            completion(CLLocationManager.locationServicesEnabled() ? P.serviceEnabled : P.serviceDisabled)
        case P.bluetooth, P.bluetoothScan, P.bluetoothConnect, P.bluetoothAdvertise:
            BluetoothServiceProbe.shared.check(completion: completion)
        case P.phone:
            // iOS apps cannot read SIM state without entitlements; treat as enabled.
            completion(P.serviceEnabled)
        default:
            completion(P.serviceNotApplicable)
        }
    }
}

/// Lightweight CB state cache. Created once; observes powered-on transitions.
private final class BluetoothServiceProbe: NSObject, CBCentralManagerDelegate {
    static let shared = BluetoothServiceProbe()
    private var manager: CBCentralManager?
    private var hasState = false
    var isPoweredOn: Bool = false
    private var pending: [(Int) -> Void] = []

    private override init() {
        super.init()
        // Defer alloc until first read so we don't trigger an authorization prompt
        // unrelated to the user's actual call.
    }

    func check(completion: @escaping (Int) -> Void) {
        if hasState {
            completion(isPoweredOn ? P.serviceEnabled : P.serviceDisabled)
            return
        }
        pending.append(completion)
        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: nil, options: [
                CBCentralManagerOptionShowPowerAlertKey: false
            ])
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        hasState = true
        isPoweredOn = (central.state == .poweredOn)
        let callbacks = pending
        pending.removeAll()
        let status = isPoweredOn ? P.serviceEnabled : P.serviceDisabled
        for callback in callbacks {
            callback(status)
        }
    }
}
