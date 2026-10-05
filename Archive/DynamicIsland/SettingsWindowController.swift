import Cocoa
import SwiftUI

final class SettingsWindowController: NSWindowController {

    init(viewModel: IslandViewModel) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "إعدادات Dynamic Island"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let hosting = NSHostingView(rootView: SettingsView(viewModel: viewModel))
        window.contentView = hosting
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
}
