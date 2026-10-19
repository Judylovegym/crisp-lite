import SwiftUI

/// The DDC feature-detection section, mirroring BetterDisplay's DDC panel:
/// channel availability, communication support, capabilities report, and the
/// monitor's hardware brightness / contrast values.

struct DDCHeadBlock: View {
    let display: DisplayInfo
    @ObservedObject var state: PanelSectionState

    var body: some View {
        ExpandableRow(
            icon: "antenna.radiowaves.left.and.right",
            iconActive: false,
            label: "DDC Detection",
            isExpanded: state.openBinding(\.ddcOpenIDs, display.displayID)
        )
    }
}

struct DDCBodyBlock: View {
    @ObservedObject var display: DisplayInfo
    @ObservedObject var state: PanelSectionState
    @ObservedObject private var service = DDCInspectionService.shared
    @State private var showFullReport = false

    private var isOpen: Bool { state.ddcOpenIDs.contains(display.displayID) }

    var body: some View {
        Group {
            if let report = service.report(for: display.displayID) {
                content(report)
            } else {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.5).frame(width: 14, height: 14)
                    Text("Reading DDC information…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
        .onChange(of: isOpen) { _, open in
            if open { Task { await service.inspect(display) } }
        }
    }

    @ViewBuilder
    private func content(_ report: DDCInspectionService.Report) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            DDCStatusRow("DDC Channel", report.channelAvailable == true ? "Available" : "Unavailable")
            DDCStatusRow("DDC Communication", report.communicationSupported == true ? "Supported" : "Not Supported")
            DDCStatusRow("DDC Capabilities Report", report.capabilities != nil ? "Fetched" : "Not Fetched")

            // The full capabilities string, revealed on demand.
            HStack(spacing: 8) {
                Text("Detailed DDC Report")
                    .font(.body)
                Spacer()
                Button(showFullReport ? "Hide" : "Show") {
                    withAnimation(.panelResize) { showFullReport.toggle() }
                }
                .buttonStyle(.link)
                .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
            if showFullReport, let caps = report.capabilities {
                Text(caps)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(nil)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            } else if let caps = report.capabilities {
                Text(caps)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }

            SectionDivider()

            if let brightness = report.brightness, brightness.max > 0 {
                hardwareRow("Brightness (Hardware)", current: brightness.current, max: brightness.max)
            }
            if let contrast = report.contrast, contrast.max > 0 {
                hardwareRow("Contrast (Hardware)", current: contrast.current, max: contrast.max)
            }
        }
    }

    private func hardwareRow(_ label: LocalizedStringKey, current: UInt16, max: UInt16) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.body)
            Text("Maximum: \(Int(max)) · Current: \(Int(current))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }
}

private struct DDCStatusRow: View {
    let label: LocalizedStringKey
    let status: LocalizedStringKey

    init(_ label: LocalizedStringKey, _ status: LocalizedStringKey) {
        self.label = label
        self.status = status
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.body)
            Spacer()
            Text(status)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }
}
