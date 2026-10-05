import Cocoa
import SwiftUI
import Combine

/// نافذة بدون إطار (Borderless NSPanel)، شفافة، Always On Top،
/// لا تظهر في Mission Control ولا تسرق التركيز (non-activating).
final class IslandWindowController: NSWindowController {

    let viewModel: IslandViewModel
    private var clickOutsideMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: IslandViewModel) {
        self.viewModel = viewModel

        let panel = IslandPanel(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 220),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar // Always On Top
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false // نحتاج نستقبل clicks على الجزيرة نفسها

        super.init(window: panel)

        let hosting = NSHostingView(rootView: IslandView(viewModel: viewModel))
        hosting.frame = NSRect(origin: .zero, size: panel.frame.size)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        positionAtTopCenter()
        observeScreenChanges()
        setupClickOutsideToCollapse()
        observeContentSize()
    }

    /// نُصغّر إطار النافذة الفعلي ليطابق حجم المحتوى المرئي فقط (Pill صغيرة عادةً)،
    /// حتى لا "تسدّ" النافذة الشفافة الكبيرة الضغط على عناصر macOS أسفلها
    /// أثناء الوضع العادي (Minimal)، وتتمدد فقط أثناء التفاعل الفعلي.
    private func observeContentSize() {
        Publishers.CombineLatest(viewModel.$mode, viewModel.$isExpandedByUser)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode, expanded in
                self?.resizeToFit(mode: mode, expanded: expanded)
            }
            .store(in: &cancellables)
    }

    private func resizeToFit(mode: IslandMode, expanded: Bool) {
        let size: NSSize
        if expanded {
            size = NSSize(width: 420, height: 220)
        } else {
            switch mode {
            case .idle:
                size = NSSize(width: 170, height: 40)
            case .music:
                size = NSSize(width: 380, height: 90)
            default:
                size = NSSize(width: 320, height: 70)
            }
        }
        guard let screen = NSScreen.main, let window = window else { return }
        let origin = NSPoint(x: screen.frame.midX - size.width / 2, y: screen.frame.maxY - size.height)
        window.setFrame(NSRect(origin: origin, size: size), display: true, animate: true)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: - التموضع أعلى منتصف الشاشة الأساسية فقط (كما طُلب)

    private func positionAtTopCenter() {
        guard let screen = NSScreen.main, let window = window else { return }
        let screenFrame = screen.frame
        let width: CGFloat = 620
        let height: CGFloat = 220
        // نضع أعلى حافة الجزيرة ملاصقة تقريبًا لمكان الـ notch/الكاميرا
        let topInset: CGFloat = 0
        let origin = NSPoint(
            x: screenFrame.midX - width / 2,
            y: screenFrame.maxY - height - topInset
        )
        window.setFrame(NSRect(origin: origin, size: NSSize(width: width, height: height)), display: true)
    }

    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenParamsChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil
        )
    }

    @objc private func screenParamsChanged() {
        positionAtTopCenter()
    }

    // MARK: - إغلاق الوضع الموسّع عند الضغط خارج الجزيرة

    private func setupClickOutsideToCollapse() {
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.viewModel.collapseFromUserClickOutside()
        }
    }

    deinit {
        if let m = clickOutsideMonitor { NSEvent.removeMonitor(m) }
        NotificationCenter.default.removeObserver(self)
    }
}

/// NSPanel مخصص: canBecomeKey = false يمنع النافذة من سرقة التركيز
/// من التطبيق الذي يعمل عليه المستخدم (متطلب أساسي مذكور في الطلب)
final class IslandPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
