# FrozenDock

> Prevent your macOS Dock from jumping between displays.

On macOS with multiple monitors, the Dock automatically moves to whichever display your cursor hits at the bottom edge. FrozenDock stops that by intercepting the mouse event before it reaches the Dock — no killing, no restarting, no flicker.

## Features

| Feature | Description |
|---|---|
| **Dock Anchoring** | Lock the Dock to a specific display |
| **Event Interception** | Blocks dock trigger events on non-anchor displays at the system level |
| **Virtual Display Map** | Visual layout of your monitors, click to set anchor |
| **Profiles** | Save per-setup configurations; auto-switch when displays change |
| **Menu Bar** | Dropdown menu with status, toggle, anchor selection, and more |
| **Auto-Move Dock** | Moves the Dock to the anchor display when protection starts |
| **Start at Login** | Optional launch on login via `SMAppService` |
| **Background Mode** | Keeps protection running when the window is closed |
| **Themes** | System, light, and dark appearance |
| **Update Checker** | Checks GitHub releases for new versions |

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permissions (required)
- Multiple displays

## Download

Grab the latest release from the [**Releases**](../../releases/latest) page:

1. Download **FrozenDock.dmg**
2. Open it and drag **FrozenDock** into your **Applications** folder
3. Launch FrozenDock
4. Grant **Accessibility** permissions when prompted
5. Click **Start Protection**

> **First launch:** macOS may warn that the app is from an unidentified developer.  
> Right-click the app → **Open** → **Open** to bypass Gatekeeper.

### Granting Accessibility

**System Settings → Privacy & Security → Accessibility** → enable FrozenDock.

Without this, FrozenDock cannot create the event tap needed to intercept mouse events.

## Build from Source

```bash
git clone https://github.com/your-username/FrozenDock.git
cd FrozenDock

# Option A: Open in Xcode
open FrozenDock.xcodeproj
# Select signing team → Build & Run (⌘R)

# Option B: Build release from command line
./scripts/build_release.sh
# Output: build/FrozenDock.dmg + build/FrozenDock.zip
```

## Usage

- **Start/Stop** — Sidebar button or ⇧⌘P
- **Set Anchor** — Click a display in the dashboard map, or use Settings → Display
- **Move Dock** — ⇧⌘M forces the Dock back to the anchor
- **Menu Bar** — Click the snowflake icon for a dropdown with status, toggle, anchor picker, and quit

### Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| Toggle Protection | ⇧⌘P |
| Move Dock to Anchor | ⇧⌘M |
| Refresh Displays | ⇧⌘R |

## How It Works

1. A `CGEventTap` intercepts mouse-move events system-wide
2. For each non-anchor display, a dock trigger zone is calculated at the relevant edge (bottom, left, or right — matching Dock position)
3. When the cursor enters a trigger zone on a non-anchor display, the event's position is clamped just outside the zone
4. The Dock never sees the trigger, so it stays put

Compared to `killall Dock` scripts: no flicker, no restart delay, no interruption to running apps.

## Project Structure

```
FrozenDock/
├── App/                    FrozenDockApp, AppDelegate
├── Models/                 DisplayInfo, Profile, AppSettings
├── Services/
│   ├── DockProtectionService   CGEventTap-based protection core
│   ├── DisplayManager          Display detection & change monitoring
│   ├── DockController          Cursor warp to move dock
│   ├── ProfileManager          Profile CRUD & auto-switching
│   ├── LoginItemManager        Start at login (SMAppService)
│   └── UpdateChecker           GitHub release checker
├── Views/
│   ├── ContentView             Sidebar + dashboard
│   ├── SettingsView            All settings panels
│   ├── DisplayMapView          Real-time monitor visualization
│   ├── ProfilesView            Profile management UI
│   └── StatusBadgeView         Status indicator components
├── Utilities/              Constants, AccessibilityHelper
└── Resources/              Assets, Info.plist, entitlements
```

## Privacy

FrozenDock only monitors mouse movement events. It does not collect, store, or transmit any data. Everything runs locally.

## Acknowledgements

Inspired by [DockAnchor](https://github.com/bwya77/DockAnchor) by bwya77.

## License

MIT
