import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: IslandViewModel

    var body: some View {
        Form {
            Section {
                Toggle("تفعيل الجزيرة", isOn: $viewModel.settings.isEnabled)
                Toggle("التشغيل عند بدء تسجيل الدخول", isOn: Binding(
                    get: { viewModel.settings.launchAtLogin },
                    set: { newValue in
                        viewModel.settings.launchAtLogin = newValue
                        LoginItemManager.setEnabled(newValue)
                    }
                ))
            }

            Section("المظهر") {
                Picker("المظهر", selection: $viewModel.settings.appearance) {
                    Text("داكن").tag("dark")
                    Text("فاتح").tag("light")
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("سرعة الأنيميشن")
                    Slider(value: $viewModel.settings.animationSpeed, in: 0.5...2.0)
                    Text(String(format: "%.1fx", viewModel.settings.animationSpeed))
                        .frame(width: 40)
                }

                HStack {
                    Text("حجم الجزيرة")
                    Slider(value: $viewModel.settings.islandScale, in: 0.7...1.3)
                }

                HStack {
                    Text("الشفافية")
                    Slider(value: $viewModel.settings.opacity, in: 0.5...1.0)
                }
            }

            Section("الأحداث المفعّلة") {
                ForEach(IslandEventType.allCases) { event in
                    Toggle(event.displayName, isOn: Binding(
                        get: { viewModel.settings.enabledEvents.contains(event) },
                        set: { isOn in
                            if isOn {
                                viewModel.settings.enabledEvents.insert(event)
                            } else {
                                viewModel.settings.enabledEvents.remove(event)
                            }
                        }
                    ))
                }
            }

            Section {
                Button("إعادة الضبط للإعدادات الافتراضية", role: .destructive) {
                    viewModel.settings.resetToDefaults()
                }
            }

            Section("اختصارات لوحة المفاتيح") {
                Text("⌥ ⌘ I  — إظهار/إخفاء الجزيرة الموسّعة")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 420, height: 480)
    }
}
