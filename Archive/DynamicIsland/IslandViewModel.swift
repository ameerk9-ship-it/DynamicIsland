import Foundation
import Combine
import AppKit

/// وضع العرض الحالي للجزيرة
enum IslandMode: Equatable {
    case idle
    case battery(level: Int, charging: Bool, justPlugged: Bool)
    case music(title: String, artist: String, isPlaying: Bool, progress: Double)
    case volume(level: Double)
    case brightness(level: Double)
    case notification(title: String, body: String)
    case clipboard(preview: String)
    case network(connected: Bool, name: String)
    case expandedIdle // المستخدم فتحها يدويًا (الوقت/التاريخ)
}

final class IslandViewModel: ObservableObject {

    @Published var mode: IslandMode = .idle
    @Published var isExpandedByUser: Bool = false
    @Published var settings = IslandSettings.load()

    private var cancellables = Set<AnyCancellable>()
    private var autoCollapseTask: DispatchWorkItem?

    // المديرون
    private let batteryManager = BatteryManager()
    private let musicManager = MusicManager()
    private let volumeManager = VolumeManager()
    private let brightnessManager = BrightnessManager()
    private let clipboardManager = ClipboardManager()
    private let networkManager = NetworkManager()
    let notificationsManager = NotificationsManager()

    init() {
        settings.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.settings.save()
            }
            .store(in: &cancellables)

        bindManagers()
        startAllManagers()
    }

    // MARK: - ربط الأحداث بكل مدير

    private func bindManagers() {
        batteryManager.onUpdate = { [weak self] level, charging, justPlugged in
            guard let self, self.settings.enabledEvents.contains(.battery) else { return }
            self.present(.battery(level: level, charging: charging, justPlugged: justPlugged),
                         autoCollapseAfter: justPlugged ? 2.5 : 3.0)
        }

        musicManager.onUpdate = { [weak self] title, artist, isPlaying, progress in
            guard let self, self.settings.enabledEvents.contains(.music) else { return }
            if isPlaying || self.isCurrentlyShowingMusic {
                self.present(.music(title: title, artist: artist, isPlaying: isPlaying, progress: progress),
                             autoCollapseAfter: isPlaying ? nil : 3.0)
            }
        }

        volumeManager.onUpdate = { [weak self] level in
            guard let self, self.settings.enabledEvents.contains(.volume) else { return }
            self.present(.volume(level: level), autoCollapseAfter: 1.2)
        }

        brightnessManager.onUpdate = { [weak self] level in
            guard let self, self.settings.enabledEvents.contains(.brightness) else { return }
            self.present(.brightness(level: level), autoCollapseAfter: 1.2)
        }

        clipboardManager.onUpdate = { [weak self] text in
            guard let self, self.settings.enabledEvents.contains(.clipboard) else { return }
            self.present(.clipboard(preview: text), autoCollapseAfter: 2.5)
        }

        networkManager.onUpdate = { [weak self] connected, name in
            guard let self, self.settings.enabledEvents.contains(.network) else { return }
            self.present(.network(connected: connected, name: name), autoCollapseAfter: 2.5)
        }

        notificationsManager.onUpdate = { [weak self] title, body in
            guard let self, self.settings.enabledEvents.contains(.notification) else { return }
            self.present(.notification(title: title, body: body), autoCollapseAfter: 3.5)
        }
    }

    private var isCurrentlyShowingMusic: Bool {
        if case .music = mode { return true }
        return false
    }

    // MARK: - عرض حالة جديدة + إلغاء تلقائي بعد مدة

    private func present(_ newMode: IslandMode, autoCollapseAfter seconds: Double?) {
        guard settings.isEnabled else { return }
        autoCollapseTask?.cancel()

        // الأنيميشن الفعلي (spring) يتم التعامل معه داخل IslandView عبر .animation(value:)
        // بمجرد تغيّر @Published mode هنا، لسنا بحاجة لأي لفّ إضافي.
        mode = newMode

        guard let seconds = seconds else { return }
        let task = DispatchWorkItem { [weak self] in
            guard let self, self.mode == newMode, !self.isExpandedByUser else { return }
            self.mode = .idle
        }
        autoCollapseTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: task)
    }

    // MARK: - تفاعل المستخدم

    func toggleExpanded() {
        isExpandedByUser.toggle()
        if isExpandedByUser {
            mode = .expandedIdle
        } else {
            mode = .idle
        }
    }

    func collapseFromUserClickOutside() {
        guard isExpandedByUser else { return }
        isExpandedByUser = false
        mode = .idle
    }

    func handleIslandTap() {
        toggleExpanded()
    }

    // MARK: - التحكم بالموسيقى من الواجهة
    func musicPlayPause() { musicManager.playPause() }
    func musicNext() { musicManager.next() }
    func musicPrevious() { musicManager.previous() }

    func startAllManagers() {
        batteryManager.start()
        musicManager.start()
        volumeManager.start()
        brightnessManager.start()
        clipboardManager.start()
        networkManager.start()
    }

    func stopAllManagers() {
        batteryManager.stop()
        musicManager.stop()
        volumeManager.stop()
        brightnessManager.stop()
        clipboardManager.stop()
        networkManager.stop()
    }
}
