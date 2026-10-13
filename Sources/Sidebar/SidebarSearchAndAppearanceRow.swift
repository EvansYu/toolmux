import CmuxSettings
import SwiftUI

/// Search + appearance row pinned above the workspace list.
///
/// The left control is the shared native sidebar search field (also used by
/// Find and Vault); the trailing gear opens the appearance popover.
struct SidebarSearchRow: View {
    @Binding var searchText: String
    @State private var showsAppearanceSettings = false

    var body: some View {
        HStack(spacing: 6) {
            SidebarSearchFieldView(
                text: $searchText,
                placeholder: String(
                    localized: "sidebar.search.placeholder",
                    defaultValue: "搜索分组和工作区"
                ),
                accessibilityIdentifier: "sidebar.searchField",
                onSubmit: {},
                onCommandSubmit: {}
            )
            .frame(height: 29)
            Button {
                showsAppearanceSettings.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .safeHelp(String(
                localized: "sidebar.appearance.tooltip",
                defaultValue: "Appearance settings"
            ))
            .accessibilityLabel(String(
                localized: "sidebar.appearance.accessibilityLabel",
                defaultValue: "Appearance settings"
            ))
            .popover(isPresented: $showsAppearanceSettings, arrowEdge: .bottom) {
                SidebarAppearanceSettingsView()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

/// Appearance settings popover content: per-section controls for group names,
/// workspace names, workspace background, terminal theme, and tab titles.
/// Every control persists to UserDefaults; rows pick changes up through the
/// existing settings snapshot rebuild (and tabs through @AppStorage).
struct SidebarAppearanceSettingsView: View {
    @Environment(\.cmuxAccentColor) private var cmuxAccent
    @AppStorage(SidebarAppearanceDefaults.groupNameFontBoostKey) private var groupNameBoost = SidebarGroupNameFontBoost.defaultBoost
    @AppStorage(SidebarAppearanceDefaults.groupNameFontFamilyKey) private var groupNameFontFamily = ""
    @AppStorage(SidebarAppearanceDefaults.groupNameColorHexKey) private var groupNameColorHex = ""

    @AppStorage(SidebarAppearanceDefaults.workspaceNameFontSizeDeltaKey) private var workspaceNameSizeDelta = 0.0
    @AppStorage(SidebarAppearanceDefaults.workspaceNameFontFamilyKey) private var workspaceNameFontFamily = ""
    @AppStorage(SidebarAppearanceDefaults.workspaceNameColorHexKey) private var workspaceNameColorHex = ""

    @AppStorage(SidebarAppearanceDefaults.workspaceTintColorHexKey) private var workspaceTintColorHex = ""
    @AppStorage(SidebarAppearanceDefaults.workspaceTintOpacityKey) private var workspaceTintOpacity = 0.05

    @AppStorage(SidebarAppearanceDefaults.tabTitleFontSizeDeltaKey) private var tabTitleSizeDelta = 0.0
    @AppStorage(SidebarAppearanceDefaults.tabTitleColorHexKey) private var tabTitleColorHex = ""

    @State private var ghosttyTheme = SidebarGhosttyTheme.current()

    private static let fontChoices: [(name: String, label: String)] = [
        ("", "系统默认"),
        ("Maple Mono NF CN", "Maple Mono"),
        ("Menlo", "Menlo"),
        ("SF Mono", "SF Mono"),
        ("PingFang SC", "苹方"),
        ("Helvetica Neue", "Helvetica"),
    ]

    private static let themeChoices: [String] = [
        "TokyoNight Storm", "TokyoNight Night", "Catppuccin Mocha",
        "GitHub Dark Default", "GitHub Dark", "Atom One Dark", "Dracula",
        "Catppuccin Frappe", "TokyoNight Moon", "Desert",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("外观设置")
                .cmuxFont(size: 13, weight: .bold)
                .foregroundStyle(.primary)

            SectionCard(title: "分组名称") {
                VStack(spacing: 8) {
                    SliderRow(
                        label: "字号",
                        value: $groupNameBoost,
                        range: 0...8,
                        format: { "+\(String(format: "%.1f", $0))pt" }
                    )
                    PickerRow(label: "字体", selection: $groupNameFontFamily, choices: Self.fontChoices)
                    ColorRow(label: "颜色", hexString: $groupNameColorHex)
                }
            }

            SectionCard(title: "工作区名称") {
                VStack(spacing: 8) {
                    SliderRow(
                        label: "字号",
                        value: $workspaceNameSizeDelta,
                        range: -2...4,
                        format: { ($0 >= 0 ? "+" : "") + String(format: "%.1f", $0) + "pt" }
                    )
                    PickerRow(label: "字体", selection: $workspaceNameFontFamily, choices: Self.fontChoices)
                    ColorRow(label: "颜色", hexString: $workspaceNameColorHex)
                }
            }

            SectionCard(title: "工作区背景") {
                VStack(spacing: 8) {
                    ColorRow(label: "颜色", hexString: $workspaceTintColorHex)
                    SliderRow(
                        label: "浓度",
                        value: $workspaceTintOpacity,
                        range: 0...0.2,
                        format: { String(format: "%.0f%%", $0 * 100) }
                    )
                }
            }

            SectionCard(title: "终端主题") {
                Picker("主题", selection: $ghosttyTheme) {
                    ForEach(Self.themeChoices, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: ghosttyTheme) { newTheme in
                    SidebarGhosttyTheme.set(newTheme)
                }
            }

            SectionCard(title: "页签名称") {
                VStack(spacing: 8) {
                    SliderRow(
                        label: "字号",
                        value: $tabTitleSizeDelta,
                        range: -2...4,
                        format: { String(format: "%+.1f", $0) }
                    )
                    ColorRow(label: "颜色", hexString: $tabTitleColorHex)
                }
            }
        }
        .padding(14)
        .frame(width: 280)
    }
}

/// Dark rounded card matching the app's dialog/palette aesthetic.
private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .cmuxFont(size: 11, weight: .medium)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

/// Label + slider + value readout, app-style compact row.
private struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: (Double) -> String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .cmuxFont(size: 11, weight: .regular)
                .foregroundStyle(.primary)
            Slider(value: $value, in: range, step: 0.5)
            Text(format(value))
                .cmuxFont(size: 11, design: .monospaced)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

/// Label + segmented font picker, app-style compact row.
private struct PickerRow: View {
    let label: String
    @Binding var selection: String
    let choices: [(name: String, label: String)]

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .cmuxFont(size: 11, weight: .regular)
                .foregroundStyle(.primary)
            Spacer(minLength: 4)
            Picker(label, selection: $selection) {
                ForEach(choices, id: \.name) { choice in
                    Text(choice.label).tag(choice.name)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 140)
        }
    }
}

/// Label + color well + clear action, app-style compact row.
private struct ColorRow: View {
    let label: String
    @Binding var hexString: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .cmuxFont(size: 11, weight: .regular)
                .foregroundStyle(.primary)
            Spacer(minLength: 4)
            SidebarColorWell(hexString: $hexString)
            if !hexString.isEmpty {
                Button {
                    hexString = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("恢复默认")
            }
        }
    }
}

/// NSColorPicker-backed hex string control: shows the color swatch and opens
/// the system color panel on click.
private struct SidebarColorWell: NSViewRepresentable {
    @Binding var hexString: String

    func makeNSView(context: Context) -> NSColorWell {
        let well = NSColorWell()
        well.color = NSColor(hex: hexString) ?? .clear
        well.target = context.coordinator
        well.action = #selector(Coordinator.colorChanged(_:))
        return well
    }

    func updateNSView(_ well: NSColorWell, context: Context) {
        if let color = NSColor(hex: hexString), well.color != color {
            well.color = color
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        let parent: SidebarColorWell
        init(_ parent: SidebarColorWell) { self.parent = parent }
        @MainActor @objc func colorChanged(_ sender: NSColorWell) {
            parent.hexString = sender.color.hexString()
        }
    }
}

/// UserDefaults keys backing the sidebar appearance popover.
enum SidebarAppearanceDefaults {
    static let groupNameFontBoostKey = SidebarGroupNameFontBoost.defaultsKey
    static let groupNameFontFamilyKey = "sidebarGroupNameFontFamily"
    static let groupNameColorHexKey = "sidebarGroupNameColorHex"
    static let workspaceNameFontSizeDeltaKey = "sidebarWorkspaceNameFontSizeDelta"
    static let workspaceNameFontFamilyKey = "sidebarWorkspaceNameFontFamily"
    static let workspaceNameColorHexKey = "sidebarWorkspaceNameColorHex"
    static let workspaceTintColorHexKey = "sidebarWorkspaceTintColorHex"
    static let workspaceTintOpacityKey = "sidebarWorkspaceTintOpacity"
    static let tabTitleFontSizeDeltaKey = "sidebarTabTitleFontSizeDelta"
    static let tabTitleColorHexKey = "sidebarTabTitleColorHex"
}

/// Reads and writes the Ghostty terminal theme in ~/.config/ghostty/config,
/// then asks the running app to reload its terminal configuration.
enum SidebarGhosttyTheme {
    /// Reads the `theme = ...` line from the Ghostty config file.
    static func current() -> String {
        let path = ghosttyConfigPath()
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return "TokyoNight Storm"
        }
        for line in contents.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("theme"), let eq = trimmed.firstIndex(of: "=") {
                return trimmed[trimmed.index(after: eq)...].trimmingCharacters(in: .whitespaces)
            }
        }
        return "TokyoNight Storm"
    }

    /// Rewrites the `theme = ...` line (appending when absent) and reloads.
    @MainActor static func set(_ theme: String) {
        let path = ghosttyConfigPath()
        var contents = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        var lines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var replaced = false
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("theme"), !trimmed.hasPrefix("#") {
                lines[index] = "theme = \(theme)"
                replaced = true
            }
        }
        if !replaced {
            lines.append("theme = \(theme)")
        }
        contents = lines.joined(separator: "\n")
        try? FileManager.default.createDirectory(
            atPath: (path as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true
        )
        try? contents.write(toFile: path, atomically: true, encoding: .utf8)
        _ = AppDelegate.shared?.reloadConfiguration(source: "sidebar.appearance.theme")
    }

    private static func ghosttyConfigPath() -> String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/ghostty/config").path
    }
}
