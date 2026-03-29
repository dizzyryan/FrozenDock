import SwiftUI

@main
struct FrozenDockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 780, height: 560)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About FrozenDock") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationName: Constants.appName,
                        .applicationVersion: Constants.appVersion
                    ])
                }
            }
            
            CommandMenu("Protection") {
                Button(DockProtectionService.shared.isProtecting ? "Stop Protection" : "Start Protection") {
                    DockProtectionService.shared.toggleProtection()
                    AppSettings.shared.protectionEnabled = DockProtectionService.shared.isProtecting
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Move Dock to Anchor") {
                    let settings = AppSettings.shared
                    if let anchor = DisplayManager.shared.display(for: settings.anchorDisplayCGID) {
                        DockController.shared.moveDockToDisplay(anchor)
                    }
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                
                Button("Refresh Displays") {
                    DisplayManager.shared.refreshDisplays()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}
