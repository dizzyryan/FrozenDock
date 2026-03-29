import Foundation
import CoreGraphics
import AppKit
import Combine

final class DockProtectionService: ObservableObject {
    static let shared = DockProtectionService()
    
    @Published var isProtecting: Bool = false
    @Published var blockedEventsCount: Int = 0
    @Published var lastBlockedDate: Date?
    @Published var statusMessage: String = "Protection inactive"
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var anchorDisplayID: CGDirectDisplayID = CGMainDisplayID()
    
    private let displayManager = DisplayManager.shared
    
    private init() {}
    
    // MARK: - Public API
    
    /// Start dock protection
    func startProtection(anchorDisplay: CGDirectDisplayID? = nil) {
        guard !isProtecting else { return }
        
        // Check accessibility
        guard AccessibilityHelper.shared.isAccessibilityEnabled else {
            AccessibilityHelper.shared.requestAccessibility()
            statusMessage = "Accessibility permission required"
            return
        }
        
        // Set anchor display
        if let anchor = anchorDisplay {
            self.anchorDisplayID = anchor
        } else {
            resolveAnchorDisplay()
        }
        
        // Create event tap
        let eventMask: CGEventMask = (1 << CGEventType.mouseMoved.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)
            | (1 << CGEventType.rightMouseDragged.rawValue)
            | (1 << CGEventType.otherMouseDragged.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: dockProtectionCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            statusMessage = "Failed to create event tap. Check accessibility permissions."
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        
        CGEvent.tapEnable(tap: tap, enable: true)
        isProtecting = true
        statusMessage = "Protection active"
        
        // Auto-move dock to anchor display if enabled
        if AppSettings.shared.autoMoveDock {
            if let display = displayManager.display(for: anchorDisplayID) {
                DispatchQueue.global(qos: .userInitiated).async {
                    DockController.shared.moveDockToDisplay(display)
                }
            }
        }
        
        NotificationCenter.default.post(name: .protectionStatusChanged, object: nil)
    }
    
    /// Stop dock protection
    func stopProtection() {
        guard isProtecting else { return }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        isProtecting = false
        statusMessage = "Protection inactive"
        
        NotificationCenter.default.post(name: .protectionStatusChanged, object: nil)
    }
    
    /// Toggle protection on/off
    func toggleProtection() {
        if isProtecting {
            stopProtection()
        } else {
            startProtection()
        }
    }
    
    /// Update the anchor display
    func updateAnchorDisplay(_ displayID: CGDirectDisplayID) {
        anchorDisplayID = displayID
        if isProtecting {
            // Move dock to new anchor if protection is active
            if AppSettings.shared.autoMoveDock {
                if let display = displayManager.display(for: displayID) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        DockController.shared.moveDockToDisplay(display)
                    }
                }
            }
        }
    }
    
    // MARK: - Private
    
    /// Resolve which display should be the anchor based on settings
    private func resolveAnchorDisplay() {
        let settings = AppSettings.shared
        if let resolved = displayManager.resolveAnchorDisplay(settings: settings) {
            anchorDisplayID = resolved.displayID
        } else {
            anchorDisplayID = CGMainDisplayID()
        }
    }
    
    /// Called from the event tap callback to process mouse events
    fileprivate func processMouseEvent(_ event: CGEvent) -> CGEvent? {
        let mouseLocation = event.location
        
        // Check if mouse is in a dock trigger zone on a non-anchor display
        for display in displayManager.displays {
            // Skip the anchor display — dock is allowed there
            if display.displayID == anchorDisplayID { continue }
            
            let triggerZone = displayManager.dockTriggerZone(for: display)
            
            if triggerZone.contains(mouseLocation) {
                // Mouse is in dock trigger zone on a non-anchor display
                // Clamp the position to just outside the trigger zone
                let dockPosition = displayManager.getDockPosition()
                var newLocation = mouseLocation
                
                switch dockPosition {
                case .bottom:
                    newLocation.y = display.bounds.origin.y + display.bounds.height - Constants.dockTriggerSize - 1
                case .left:
                    newLocation.x = display.bounds.origin.x + Constants.dockTriggerSize + 1
                case .right:
                    newLocation.x = display.bounds.origin.x + display.bounds.width - Constants.dockTriggerSize - 1
                }
                
                event.location = newLocation
                
                DispatchQueue.main.async { [weak self] in
                    self?.blockedEventsCount += 1
                    self?.lastBlockedDate = Date()
                }
                
                return event
            }
        }
        
        return event
    }
    
    /// Re-enable the tap if it was disabled
    fileprivate func reEnableTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
}

// MARK: - Event Tap Callback (C function)

private func dockProtectionCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passRetained(event)
    }
    
    let service = Unmanaged<DockProtectionService>.fromOpaque(refcon).takeUnretainedValue()
    
    // Handle tap being disabled by timeout or user input
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        service.reEnableTap()
        return Unmanaged.passRetained(event)
    }
    
    // Process the mouse event
    if let processedEvent = service.processMouseEvent(event) {
        return Unmanaged.passRetained(processedEvent)
    }
    
    return Unmanaged.passRetained(event)
}
