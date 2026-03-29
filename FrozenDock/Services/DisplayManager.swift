import Foundation
import CoreGraphics
import AppKit
import Combine

final class DisplayManager: ObservableObject {
    static let shared = DisplayManager()
    
    @Published var displays: [DisplayInfo] = []
    @Published var primaryDisplay: DisplayInfo?
    @Published var builtInDisplay: DisplayInfo?
    
    private var reconfigurationCallback: CGDisplayReconfigurationCallBack?
    
    init() {
        refreshDisplays()
        registerForDisplayChanges()
    }
    
    deinit {
        CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
    }
    
    /// Refresh the list of connected displays
    func refreshDisplays() {
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)
        
        guard displayCount > 0 else {
            DispatchQueue.main.async {
                self.displays = []
                self.primaryDisplay = nil
                self.builtInDisplay = nil
            }
            return
        }
        
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetActiveDisplayList(displayCount, &displayIDs, &displayCount)
        
        let newDisplays = displayIDs.map { DisplayInfo.from(displayID: $0) }
        
        DispatchQueue.main.async {
            self.displays = newDisplays
            self.primaryDisplay = newDisplays.first(where: { $0.isPrimary })
            self.builtInDisplay = newDisplays.first(where: { $0.isBuiltIn })
        }
    }
    
    /// Get display info by ID
    func display(for id: CGDirectDisplayID) -> DisplayInfo? {
        displays.first(where: { $0.displayID == id })
    }
    
    /// Get the anchor display based on current settings
    func resolveAnchorDisplay(settings: AppSettings) -> DisplayInfo? {
        switch settings.anchorMode {
        case .primary:
            return primaryDisplay
        case .builtIn:
            return builtInDisplay ?? primaryDisplay
        case .specific:
            let specificID = settings.anchorDisplayCGID
            if let specific = display(for: specificID) {
                return specific
            }
            // Fallback to primary if specific display is disconnected
            return primaryDisplay
        }
    }
    
    /// Get all display IDs as an array
    var displayIDs: [CGDirectDisplayID] {
        displays.map { $0.displayID }
    }
    
    /// Generate a signature for the current display configuration
    var displaySignature: String {
        Profile.generateSignature(from: displayIDs)
    }
    
    /// Get the dock position from system preferences
    func getDockPosition() -> Constants.DockPosition {
        if let orientation = UserDefaults(suiteName: "com.apple.dock")?.string(forKey: "orientation") {
            return Constants.DockPosition(rawValue: orientation) ?? .bottom
        }
        return .bottom
    }
    
    /// Calculate the dock trigger zone for a display
    func dockTriggerZone(for display: DisplayInfo) -> CGRect {
        let bounds = display.bounds
        let triggerSize = Constants.dockTriggerSize
        let dockPosition = getDockPosition()
        
        switch dockPosition {
        case .bottom:
            return CGRect(
                x: bounds.origin.x,
                y: bounds.origin.y + bounds.height - triggerSize,
                width: bounds.width,
                height: triggerSize
            )
        case .left:
            return CGRect(
                x: bounds.origin.x,
                y: bounds.origin.y,
                width: triggerSize,
                height: bounds.height
            )
        case .right:
            return CGRect(
                x: bounds.origin.x + bounds.width - triggerSize,
                y: bounds.origin.y,
                width: triggerSize,
                height: bounds.height
            )
        }
    }
    
    // MARK: - Display Change Monitoring
    
    private func registerForDisplayChanges() {
        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
    }
}

private func displayReconfigurationCallback(
    displayID: CGDirectDisplayID,
    flags: CGDisplayChangeSummaryFlags,
    userInfo: UnsafeMutableRawPointer?
) {
    guard let userInfo = userInfo else { return }
    let manager = Unmanaged<DisplayManager>.fromOpaque(userInfo).takeUnretainedValue()
    
    // Only refresh after the reconfiguration is complete
    if flags.contains(.beginConfigurationFlag) { return }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        manager.refreshDisplays()
        NotificationCenter.default.post(name: .displaysChanged, object: nil)
    }
}

extension Notification.Name {
    static let displaysChanged = Notification.Name("com.frozendock.displaysChanged")
    static let protectionStatusChanged = Notification.Name("com.frozendock.protectionStatusChanged")
}
