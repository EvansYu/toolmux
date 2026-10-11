import CmuxFoundation
import CmuxSettings
import CmuxSidebar
import CoreGraphics
import Foundation

/// Immutable settings projection consumed by both SwiftUI and AppKit sidebar rows.
struct SidebarTabItemSettingsSnapshot: Equatable {
    let hidesAllDetails: Bool
    let wrapsWorkspaceTitles: Bool
    /// `sidebar.compactAgentStatus`: agent status entries draw on the title line.
    let compactsAgentStatus: Bool
    /// `sidebar.compactStatusIcons`, keeping only known states and non-empty names.
    let compactStatusIcons: [String: String]
    let showsWorkspaceDescription: Bool
    let workspaceDescriptionColorHex: String?
    let sidebarShortcutHintXOffset: Double
    let sidebarShortcutHintYOffset: Double
    let alwaysShowShortcutHints: Bool
    let sidebarFontScale: CGFloat
    /// Extra points on the group-header name over the scaled base, so group
    /// names read one step larger than normal workspace rows by default.
    /// Persisted as `sidebarGroupNameFontBoost`; adjustable from the group
    /// header context menu.
    let groupNameFontBoost: CGFloat
    let showsGitBranch: Bool
    let branchDirectory: SidebarWorkspaceBranchDirectorySettings
    let details: SidebarWorkspaceDetailSettings
    let showsGitBranchIcon: Bool
    let makesPullRequestsClickable: Bool
    let openPullRequestLinksInCmuxBrowser: Bool
    let openPortLinksInCmuxBrowser: Bool
    let showsNotificationMessage: Bool
    let notificationMessageLineLimit: Int
    let activeTabIndicatorStyle: WorkspaceIndicatorStyle
    let loadingSpinnerPosition: SidebarIndicatorPosition
    let notificationBadgePosition: SidebarIndicatorPosition
    let selectionColorHex: String?
    let subtleSelection: Bool
    let brightenInDarkMode: Bool
    let notificationBadgeColorHex: String?
    let visibleAuxiliaryDetails: SidebarWorkspaceAuxiliaryDetailVisibility
    let iMessageModeEnabled: Bool
    let workspaceTodoChecklistStyle: WorkspaceTodoChecklistStyle
    /// The resolved cmux accent. Rows draw selection, progress, drop
    /// indicators and agent status with it, and reconfigure when it changes.
    let accentColor: CmuxAccentColor

    var usesLastSegmentPath: Bool { branchDirectory.usesLastSegmentPath }
    var showsSSH: Bool { details.showSSH }

