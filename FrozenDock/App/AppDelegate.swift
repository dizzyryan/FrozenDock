import Cocoa
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    
    private let settings = AppSettings.shared
    private let protectionService = DockProtectionService.shared
    private let displayManager = DisplayManager.shared
    private let profileManager = ProfileManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply settings
        settings.applyTheme()
        settings.updateDockVisibility()
        
        // Setup menu bar icon
        if settings.showMenuBarIcon {
            setupMenuBarIcon()
        }
        
        // Observe settings changes
        setupObservers()
        
        // Auto-start protection if enabled
        if settings.autoStartProtection {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.protectionService.startProtection()
            }
        }
        
        // Check for updates
        if settings.checkForUpdates {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                UpdateChecker.shared.checkForUpdates()
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return !settings.runInBackground
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Re-open window when clicking dock icon
            for window in NSApp.windows {
                if window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
        }
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        protectionService.stopProtection()
    }
    
    // MARK: - Menu Bar Icon
    
    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            updateMenuBarIcon()
            button.action = #selector(statusBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        updateStatusMenu()
    }
    
    private func removeMenuBarIcon() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }
    
    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }
        
        let iconName = protectionService.isProtecting ? "snowflake" : "snowflake"
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "FrozenDock")?
            .withSymbolConfiguration(config)
        
        button.image = image
        button.contentTintColor = protectionService.isProtecting ? .systemGreen : .secondaryLabelColor
    }
    
    @objc private func statusBarButtonClicked() {
        updateStatusMenu()
        statusItem?.menu = createStatusMenu()
        statusItem?.button?.performClick(nil)
        // Clear menu after display so future clicks re-trigger action
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.menu = nil
        }
    }
    
    private func updateStatusMenu() {
        statusItem?.menu = createStatusMenu()
    }
    
    private func createStatusMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        // Status header
        let statusTitle = protectionService.isProtecting ? "✓ Protection Active" : "✗ Protection Inactive"
        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        if protectionService.isProtecting {
            statusItem.image = NSImage(systemSymbolName: "shield.checkered", accessibilityDescription: nil)
            statusItem.image?.isTemplate = true
        }
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Toggle protection
        let toggleTitle = protectionService.isProtecting ? "Stop Protection" : "Start Protection"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleProtection), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.image = NSImage(systemSymbolName: protectionService.isProtecting ? "stop.circle" : "play.circle", accessibilityDescription: nil)
        toggleItem.image?.isTemplate = true
        menu.addItem(toggleItem)
        
        // Move dock to anchor
        let moveItem = NSMenuItem(title: "Move Dock to Anchor", action: #selector(moveDockToAnchor), keyEquivalent: "")
        moveItem.target = self
        moveItem.isEnabled = displayManager.displays.count >= 2
        moveItem.image = NSImage(systemSymbolName: "dock.arrow.down.rectangle", accessibilityDescription: nil)
        moveItem.image?.isTemplate = true
        menu.addItem(moveItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Anchor display submenu
        let anchorMenu = NSMenu()
        for display in displayManager.displays {
            let item = NSMenuItem(title: display.displayLabel, action: #selector(selectAnchorDisplay(_:)), keyEquivalent: "")
            item.target = self
            item.tag = Int(display.displayID)
            if display.displayID == settings.anchorDisplayCGID {
                item.state = .on
            }
            anchorMenu.addItem(item)
        }
        let anchorItem = NSMenuItem(title: "Anchor Display", action: nil, keyEquivalent: "")
        anchorItem.submenu = anchorMenu
        anchorItem.image = NSImage(systemSymbolName: "lock.display", accessibilityDescription: nil)
        anchorItem.image?.isTemplate = true
        menu.addItem(anchorItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Show window
        let showItem = NSMenuItem(title: "Show FrozenDock", action: #selector(showMainWindow), keyEquivalent: "")
        showItem.target = self
        showItem.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
        showItem.image?.isTemplate = true
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit FrozenDock", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc private func toggleProtection() {
        protectionService.toggleProtection()
        settings.protectionEnabled = protectionService.isProtecting
        updateMenuBarIcon()
    }
    
    @objc private func moveDockToAnchor() {
        if let anchor = displayManager.display(for: settings.anchorDisplayCGID) {
            DispatchQueue.global(qos: .userInitiated).async {
                DockController.shared.moveDockToDisplay(anchor)
            }
        }
    }
    
    @objc private func selectAnchorDisplay(_ sender: NSMenuItem) {
        let displayID = CGDirectDisplayID(sender.tag)
        settings.anchorDisplayCGID = displayID
        settings.defaultAnchorMode = Constants.AnchorMode.specific.rawValue
        protectionService.updateAnchorDisplay(displayID)
    }
    
    @objc private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        // If no window found, open a new one
        if let url = URL(string: "frozendock://main") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        // Watch for protection status changes
        NotificationCenter.default.publisher(for: .protectionStatusChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
            }
            .store(in: &cancellables)
        
        // Watch for UserDefaults changes (includes menu bar icon toggle)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let show = self.settings.showMenuBarIcon
                if show && self.statusItem == nil {
                    self.setupMenuBarIcon()
                } else if !show && self.statusItem != nil {
                    self.removeMenuBarIcon()
                }
            }
            .store(in: &cancellables)
    }
}
