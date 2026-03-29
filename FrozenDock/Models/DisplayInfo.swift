import Foundation
import CoreGraphics
import AppKit

struct DisplayInfo: Identifiable, Equatable, Hashable, Codable {
    let displayID: CGDirectDisplayID
    let name: String
    let width: Int
    let height: Int
    let originX: Int
    let originY: Int
    let isPrimary: Bool
    let isBuiltIn: Bool
    
    var id: CGDirectDisplayID { displayID }
    
    var bounds: CGRect {
        CGRect(x: originX, y: originY, width: width, height: height)
    }
    
    var resolution: String {
        "\(width) × \(height)"
    }
    
    var displayLabel: String {
        var label = name
        if isPrimary { label += " (Primary)" }
        if isBuiltIn { label += " (Built-in)" }
        return label
    }
    
    /// Create DisplayInfo from a CGDirectDisplayID
    static func from(displayID: CGDirectDisplayID) -> DisplayInfo {
        let bounds = CGDisplayBounds(displayID)
        let isPrimary = CGDisplayIsMain(displayID) != 0
        let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0
        let name = Self.getDisplayName(for: displayID)
        
        return DisplayInfo(
            displayID: displayID,
            name: name,
            width: Int(bounds.width),
            height: Int(bounds.height),
            originX: Int(bounds.origin.x),
            originY: Int(bounds.origin.y),
            isPrimary: isPrimary,
            isBuiltIn: isBuiltIn
        )
    }
    
    /// Get a user-friendly display name
    private static func getDisplayName(for displayID: CGDirectDisplayID) -> String {
        // Try NSScreen.localizedName first (macOS 10.15+)
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               screenNumber == displayID {
                return screen.localizedName
            }
        }
        
        // Fallback names
        if CGDisplayIsBuiltin(displayID) != 0 {
            return "Built-in Display"
        }
        if CGDisplayIsMain(displayID) != 0 {
            return "Primary Display"
        }
        return "Display \(displayID)"
    }
    
    // Codable conformance for CGDirectDisplayID (UInt32)
    enum CodingKeys: String, CodingKey {
        case displayID, name, width, height, originX, originY, isPrimary, isBuiltIn
    }
}
