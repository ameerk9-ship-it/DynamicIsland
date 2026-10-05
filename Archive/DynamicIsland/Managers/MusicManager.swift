import Foundation
import AppKit

/// يتحكم في تطبيق "الموسيقى" (Music.app) عبر Apple Events (NSAppleScript)
/// هذه الطريقة عامة، موثقة، ومتوافقة من macOS القديم جدًا وحتى الأحدث.
/// أول استخدام سيطلب من macOS إذن "Automation" للتحكم في Music.app.
final class MusicManager {

    var onUpdate: ((_ title: String, _ artist: String, _ isPlaying: Bool, _ progress: Double) -> Void)?

    private var timer: Timer?
    private var lastTitle: String = ""
    private var lastIsPlaying: Bool = false

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer!, forMode: .common)
        poll()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard isMusicRunning() else {
            if lastIsPlaying { lastIsPlaying = false }
            return
        }

        let script = """
        tell application "Music"
            if player state is playing or player state is paused then
                set trackTitle to name of current track
                set trackArtist to artist of current track
                set trackPos to player position
                set trackDur to duration of current track
                set stateStr to (player state as string)
                return trackTitle & "||" & trackArtist & "||" & stateStr & "||" & trackPos & "||" & trackDur
            else
                return "NONE"
            end if
        end tell
        """

        guard let result = runAppleScript(script), result != "NONE" else { return }
        let parts = result.components(separatedBy: "||")
        guard parts.count == 5 else { return }

        let title = parts[0]
        let artist = parts[1]
        let isPlaying = parts[2] == "playing"
        let position = Double(parts[3]) ?? 0
        let duration = Double(parts[4]) ?? 1
        let progress = duration > 0 ? min(1.0, position / duration) : 0

        lastTitle = title
        lastIsPlaying = isPlaying
        onUpdate?(title, artist, isPlaying, progress)
    }

    private func isMusicRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.apple.Music"
        }
    }

    // MARK: - أوامر التحكم

    func playPause() {
        _ = runAppleScript("""
        tell application "Music" to playpause
        """)
    }

    func next() {
        _ = runAppleScript("""
        tell application "Music" to next track
        """)
    }

    func previous() {
        _ = runAppleScript("""
        tell application "Music" to previous track
        """)
    }

    @discardableResult
    private func runAppleScript(_ source: String) -> String? {
        guard let appleScript = NSAppleScript(source: source) else { return nil }
        var errorDict: NSDictionary?
        let result = appleScript.executeAndReturnError(&errorDict)
        if let errorDict = errorDict {
            NSLog("MusicManager AppleScript error: \(errorDict)")
            return nil
        }
        return result.stringValue
    }
}
