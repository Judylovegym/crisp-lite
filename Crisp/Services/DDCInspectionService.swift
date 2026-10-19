import Foundation

/// DDC feature detection for one display, mirroring the DDC panel BetterDisplay
/// shows (channel, communication, capabilities report, hardware brightness and
/// contrast). It answers once per display and caches; the view re-runs it when
/// the display is (re)opened.
@MainActor
final class DDCInspectionService: ObservableObject {
    static let shared = DDCInspectionService()

    struct Report {
        /// Whether an I²C channel exists for the display. nil before the first probe.
        var channelAvailable: Bool?
        /// Whether a VCP read answered. nil before the first probe.
        var communicationSupported: Bool?
        /// The capabilities string, nil when the monitor never answered it.
        var capabilities: String?
        /// Hardware brightness (VCP 0x10) and its max.
        var brightness: (current: UInt16, max: UInt16)?
        /// Hardware contrast (VCP 0x12) and its max.
        var contrast: (current: UInt16, max: UInt16)?
    }

    @Published private(set) var reports: [CGDirectDisplayID: Report] = [:]
    private var inflight: Set<CGDirectDisplayID> = []

    func report(for displayID: CGDirectDisplayID) -> Report? { reports[displayID] }

    /// Probes channel, communication, capabilities and hardware brightness /
    /// contrast once. Runs the reads asynchronously (capabilities can take tens
    /// of seconds on some monitors); a repeat call while a probe runs waits for it.
    func inspect(_ display: DisplayInfo) async {
        let id = display.displayID
        guard !inflight.contains(id) else { return }
        inflight.insert(id)
        defer { inflight.remove(id) }

        var report = Report()

        report.channelAvailable = DDCService.shared.channelLocation(for: id) != nil

        if await DDCService.shared.readInput(displayID: id) != nil {
            report.communicationSupported = true
        } else {
            report.communicationSupported = false
        }

        report.capabilities = await DDCService.shared.readCapabilities(displayID: id)

        report.brightness = await withCheckedContinuation { continuation in
            DDCService.shared.readAsync(displayID: id, command: DDCService.brightnessVCP) {
                continuation.resume(returning: $0)
            }
        }
        report.contrast = await withCheckedContinuation { continuation in
            DDCService.shared.readAsync(displayID: id, command: 0x12) {
                continuation.resume(returning: $0)
            }
        }

        reports[id] = report
    }
}
