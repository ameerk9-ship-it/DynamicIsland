import Foundation
import Combine

/// كل الأحداث التي تدعمها الجزيرة
enum IslandEventType: String, CaseIterable, Identifiable, Codable {
    case battery, music, volume, brightness, notification, clipboard, network
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .battery: return "البطارية"
        case .music: return "الموسيقى"
        case .volume: return "الصوت"
        case .brightness: return "السطوع"
        case .notification: return "الإشعارات"
        case .clipboard: return "الحافظة (Clipboard)"
        case .network: return "الشبكة"
        }
    }
}

final class IslandSettings: ObservableObject, Codable {

    @Published var isEnabled: Bool = true
    @Published var launchAtLogin: Bool = false
    @Published var animationSpeed: Double = 1.0      // 0.5 (بطيء) ... 2.0 (سريع)
    @Published var islandScale: Double = 1.0         // حجم الجزيرة الأساسي
    @Published var opacity: Double = 1.0
    @Published var appearance: String = "dark"       // dark / light
    @Published var enabledEvents: Set<IslandEventType> = Set(IslandEventType.allCases)

    enum CodingKeys: String, CodingKey {
        case isEnabled, launchAtLogin, animationSpeed, islandScale, opacity, appearance, enabledEvents
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        animationSpeed = try c.decodeIfPresent(Double.self, forKey: .animationSpeed) ?? 1.0
        islandScale = try c.decodeIfPresent(Double.self, forKey: .islandScale) ?? 1.0
        opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        appearance = try c.decodeIfPresent(String.self, forKey: .appearance) ?? "dark"
        let events = try c.decodeIfPresent([IslandEventType].self, forKey: .enabledEvents) ?? IslandEventType.allCases
        enabledEvents = Set(events)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(isEnabled, forKey: .isEnabled)
        try c.encode(launchAtLogin, forKey: .launchAtLogin)
        try c.encode(animationSpeed, forKey: .animationSpeed)
        try c.encode(islandScale, forKey: .islandScale)
        try c.encode(opacity, forKey: .opacity)
        try c.encode(appearance, forKey: .appearance)
        try c.encode(Array(enabledEvents), forKey: .enabledEvents)
    }

    static let defaultsKey = "DynamicIsland.Settings.v1"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    static func load() -> IslandSettings {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let settings = try? JSONDecoder().decode(IslandSettings.self, from: data) else {
            return IslandSettings()
        }
        return settings
    }

    func resetToDefaults() {
        isEnabled = true
        launchAtLogin = false
        animationSpeed = 1.0
        islandScale = 1.0
        opacity = 1.0
        appearance = "dark"
        enabledEvents = Set(IslandEventType.allCases)
        save()
    }
}
