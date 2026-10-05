import Foundation
import UserNotifications

/// ملاحظة صريحة ومهمة (لا نريد تطبيقًا "يبدو أنه يعمل" فقط):
/// macOS لا يسمح لأي تطبيق خارجي بقراءة أو اعتراض إشعارات التطبيقات الأخرى
/// (مثل الواتساب أو الإيميل) إلا عبر الوصول لقاعدة بيانات NotificationCenter
/// الخاصة (private database, غير موثقة، وتحتاج Full Disk Access، وتتغيّر بنية
/// جدولها بين إصدارات macOS بلا سابق إنذار). هذا غير مستقر إطلاقًا على المدى
/// الطويل، لذلك تم تعمّد عدم تنفيذه هنا.
///
/// ما يوفره هذا الملف بدلًا من ذلك:
/// 1. نظام Notification داخلي يمكن لأي جزء من هذا التطبيق استخدامه لعرض
///    رسالة داخل الجزيرة (مثال: "تم تفعيل الشاحن"، "تم تغيير الشبكة").
/// 2. يمكن لاحقًا لأي تطبيق آخر يملكه المستخدم إرسال إشعار للجزيرة عبر
///    Distributed Notification باسم مخصص (موضّح بالأسفل) دون الحاجة لأي API خاص.
final class NotificationsManager {

    var onUpdate: ((_ title: String, _ body: String) -> Void)?

    static let externalNotificationName = Notification.Name("com.amir.dynamicisland.externalNotify")

    func start() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleExternal(_:)),
            name: Self.externalNotificationName,
            object: nil
        )
    }

    func stop() {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    /// استدعِ هذه الدالة من أي مكان داخل التطبيق لعرض رسالة داخل الجزيرة
    func post(title: String, body: String) {
        onUpdate?(title, body)
    }

    @objc private func handleExternal(_ note: Notification) {
        guard let info = note.userInfo,
              let title = info["title"] as? String,
              let body = info["body"] as? String else { return }
        DispatchQueue.main.async {
            self.onUpdate?(title, body)
        }
    }
}
