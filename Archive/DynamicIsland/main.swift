import Cocoa

// نستخدم NSApplicationMain اليدوي عشان نتحكم بالكامل في دورة الحياة
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // بدون Dock icon وبدون Cmd+Tab
app.run()
