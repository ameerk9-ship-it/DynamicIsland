import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    var islandWindowController: IslandWindowController?
    var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // نتأكد من عدم ظهور أيقونة في الـ Dock حتى لو تغيّر شيء لاحقًا
        NSApp.setActivationPolicy(.accessory)

        let viewModel = IslandViewModel()
        islandWindowController = IslandWindowController(viewModel: viewModel)
        islandWindowController?.showWindow(nil)

        setupGlobalShortcuts(viewModel: viewModel)
        setupMenuBarFallback(viewModel: viewModel)
    }

    func applicationWillTerminate(_ notification: Notification) {
        islandWindowController?.viewModel.stopAllManagers()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Global Keyboard Shortcut (⌥⌘I لإظهار/إخفاء الجزيرة)
    private var globalMonitor: Any?

    private func setupGlobalShortcuts(viewModel: IslandViewModel) {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // ⌥⌘I = toggle
            if event.modifierFlags.contains([.option, .command]),
               event.charactersIgnoringModifiers?.lowercased() == "i" {
                DispatchQueue.main.async {
                    viewModel.toggleExpanded()
                }
            }
        }
    }

    // MARK: - أيقونة بسيطة في الـ Menu Bar للوصول للإعدادات
    // (لأن التطبيق بدون Dock icon، لازم مكان يفتح منه المستخدم الإعدادات)
    private var statusItem: NSStatusItem?

    private func setupMenuBarFallback(viewModel: IslandViewModel) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "smallcircle.filled.circle", accessibilityDescription: "Dynamic Island")
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "الإعدادات...", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        let toggleItem = NSMenuItem(title: "تفعيل/إيقاف الجزيرة", action: #selector(toggleEnabled), keyEquivalent: "")
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "خروج", action: #selector(quit), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(viewModel: islandWindowController!.viewModel)
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleEnabled() {
        islandWindowController?.viewModel.settings.isEnabled.toggle()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
