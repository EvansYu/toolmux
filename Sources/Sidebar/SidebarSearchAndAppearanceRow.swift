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
            Button {
                showsAppearanceSettings.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 22)
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
        .padding(.horizontal, 3)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }
}

/// Appearance settings popover content: per-section controls for group names,
/// workspace names, workspace background, terminal theme, and tab titles.
/// Every control persists to UserDefaults; rows pick changes up through the
/// existing settings snapshot rebuild (and tabs through @AppStorage).
struct SidebarAppearanceSettingsView: View {
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
        ("Maple Mono NF CN", "Maple Mono NF CN"),
        ("Menlo", "Menlo"),
        ("SF Mono", "SF Mono"),
        ("PingFang SC", "PingFang SC"),
        ("Helvetica Neue", "Helvetica Neue"),
    ]

    private static let themeChoices: [String] = [
        "TokyoNight Storm", "TokyoNight Night", "Catppuccin Mocha",
        "GitHub Dark Default", "GitHub Dark", "Atom One Dark", "Dracula",
        "Catppuccin Frappe", "TokyoNight Moon", "Desert",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("外观设置")
                .font(.headline)

            fontSection(
                title: "分组名称",
                sizeValue: $groupNameBoost,
                sizeRange: 0...8,
                sizeLabel: { v in "字号 +\(String(format: "%.1f", v))pt" },
                family: $groupNameFontFamily,
                colorHex: $groupNameColorHex
            )

            fontSection(
                title: "工作区名称",
                sizeValue: $workspaceNameSizeDelta,
                sizeRange: -2...4,
                sizeLabel: { v in "字号 \(v >= 0 ? "+" : "")\(String(format: "%.1f", v))pt" },
                family: $workspaceNameFontFamily,
                colorHex: $workspaceNameColorHex
            )

            GroupBox("工作区背景") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("颜色")
                        Spacer()
                        SidebarColorWell(hexString: $workspaceTintColorHex)
                        if !workspaceTintColorHex.isEmpty {
                            Button("清除") { workspaceTintColorHex = "" }
                                .font(.caption)
                        }
                    }
                    HStack {
                        Text("浓度")
                        Slider(value: $workspaceTintOpacity, in: 0...0.2, step: 0.01)
                        Text(String(format: "%.0f%%", workspaceTintOpacity * 100))
                            .font(.caption).monospacedDigit()
                            .frame(width: 34, alignment: .trailing)
                    }
                }
            }

            GroupBox("终端主题") {
                Picker("主题", selection: $ghosttyTheme) {
                    ForEach(Self.themeChoices, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .onChange(of: ghosttyTheme) { newTheme in
                    SidebarGhosttyTheme.set(newTheme)
                }
            }

            GroupBox("页签名称（右侧）") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("字号")
                        Slider(value: $tabTitleSizeDelta, in: -2...4, step: 0.5)
                        Text(String(format: "%+.1f", tabTitleSizeDelta))
                            .font(.caption).monospacedDigit()
                            .frame(width: 34, alignment: .trailing)
                    }
                    HStack {
                        Text("颜色")
                        Spacer()
                        SidebarColorWell(hexString: $tabTitleColorHex)
                        if !tabTitleColorHex.isEmpty {
                            Button("清除") { tabTitleColorHex = "" }
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 300)
    }

    @ViewBuilder
    private func fontSection(
        title: String,
        sizeValue: Binding<Double>,
        sizeRange: ClosedRange<Double>,
        sizeLabel: @escaping (Double) -> String,
        family: Binding<String>,
        colorHex: Binding<String>
    ) -> some View {
        GroupBox(title) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("字号")
                    Slider(value: sizeValue, in: sizeRange, step: 0.5)
                    Text(sizeLabel(sizeValue.wrappedValue))
                        .font(.caption).monospacedDigit()
                        .frame(width: 58, alignment: .trailing)
                }
                HStack {
                    Text("字体")
                    Spacer()
                    Picker("字体", selection: family) {
                        ForEach(Self.fontChoices, id: \.name) { choice in
                            Text(choice.label).tag(choice.name)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 170)
                }
                HStack {
                    Text("颜色")
                    Spacer()
                    SidebarColorWell(hexString: colorHex)
                    if !colorHex.wrappedValue.isEmpty {
                        Button("清除") { colorHex.wrappedValue = "" }
                            .font(.caption)
                    }
                }
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
