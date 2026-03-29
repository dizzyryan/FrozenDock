import Cocoa
import ApplicationServices

final class AccessibilityHelper {
    
    static let shared = AccessibilityHelper()
    
    private init() {}
    
    /// Check if the app has accessibility permissions
    var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }
    
    /// Prompt the user to grant accessibility permissions
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    /// Check and request accessibility permissions if not granted
    /// Returns true if already granted
    @discardableResult
    func ensureAccessibility() -> Bool {
        if isAccessibilityEnabled {
            return true
        }
        requestAccessibility()
        return false
    }
    
    /// Open System Preferences to the Accessibility pane
    func openAccessibilityPreferences() {
        let url: URL
        if #available(macOS 13.0, *) {
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        } else {
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        }
        NSWorkspace.shared.open(url)
    }
}
