import SwiftUI

/// Settings > Shortcuts: the curated list of named global-shortcut actions
/// (issue #61). Toggle HiDPI, plus brightness up and down for keyboards whose
/// brightness keys are missing or taken (issue #160); the bar for adding another
/// is "someone asked". Per-preset shortcuts live on the
/// presets themselves, not here. Expands in place per DESIGN.md.
struct ShortcutsSection: View {
    @ObservedObject private var settings = SettingsService.shared
    // Owned by SettingsView so its panel-close reset collapses this section
    // like every other.
    @Binding var expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ExpandableRow(
                icon: "command",
                iconActive: settings.hidpiShortcut != nil
                    || settings.brightnessUpShortcut != nil
                    || settings.brightnessDownShortcut != nil
                    || settings.inputOneShortcut != nil
                    || settings.inputTwoShortcut != nil,
                // No combo subtitle: the header names a category, and a single
                // binding there reads as the section's own shortcut. Bindings
                // show only on their action rows inside.
                label: "Keyboard Shortcuts",
                isExpanded: $expanded
            )
            if expanded {
                ShortcutRecorderRow(
                    label: "Toggle HiDPI",
                    // Commits immediately (no form): store, take the combo off
                    // whatever else held it, re-register.
                    shortcut: binding(\.hidpiShortcut) { settings.hidpiShortcut = $0 },
                    leadingInset: 34
                )
                caption("Switches the display under the pointer between HiDPI and low resolution.")
                ShortcutRecorderRow(
                    label: "Brightness Up",
                    shortcut: binding(\.brightnessUpShortcut) { settings.brightnessUpShortcut = $0 },
                    leadingInset: 34
                )
                ShortcutRecorderRow(
                    label: "Brightness Down",
                    shortcut: binding(\.brightnessDownShortcut) { settings.brightnessDownShortcut = $0 },
                    leadingInset: 34
                )
                caption("Steps brightness like the brightness keys, on the same displays. For keyboards without them.")
                ShortcutRecorderRow(
                    label: "Switch Input 1",
                    shortcut: binding(\.inputOneShortcut) { settings.inputOneShortcut = $0 },
                    leadingInset: 34
                )
                inputPicker($settings.inputOneValue)
                ShortcutRecorderRow(
                    label: "Switch Input 2",
                    shortcut: binding(\.inputTwoShortcut) { settings.inputTwoShortcut = $0 },
                    leadingInset: 34
                )
                inputPicker($settings.inputTwoValue)
                caption("Switches the display under the pointer to the chosen input over DDC (HDMI, DisplayPort…). Another input disconnects the display; its Reconnect row brings it back.")
            }
        }
    }

    /// The target input for a Switch Input slot: the standard DDC inputs, with
    /// the chosen one named. Menu clicks stay out of the recorder's tap zone.
    private func inputPicker(_ value: Binding<UInt16>) -> some View {
        HStack(spacing: 6) {
            Text("Target Input")
                .font(.caption)
                .foregroundColor(.secondary)
            Menu {
                ForEach(DDCInputSource.standard, id: \.self) { input in
                    Button(inputName(input)) { value.wrappedValue = input }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "cable.connector")
                        .font(.caption)
                    Text(inputName(value.wrappedValue))
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.secondaryReadable)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
            }
            .menuStyle(.borderlessButton)
            .menuRowHover(false)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.leading, 34)
        .padding(.bottom, 2)
    }

    private func inputName(_ value: UInt16) -> String {
        DDCInputSource.name(for: value) ?? String(localized: "Input \(String(format: "0x%02X", value))")
    }

    private func binding(_ path: KeyPath<SettingsService, KeyboardShortcut?>,
                         assign: @escaping (KeyboardShortcut?) -> Void) -> Binding<KeyboardShortcut?> {
        Binding(
            get: { settings[keyPath: path] },
            set: { newValue in settings.assignStaticShortcut(newValue, assign: assign) }
        )
    }

    private func caption(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.leading, 34)
            .padding(.bottom, 4)
    }
}
