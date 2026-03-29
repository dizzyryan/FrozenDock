import Foundation

enum Constants {
    static let appName = "FrozenDock"
    static let bundleIdentifier = "com.frozendock.app"
    
    // Dock trigger zone size in points
    static let dockTriggerSize: CGFloat = 5.0
    
    // How long to wait for dock to move (ms)
    static let dockMoveDelay: UInt32 = 300_000
    
    // UserDefaults keys
    enum Keys {
        static let anchorDisplayID = "anchorDisplayID"
        static let startAtLogin = "startAtLogin"
        static let runInBackground = "runInBackground"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let hideFromDock = "hideFromDock"
        static let appTheme = "appTheme"
        static let autoStartProtection = "autoStartProtection"
        static let autoMoveDock = "autoMoveDock"
        static let defaultAnchorMode = "defaultAnchorMode"
        static let activeProfileID = "activeProfileID"
        static let autoSwitchProfiles = "autoSwitchProfiles"
        static let protectionEnabled = "protectionEnabled"
        static let profiles = "profiles"
        static let checkForUpdates = "checkForUpdates"
    }
    
    enum AnchorMode: String, CaseIterable {
        case primary = "primary"
        case builtIn = "builtIn"
        case specific = "specific"
        
        var displayName: String {
            switch self {
            case .primary: return "Primary Display"
            case .builtIn: return "Built-in Display"
            case .specific: return "Specific Display"
            }
        }
    }
    
    enum AppTheme: String, CaseIterable {
        case system = "system"
        case light = "light"
        case dark = "dark"
        
        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }
    
    enum DockPosition: String {
        case bottom, left, right
    }
    
    // GitHub release URL for update checking
    static let githubReleasesURL = "https://api.github.com/repos/frozendock/frozendock/releases/latest"
    static let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()
}
