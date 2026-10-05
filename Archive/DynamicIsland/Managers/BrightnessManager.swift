import Foundation
import AppKit
import IOKit

/// ملاحظة هامة (تمت مراجعتها بعناية):
/// macOS لا يوفر API عامًا رسميًا لقراءة "نسبة السطوع الحالية" لشاشة MacBook المدمجة
/// بدون استخدام Private Frameworks (مثل DisplayServices) وهو ما تم تجنبه هنا عمدًا
/// حتى لا يرفض Apple التطبيق أو ينكسر مع تحديثات النظام.
///
/// البديل العملي والمستقر: نرصد ضغط مفاتيح السطوع (F1 / F2) عبر NSEvent Global/Local Monitor
/// ونعرض تغييرًا تقريبيًا (+/- خطوة) بدل القيمة المطلقة، وهذا يعطي تجربة قريبة جدًا
/// من الأصلية بدون الاعتماد على أي API غير موثق.
final class BrightnessManager {

    var onUpdate: ((_ level: Double) -> Void)?

    // نتتبع قيمة تقريبية داخليًا فقط للعرض (0.0 ... 1.0)
    private var approximateLevel: Double = 0.75
    private var globalMonitor: Any?
    private var localMonitor: Any?

    // Keycode الخاص بمفاتيح السطوع على أغلب أجهزة Mac (النظام الخاص F1/F2 كأحداث NX)
    private let brightnessDownKeyCode: UInt16 = 107 // NX_KEYTYPE_BRIGHTNESS_DOWN (عبر system-defined events)
    private let brightnessUpKeyCode: UInt16 = 113   // NX_KEYTYPE_BRIGHTNESS_UP

    func start() {
        // نستخدم System Defined Events (NSEvent.EventType.systemDefined) وهي طريقة عامة معتمدة
        // منذ زمن طويل لرصد مفاتيح الميديا/السطوع، ومستخدمة في تطبيقات مفتوحة المصدر كثيرة.
        let mask: NSEvent.EventTypeMask = .systemDefined
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event: event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event: event)
            return event
        }
    }

    func stop() {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor { NSEvent.removeMonitor(m) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(event: NSEvent) {
        // subtype 8 = NX_SUBTYPE_AUX_CONTROL_BUTTONS وهو المستخدم لمفاتيح الميديا/السطوع
        guard event.subtype.rawValue == 8 else { return }
        let keyCode = (event.data1 & 0xFFFF0000) >> 16
        let keyState = ((event.data1 & 0xFF00) >> 8) == 0x0A // key down

        guard keyState else { return }

        switch Int(keyCode) {
        case Int(brightnessUpKeyCode):
            approximateLevel = min(1.0, approximateLevel + 0.0625)
            onUpdate?(approximateLevel)
        case Int(brightnessDownKeyCode):
            approximateLevel = max(0.0, approximateLevel - 0.0625)
            onUpdate?(approximateLevel)
        default:
            break
        }
    }
}
