import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage(Constants.Keys.anchorDisplayID) var anchorDisplayID: Int = 0
    @AppStorage(Constants.Keys.startAtLogin) var startAtLogin: Bool = false
    @AppStorage(Constants.Keys.runInBackground) var runInBackground: Bool = true
    @AppStorage(Constants.Keys.showMenuBarIcon) var showMenuBarIcon: Bool = true
    @AppStorage(Constants.Keys.hideFromDock) var hideFromDock: Bool = false
    @AppStorage(Constants.Keys.appTheme) var appTheme: String = Constants.AppTheme.system.rawValue
    @AppStorage(Constants.Keys.autoStartProtection) var autoStartProtection: Bool = false
    @AppStorage(Constants.Keys.autoMoveDock) var autoMoveDock: Bool = true
    @AppStorage(Constants.Keys.defaultAnchorMode) var defaultAnchorMode: String = Constants.AnchorMode.primary.rawValue
    @AppStorage(Constants.Keys.activeProfileID) var activeProfileID: String = ""
    @AppStorage(Constants.Keys.autoSwitchProfiles) var autoSwitchProfiles: Bool = false
    @AppStorage(Constants.Keys.protectionEnabled) var protectionEnabled: Bool = false
    @AppStorage(Constants.Keys.checkForUpdates) var checkForUpdates: Bool = true
    
    var anchorMode: Constants.AnchorMode {
        get { Constants.AnchorMode(rawValue: defaultAnchorMode) ?? .primary }
        set { defaultAnchorMode = newValue.rawValue }
    }
    
    var theme: Constants.AppTheme {
        get { Constants.AppTheme(rawValue: appTheme) ?? .system }
        set { appTheme = newValue.rawValue }
    }
    
    var anchorDisplayCGID: CGDirectDisplayID {
        get { CGDirectDisplayID(anchorDisplayID) }
        set { anchorDisplayID = Int(newValue) }
    }
    
    func applyTheme() {
        switch theme {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
    
    func updateDockVisibility() {
        if hideFromDock {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }
    }
}
