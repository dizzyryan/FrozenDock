import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var displayManager: DisplayManager
    @ObservedObject var protectionService: DockProtectionService
    @ObservedObject var updateChecker: UpdateChecker
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                startupSection
                interfaceSection
                displaySection
                protectionSection
                updatesSection
                aboutSection
            }
            .padding(20)
        }
    }
    
    // MARK: - Startup & Background
    
    private var startupSection: some View {
        SettingsSection(title: "Startup & Background", icon: "power") {
            Toggle("Start at Login", isOn: $settings.startAtLogin)
                .onChange(of: settings.startAtLogin) { newValue in
                    LoginItemManager.shared.setLoginItemEnabled(newValue)
                }
            
            Toggle("Run in Background", isOn: $settings.runInBackground)
                .help("Keep protection active even when the main window is closed")
            
            Toggle("Auto-start Protection", isOn: $settings.autoStartProtection)
                .help("Automatically start protection when the app launches")
        }
    }
    
    // MARK: - Interface
    
    private var interfaceSection: some View {
        SettingsSection(title: "Interface", icon: "paintbrush") {
            Toggle("Show Menu Bar Icon", isOn: $settings.showMenuBarIcon)
            
            Toggle("Hide from Dock", isOn: $settings.hideFromDock)
                .onChange(of: settings.hideFromDock) { _ in
                    settings.updateDockVisibility()
                }
                .help("Hide the app icon from the macOS Dock (access via menu bar)")
            
            Picker("Theme", selection: $settings.appTheme) {
                ForEach(Constants.AppTheme.allCases, id: \.rawValue) { theme in
                    Text(theme.displayName).tag(theme.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: settings.appTheme) { _ in
                settings.applyTheme()
            }
        }
    }
    
    // MARK: - Display Selection
    
    private var displaySection: some View {
        SettingsSection(title: "Display", icon: "display") {
            // Anchor mode
            Picker("Default Anchor", selection: $settings.defaultAnchorMode) {
                ForEach(Constants.AnchorMode.allCases, id: \.rawValue) { mode in
                    Text(mode.displayName).tag(mode.rawValue)
                }
            }
            .onChange(of: settings.defaultAnchorMode) { _ in
                if let anchor = displayManager.resolveAnchorDisplay(settings: settings) {
                    settings.anchorDisplayCGID = anchor.displayID
                    protectionService.updateAnchorDisplay(anchor.displayID)
                }
            }
            
            // Specific display picker (shown when mode is .specific)
            if settings.anchorMode == .specific {
                Picker("Anchor Display", selection: Binding(
                    get: { settings.anchorDisplayCGID },
                    set: { newID in
                        settings.anchorDisplayCGID = newID
                        protectionService.updateAnchorDisplay(newID)
                    }
                )) {
                    ForEach(displayManager.displays) { display in
                        Text(display.displayLabel).tag(display.displayID)
                    }
                }
            }
            
            // Display info
            if let primary = displayManager.primaryDisplay {
                HStack {
                    Text("Primary Display")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(primary.name)
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
            
            HStack {
                Text("Connected Displays")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(displayManager.displays.count)")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            
            Toggle("Auto-move Dock to Anchor", isOn: $settings.autoMoveDock)
                .help("Automatically move the dock to the anchor display when protection starts")
        }
    }
    
    // MARK: - Protection
    
    private var protectionSection: some View {
        SettingsSection(title: "Protection", icon: "shield") {
            // Accessibility status
            HStack {
                Text("Accessibility")
                Spacer()
                if AccessibilityHelper.shared.isAccessibilityEnabled {
                    Label("Granted", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Button("Grant Access") {
                        AccessibilityHelper.shared.openAccessibilityPreferences()
                    }
                    .controlSize(.small)
                }
            }
            
            if protectionService.blockedEventsCount > 0 {
                HStack {
                    Text("Events Blocked")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(protectionService.blockedEventsCount)")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                .font(.caption)
            }
        }
    }
    
    // MARK: - Updates
    
    private var updatesSection: some View {
        SettingsSection(title: "Updates", icon: "arrow.triangle.2.circlepath") {
            Toggle("Check for Updates Automatically", isOn: $settings.checkForUpdates)
            
            HStack {
                if updateChecker.isChecking {
                    ProgressView()
                        .controlSize(.small)
                    Text("Checking…")
                        .foregroundColor(.secondary)
                } else if updateChecker.updateAvailable, let version = updateChecker.latestVersion {
                    Label("Version \(version) available", systemImage: "arrow.down.circle.fill")
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Button("Download") {
                        updateChecker.openReleasePage()
                    }
                    .controlSize(.small)
                } else {
                    Button("Check for Updates") {
                        updateChecker.checkForUpdates()
                    }
                    .controlSize(.small)
                    
                    if let date = updateChecker.lastCheckDate {
                        Spacer()
                        Text("Last checked: \(date, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - About
    
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle") {
            HStack {
                Text("Version")
                Spacer()
                Text(Constants.appVersion)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("macOS")
                Spacer()
                Text(ProcessInfo.processInfo.operatingSystemVersionString)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Acknowledgements")
                    .font(.caption.weight(.semibold))
                HStack(spacing: 4) {
                    Text("Inspired by")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Link("DockAnchor", destination: URL(string: "https://github.com/bwya77/DockAnchor")!)
                        .font(.caption)
                    Text("by bwya77")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.controlBackgroundColor))
            )
        }
    }
}
