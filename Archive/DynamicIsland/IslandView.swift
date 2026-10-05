import SwiftUI

struct IslandView: View {
    @ObservedObject var viewModel: IslandViewModel
    @State private var isHovering = false

    private var springAnimation: Animation {
        .interpolatingSpring(stiffness: 260, damping: 22)
            .speed(viewModel.settings.animationSpeed)
    }

    var body: some View {
        VStack {
            pillContent
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(viewModel.settings.opacity))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                .scaleEffect(isHovering ? 1.02 : 1.0)
                .animation(springAnimation, value: viewModel.mode)
                .animation(springAnimation, value: viewModel.isExpandedByUser)
                .animation(.easeOut(duration: 0.15), value: isHovering)
                .onHover { hovering in isHovering = hovering }
                .onTapGesture { viewModel.handleIslandTap() }
                .opacity(viewModel.settings.isEnabled ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 6)
    }

    private var cornerRadius: CGFloat {
        viewModel.isExpandedByUser ? 28 : 20
    }

    @ViewBuilder
    private var pillContent: some View {
        Group {
            if viewModel.isExpandedByUser {
                ExpandedContentView(viewModel: viewModel)
            } else {
                switch viewModel.mode {
                case .idle:
                    IdlePillView()
                case .battery(let level, let charging, let justPlugged):
                    BatteryPillView(level: level, charging: charging, justPlugged: justPlugged)
                case .music(let title, let artist, let isPlaying, let progress):
                    MusicPillView(title: title, artist: artist, isPlaying: isPlaying, progress: progress, viewModel: viewModel)
                case .volume(let level):
                    LevelPillView(systemImage: level == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill", level: level)
                case .brightness(let level):
                    LevelPillView(systemImage: "sun.max.fill", level: level)
                case .notification(let title, let body):
                    NotificationPillView(title: title, body: body)
                case .clipboard(let preview):
                    ClipboardPillView(preview: preview)
                case .network(let connected, let name):
                    NetworkPillView(connected: connected, name: name)
                case .expandedIdle:
                    ExpandedContentView(viewModel: viewModel)
                }
            }
        }
        .padding(.horizontal, viewModel.isExpandedByUser ? 20 : 14)
        .padding(.vertical, viewModel.isExpandedByUser ? 16 : 8)
        .foregroundColor(.white)
    }
}

// MARK: - أوضاع Minimal

private struct IdlePillView: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(Color.white.opacity(0.85)).frame(width: 6, height: 6)
        }
        .frame(minWidth: 20, minHeight: 12)
    }
}

private struct BatteryPillView: View {
    let level: Int
    let charging: Bool
    let justPlugged: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: charging ? "bolt.fill" : "battery.100")
                .foregroundColor(charging ? .green : .white)
            Text("\(level)%")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            if justPlugged {
                Text("جاري الشحن")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
            }
        }
    }
}

private struct MusicPillView: View {
    let title: String
    let artist: String
    let isPlaying: Bool
    let progress: Double
    let viewModel: IslandViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                Text(artist).font(.system(size: 11)).foregroundColor(.white.opacity(0.6)).lineLimit(1)
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(height: 3)
            }
            Spacer(minLength: 8)
            HStack(spacing: 14) {
                Button(action: viewModel.musicPrevious) {
                    Image(systemName: "backward.fill")
                }
                Button(action: viewModel.musicPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                }
                Button(action: viewModel.musicNext) {
                    Image(systemName: "forward.fill")
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 14))
        }
    }
}

private struct LevelPillView: View {
    let systemImage: String
    let level: Double

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.2))
                    Capsule().fill(Color.white).frame(width: geo.size.width * level)
                }
            }
            .frame(width: 120, height: 5)
            Text("\(Int(level * 100))%")
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
    }
}

private struct NotificationPillView: View {
    let title: String
    let body: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.fill")
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                Text(body).font(.system(size: 11)).foregroundColor(.white.opacity(0.7)).lineLimit(1)
            }
        }
    }
}

private struct ClipboardPillView: View {
    let preview: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard.fill")
            Text(preview).font(.system(size: 12)).lineLimit(1)
        }
    }
}

private struct NetworkPillView: View {
    let connected: Bool
    let name: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: connected ? "wifi" : "wifi.slash")
                .foregroundColor(connected ? .green : .red)
            Text(name).font(.system(size: 12, weight: .medium)).lineLimit(1)
        }
    }
}

// MARK: - الوضع الموسّع (Expanded) عند الضغط على الجزيرة

private struct ExpandedContentView: View {
    @ObservedObject var viewModel: IslandViewModel
    @State private var now = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(timeString)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Spacer()
                Text(dateString)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            Divider().background(Color.white.opacity(0.15))
            if case .music(let title, let artist, let isPlaying, let progress) = lastKnownMusicMode {
                MusicPillView(title: title, artist: artist, isPlaying: isPlaying, progress: progress, viewModel: viewModel)
            } else {
                Text("اضغط خارج الجزيرة للإغلاق")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .onReceive(timer) { now = $0 }
    }

    private var lastKnownMusicMode: IslandMode { viewModel.mode }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.locale = Locale(identifier: "ar")
        return f.string(from: now)
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE، d MMMM"
        f.locale = Locale(identifier: "ar")
        return f.string(from: now)
    }
}
