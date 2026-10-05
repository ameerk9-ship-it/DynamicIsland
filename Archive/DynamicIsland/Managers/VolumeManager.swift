import Foundation
import CoreAudio
import AudioToolbox

/// يراقب الـ default output device ويستمع لتغيّر الـ Volume عبر CoreAudio (API عام مستقر)
final class VolumeManager {

    var onUpdate: ((_ level: Double) -> Void)?

    private var listenerBlock: AudioObjectPropertyListenerBlock?
    private var currentDeviceID: AudioDeviceID = kAudioObjectUnknown

    func start() {
        currentDeviceID = defaultOutputDevice()
        addVolumeListener(on: currentDeviceID)
    }

    func stop() {
        removeVolumeListener(on: currentDeviceID)
    }

    private func defaultOutputDevice() -> AudioDeviceID {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return deviceID
    }

    private func addVolumeListener(on deviceID: AudioDeviceID) {
        guard deviceID != kAudioObjectUnknown else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)

        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.readCurrentVolume(deviceID: deviceID)
        }
        listenerBlock = block
        AudioObjectAddPropertyListenerBlock(deviceID, &address, DispatchQueue.main, block)
    }

    private func removeVolumeListener(on deviceID: AudioDeviceID) {
        guard deviceID != kAudioObjectUnknown, let block = listenerBlock else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectRemovePropertyListenerBlock(deviceID, &address, DispatchQueue.main, block)
    }

    private func readCurrentVolume(deviceID: AudioDeviceID) {
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
        guard status == noErr else { return }
        onUpdate?(Double(volume))
    }
}
