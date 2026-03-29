import Foundation
import ServiceManagement

final class LoginItemManager {
    static let shared = LoginItemManager()
    
    private init() {}
    
    var isLoginItemEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return legacyIsEnabled()
        }
    }
    
    func setLoginItemEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") login item: \(error)")
            }
        } else {
            legacySetEnabled(enabled)
        }
    }
    
    // MARK: - Legacy Support (macOS < 13)
    
    private func legacyIsEnabled() -> Bool {
        let launchAgentPath = launchAgentPlistPath()
        return FileManager.default.fileExists(atPath: launchAgentPath)
    }
    
    private func legacySetEnabled(_ enabled: Bool) {
        let plistPath = launchAgentPlistPath()
        
        if enabled {
            let dict: [String: Any] = [
                "Label": Constants.bundleIdentifier,
                "ProgramArguments": [Bundle.main.executablePath ?? ""],
                "RunAtLoad": true,
                "KeepAlive": false
            ]
            let plistData = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
            
            let dirPath = (plistPath as NSString).deletingLastPathComponent
            try? FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: plistPath, contents: plistData)
        } else {
            try? FileManager.default.removeItem(atPath: plistPath)
        }
    }
    
    private func launchAgentPlistPath() -> String {
        let home = NSHomeDirectory()
        return "\(home)/Library/LaunchAgents/\(Constants.bundleIdentifier).plist"
    }
}