    init(
        defaults: UserDefaults = .standard,
        sidebarFontSize: CGFloat = GhosttyConfig.defaultSidebarFontSize,
        accentColor: CmuxAccentColor = CmuxAccentColor()
    ) {
        let settings = UserDefaultsSettingsClient(defaults: defaults)
        let sidebar = SidebarCatalogSection()
        let workspaceColors = WorkspaceColorsCatalogSection()
        let betaFeatures = BetaFeaturesCatalogSection()
        branchDirectory = SidebarWorkspaceBranchDirectorySettings(defaults: defaults)
        details = SidebarWorkspaceDetailSettings(defaults: defaults)

        sidebarShortcutHintXOffset = ShortcutHintDebugSettings.defaultSidebarHintX
        sidebarShortcutHintYOffset = ShortcutHintDebugSettings.defaultSidebarHintY
        alwaysShowShortcutHints = ShortcutHintDebugSettings(defaults: defaults).alwaysShowHints
        sidebarFontScale = SidebarTabItemFontScale.scale(for: sidebarFontSize)
        showsGitBranch = Self.bool(defaults: defaults, key: "sidebarShowGitBranch", defaultValue: true)
        showsGitBranchIcon = Self.bool(defaults: defaults, key: "sidebarShowGitBranchIcon", defaultValue: false)
        makesPullRequestsClickable = settings.value(for: sidebar.makePullRequestsClickable)
        openPullRequestLinksInCmuxBrowser = BrowserLinkOpenSettings.openSidebarPullRequestLinksInCmuxBrowser(
            defaults: defaults
        )
        openPortLinksInCmuxBrowser = BrowserLinkOpenSettings.openSidebarPortLinksInCmuxBrowser(
            defaults: defaults
        )
        hidesAllDetails = settings.value(for: sidebar.hideAllDetails)
        wrapsWorkspaceTitles = settings.value(for: sidebar.wrapWorkspaceTitles)
        compactsAgentStatus = settings.value(for: sidebar.compactAgentStatus)
        compactStatusIcons = SidebarCompactStatusGlyph.validIconOverrides(settings.value(for: sidebar.compactStatusIcons))
        let detailVisibility = SidebarWorkspaceDetailVisibility(
            showWorkspaceDescription: settings.value(for: sidebar.showWorkspaceDescription),
            showNotificationMessage: settings.value(for: sidebar.showNotificationMessage),
            hideAllDetails: hidesAllDetails
        )
        showsWorkspaceDescription = detailVisibility.showsWorkspaceDescription
        workspaceDescriptionColorHex = settings.value(for: sidebar.workspaceDescriptionColorHex).nilIfEmpty
        showsNotificationMessage = detailVisibility.showsNotificationMessage
        notificationMessageLineLimit = min(
            max(
                settings.value(for: sidebar.notificationMessageLineLimit),
                SidebarCatalogSection.notificationMessageLineLimitRange.lowerBound
            ),
            SidebarCatalogSection.notificationMessageLineLimitRange.upperBound
        )
        visibleAuxiliaryDetails = SidebarWorkspaceAuxiliaryDetailVisibility.resolved(
            showMetadata: details.showCustomMetadata,
            showLog: details.showLog,
            showProgress: details.showProgress,
            showAgentUsage: details.showAgentUsage,
            showBranchDirectory: details.showBranchDirectory,
            showPullRequests: details.showPullRequests,
            showPorts: details.showPorts,
            hideAllDetails: hidesAllDetails
        )

        activeTabIndicatorStyle = settings.value(for: workspaceColors.indicatorStyle)
        loadingSpinnerPosition = settings.value(for: sidebar.loadingSpinnerPosition)
        notificationBadgePosition = settings.value(for: sidebar.notificationBadgePosition)
        selectionColorHex = settings.value(for: workspaceColors.selectionColorHex).nilIfEmpty
        subtleSelection = settings.value(for: workspaceColors.subtleSelection)
        brightenInDarkMode = settings.value(for: workspaceColors.brightenInDarkMode)
        notificationBadgeColorHex = settings.value(for: workspaceColors.notificationBadgeColorHex).nilIfEmpty
        iMessageModeEnabled = IMessageModeSettings.isEnabled(defaults: defaults)
        workspaceTodoChecklistStyle = settings.value(for: betaFeatures.workspaceTodosChecklistStyle)
        groupNameFontBoost = SidebarGroupNameFontBoost.current(defaults: defaults)
        self.accentColor = accentColor
    }

    private static func bool(
        defaults: UserDefaults,
        key: String,
        defaultValue: Bool
    ) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }
}

/// User-adjustable extra point size for workspace-group header names.
///
/// Group names render one step larger than normal workspace rows by default
/// (``defaultBoost``) so the grouping level stays visually distinct. The group
/// header context menu nudges the value by ``step`` within ``allowedRange``;
/// the snapshot above re-reads it on every UserDefaults change, so menu
/// adjustments apply live.
enum SidebarGroupNameFontBoost {
    /// UserDefaults key holding the boost in points (Double).
    static let defaultsKey = "sidebarGroupNameFontBoost"
    /// Default boost: group names render 2pt above the scaled base size.
    static let defaultBoost: CGFloat = 1
    /// Step applied by the context-menu larger/smaller actions.
    static let step: CGFloat = 0.5
    /// Allowed boost range: from the plain row size up to +8pt.
    static let allowedRange: ClosedRange<CGFloat> = 0...8

    /// Reads the persisted boost, falling back to ``defaultBoost``.
    static func current(defaults: UserDefaults = .standard) -> CGFloat {
        guard let stored = defaults.object(forKey: defaultsKey) as? Double,
              stored.isFinite else {
            return defaultBoost
        }
        return min(max(CGFloat(stored), allowedRange.lowerBound), allowedRange.upperBound)
    }

    /// Writes a clamped boost so the settings snapshot re-reads it.
    static func set(_ value: CGFloat, defaults: UserDefaults = .standard) {
        let clamped = min(max(value, allowedRange.lowerBound), allowedRange.upperBound)
        defaults.set(Double(clamped), forKey: defaultsKey)
    }

    /// Removes the persisted override, restoring ``defaultBoost``.
    static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: defaultsKey)
    }
}
