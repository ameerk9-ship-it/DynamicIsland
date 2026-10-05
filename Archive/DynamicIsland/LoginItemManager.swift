import Foundation
import ServiceManagement
import AppKit

/// إدارة "Launch at Login" بطريقة متوافقة مع macOS القديم (Big Sur/Monterey على 2015 MacBook)
/// SMAppService الحديث متاح فقط من macOS 13، لذلك نستخدم هنا الطريقة الكلاسيكية
/// عبر إضافة/حذف عنصر Login Items من خلال System Events (Apple Events عامة وموثقة)
/// بدلًا من واجهات خاصة غير موثقة.
enum LoginItemManager {

    static func setEnabled(_ enabled: Bool) {
        let appPath = Bundle.main.bundlePath // String عادي (وليس Optional) لتفادي طباعة "Optional(...)" داخل الـ AppleScript
        let script: String
        if enabled {
            script = """
            tell application "System Events"
                if not (exists login item "DynamicIsland") then
                    make login item at end with properties {path:"\(appPath)", hidden:false}
                end if
            end tell
            """
        } else {
            script = """
            tell application "System Events"
                if exists login item "DynamicIsland" then
                    delete login item "DynamicIsland"
                end if
            end tell
            """
        }
        guard let appleScript = NSAppleScript(source: script) else { return }
        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)
        if let error = error {
            NSLog("LoginItemManager error: \(error)")
        }
    }
}
