import SwiftUI

struct ContentView: View {
    @ObservedObject var protectionService = DockProtectionService.shared
    @ObservedObject var displayManager = DisplayManager.shared
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var updateChecker = UpdateChecker.shared
    
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case profiles = "Profiles"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .dashboard: return "shield.fill"
            case .profiles: return "person.2.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
                .frame(minWidth: 480)
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            settings.applyTheme()
            if settings.autoStartProtection && !protectionService.isProtecting {
                protectionService.startProtection()
            }
            if settings.checkForUpdates {
                updateChecker.checkForUpdates()
            }
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        VStack(spacing: 0) {
            // App header
            VStack(spacing: 8) {
                Image(systemName: "snowflake")
                    .font(.system(size: 36))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("FrozenDock")
                    .font(.title3.weight(.bold))
                
                StatusBadgeView(isActive: protectionService.isProtecting, size: 8)
            }
            .padding(.vertical, 20)
            
            Divider()
                .padding(.horizontal)
            
            // Navigation
            List(Tab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            
            Spacer()
            
            // Quick toggle
            VStack(spacing: 10) {
                Button {
                    protectionService.toggleProtection()
                    settings.protectionEnabled = protectionService.isProtecting
                } label: {
                    HStack {
                        Image(systemName: protectionService.isProtecting ? "shield.slash.fill" : "shield.fill")
                        Text(protectionService.isProtecting ? "Stop Protection" : "Start Protection")
                    }
                    .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(protectionService.isProtecting ? .red : .green)
            }
            .padding()
        }
        .frame(minWidth: 200)
    }
    
    // MARK: - Detail View
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .dashboard:
            dashboardView
        case .profiles:
            ProfilesView(
                profileManager: profileManager,
                displayManager: displayManager,
                settings: settings
            )
            .padding(20)
        case .settings:
            SettingsView(
                settings: settings,
                displayManager: displayManager,
                protectionService: protectionService,
                updateChecker: updateChecker
            )
        }
    }
    
    // MARK: - Dashboard
    
    private var dashboardView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Protection status
                ProtectionStatusView(protectionService: protectionService)
                
                // Display map
                VStack(alignment: .leading, spacing: 10) {
                    Label("Displays", systemImage: "display.2")
                        .font(.headline)
                    
                    DisplayMapView(
                        displayManager: displayManager,
                        anchorDisplayID: settings.anchorDisplayCGID,
                        onSelectDisplay: { display in
                            settings.anchorDisplayCGID = display.displayID
                            settings.defaultAnchorMode = Constants.AnchorMode.specific.rawValue
                            protectionService.updateAnchorDisplay(display.displayID)
                        }
                    )
                    .frame(height: 200)
                    
                    Text("Click a display to set it as the dock anchor.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Anchor display info
                anchorInfoSection
                
                // Accessibility warning
                if !AccessibilityHelper.shared.isAccessibilityEnabled {
                    accessibilityWarning
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Anchor Info
    
    private var anchorInfoSection: some View {
        SettingsSection(title: "Anchor Display", icon: "lock.display") {
            if let anchor = displayManager.display(for: settings.anchorDisplayCGID) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(anchor.name)
                            .font(.subheadline.weight(.medium))
                        Text(anchor.resolution)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if anchor.isPrimary {
                            Text("Primary")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.blue)
                        }
                        if anchor.isBuiltIn {
                            Text("Built-in")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.purple)
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Anchor display not found. Using primary display as fallback.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Accessibility Warning
    
    private var accessibilityWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Accessibility Permission Required")
                    .font(.subheadline.weight(.semibold))
                Text("FrozenDock needs accessibility access to monitor mouse events and prevent dock movement.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Grant Access") {
                AccessibilityHelper.shared.openAccessibilityPreferences()
            }
            .controlSize(.small)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}
