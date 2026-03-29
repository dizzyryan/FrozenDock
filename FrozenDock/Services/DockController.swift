import Foundation
import CoreGraphics
import AppKit

final class DockController {
    static let shared = DockController()
    
    private init() {}
    
    /// Move the dock to the specified display by briefly warping the cursor to its bottom edge
    func moveDockToDisplay(_ display: DisplayInfo) {
        let bounds = display.bounds
        let dockPosition = DisplayManager.shared.getDockPosition()
        
        // Save current mouse position
        let currentPos = NSEvent.mouseLocation
        
        // Calculate target position based on dock position
        let targetPoint: CGPoint
        switch dockPosition {
        case .bottom:
            // Center bottom of the target display
            // CGEvent uses top-left origin, Y-down coordinate system
            targetPoint = CGPoint(
                x: bounds.origin.x + bounds.width / 2,
                y: bounds.origin.y + bounds.height - 1
            )
        case .left:
            targetPoint = CGPoint(
                x: bounds.origin.x + 1,
                y: bounds.origin.y + bounds.height / 2
            )
        case .right:
            targetPoint = CGPoint(
                x: bounds.origin.x + bounds.width - 1,
                y: bounds.origin.y + bounds.height / 2
            )
        }
        
        // Warp cursor to trigger dock on target display
        CGWarpMouseCursorPosition(targetPoint)
        
        // Brief pause to let the dock register
        usleep(Constants.dockMoveDelay)
        
        // Convert saved NSEvent coordinate (bottom-left origin) to CG coordinate (top-left origin)
        if let primaryScreen = NSScreen.screens.first {
            let primaryHeight = primaryScreen.frame.height
            let cgY = primaryHeight - currentPos.y
            CGWarpMouseCursorPosition(CGPoint(x: currentPos.x, y: cgY))
        }
    }
    
    /// Force the dock to restart (last resort)
    func restartDock() {
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["Dock"]
        try? task.run()
    }
    
    /// Get whether the dock is set to auto-hide
    var isDockAutoHide: Bool {
        UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") ?? false
    }
}
