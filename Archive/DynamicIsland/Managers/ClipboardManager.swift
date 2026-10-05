import Foundation
import AppKit

/// macOS لا يوفر إشعارًا (notification) عند تغيّر الحافظة، لذلك الطريقة القياسية
/// والمستخدمة في كل تطبيقات Clipboard Manager هي مراقبة `changeCount` بشكل دوري خفيف جدًا.
final class ClipboardManager {

    var onUpdate: ((_ preview: String) -> Void)?

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount

    // كلمات مفتاحية بسيطة لاستبعاد محتوى قد يكون حساسًا (كلمات مرور من مديري كلمات المرور)
    private let sensitiveMarkerTypes: [NSPasteboard.PasteboardType] = [
        NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"),
        NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
    ]

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // احترام معيار "concealed/transient" الذي تستخدمه مديرو كلمات المرور
        // (1Password، Bitwarden، إلخ) لتعليم المحتوى الحساس
        let availableTypes = pasteboard.types ?? []
        if sensitiveMarkerTypes.contains(where: { availableTypes.contains($0) }) {
            return
        }

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }

        // تقصير المعاينة وعدم عرض نصوص طويلة جدًا (قد تحتوي بيانات حساسة/كبيرة)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 500 else { return } // تجاهل النصوص الضخمة (غالبًا ليست للعرض السريع)

        let preview = trimmed.count > 60 ? String(trimmed.prefix(60)) + "…" : trimmed
        onUpdate?(preview)
    }
}
