import Foundation
import IOKit.ps

/// يستخدم IOPowerSources API العام (متاح من macOS القديم جدًا وآمن تمامًا)
final class BatteryManager {

    var onUpdate: ((_ level: Int, _ charging: Bool, _ justPlugged: Bool) -> Void)?

    private var runLoopSource: CFRunLoopSource?
    private var lastCharging: Bool?

    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { context in
            guard let context = context else { return }
            let manager = Unmanaged<BatteryManager>.fromOpaque(context).takeUnretainedValue()
            manager.refresh()
        }
        if let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        refresh()
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        runLoopSource = nil
    }

    private func refresh() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let first = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, first)?.takeUnretainedValue() as? [String: Any]
        else { return }

        let capacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
        let percentage = maxCapacity > 0 ? Int((Double(capacity) / Double(maxCapacity)) * 100.0) : capacity
        let state = description[kIOPSPowerSourceStateKey] as? String
        let charging = state == kIOPSACPowerValue

        let justPlugged = (lastCharging == false && charging == true)
        lastCharging = charging

        onUpdate?(percentage, charging, justPlugged)
    }
}
