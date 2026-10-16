# ShortcutRecorder

A SwiftUI control for recording global keyboard shortcuts on macOS. It replaces
`KeyboardShortcuts.Recorder` with a flat button that turns into an input when clicked,
inline conflict messages and a hover-to-remove button, and takes its colours from your
app's own theme.

Shortcut storage and global registration still come from
[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts), so your existing
`KeyboardShortcuts.Name`s, saved values and `onKeyDown` handlers keep working.

| State | What the user sees |
|---|---|
| Empty | "Record Shortcut" placeholder |
| Hover (empty) | Slightly filled background |
| Filled | The shortcut as bold glyphs (`⇧⌘B`) |
| Hover (filled) | Filled background and a remove (x) button on the right |
| Recording | Accent ring and "Press shortcut…" |
| Live keys | Held modifiers shown in the accent colour (`⇧⌘…`) |
| Conflict | Red ring and message ("Used by “Quit App”"), or orange for macOS-reserved shortcuts |

## Requirements

- macOS 12+
- Swift 5.9+ / Xcode 15+

## Installation

> **Important: this package depends on a fork of KeyboardShortcuts**
> (`github.com/Ricka7x/KeyboardShortcuts`, tag `2.4.1-snapback.2` or later). The fork makes
> the conflict checks public and fixes the Clear button on macOS 26/27. Swift Package
> Manager identifies packages by name, so an app **cannot** also depend on
> `sindresorhus/KeyboardShortcuts`. If your app lists KeyboardShortcuts itself, point that
> entry at the fork too (see [Migrating an app](#migrating-an-app)).

### Option 1: Xcode (app project)

1. Open your project, then **File ▸ Add Package Dependencies…**
2. In the search field paste `https://github.com/Ricka7x/ShortcutRecorder`
3. Set **Dependency Rule** to *Up to Next Major Version* from `0.1.0`.
4. Click **Add Package**, tick the **ShortcutRecorder** library for the app target, and
   click **Add Package** again.

### Option 2: `Package.swift` (local Kit package or SPM project)

Add the dependency and list the product on every target that shows a recorder:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Ricka7x/ShortcutRecorder", from: "0.1.0"),
],
targets: [
    .target(
        name: "FeatureSettingsUI",
        dependencies: [
            .product(name: "ShortcutRecorder", package: "ShortcutRecorder"),
        ]
    ),
]
```

### Option 3: local path (developing the package alongside an app)

Useful while iterating on the package. In Xcode use **File ▸ Add Package Dependencies… ▸
Add Local…** and pick the `ShortcutRecorder` folder, or in `Package.swift`:

```swift
.package(path: "../ShortcutRecorder"),
```

Switch back to the URL form before you commit or release, because a path dependency only
exists on your machine.

### Option 4: pin an exact version

For release builds you can pin exactly, as the apps do for KeyboardShortcuts:

```swift
.package(url: "https://github.com/Ricka7x/ShortcutRecorder", exact: "0.1.0"),
```

### Migrating an app

If the app currently depends on `sindresorhus/KeyboardShortcuts` or on an older fork tag:

1. Change that dependency to the fork and require `2.4.1-snapback.2` or later:
   ```swift
   .package(url: "https://github.com/Ricka7x/KeyboardShortcuts", from: "2.4.1-snapback.2"),
   ```
   In an Xcode project, update it under **Project ▸ Package Dependencies**.
2. Add ShortcutRecorder as shown above.
3. Replace each `KeyboardShortcuts.Recorder(for: name)` with `ShortcutRecorderView(name: name)`.
4. Resolve packages (**File ▸ Packages ▸ Resolve Package Versions**) and build.

## Usage

```swift
import KeyboardShortcuts
import ShortcutRecorder
import SwiftUI

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel", default: .init(.v, modifiers: [.command, .shift]))
}

struct ShortcutSettings: View {
    var body: some View {
        HStack {
            Text("Toggle Panel")
            Spacer()
            ShortcutRecorderView(name: .togglePanel)
        }
    }
}
```

Register the action exactly as before:

```swift
KeyboardShortcuts.onKeyDown(for: .togglePanel) { showPanel() }
```

### Recording behaviour

| Input | Result |
|---|---|
| Click the control | Starts recording and pauses all global shortcuts |
| A modifier combo (`⌘⇧B`) or a function key | Saved, recording ends |
| `⎋` Esc | Cancels, keeps the old shortcut |
| `⌫` / `⌦` | Removes the shortcut |
| `⇥` Tab | Ends recording and lets focus move on |
| Click outside, or the window loses focus | Ends recording |
| Hover a set shortcut | Shows the remove (x) button |
| Key with no modifier | Rejected: "Add ⌘, ⌥ or ⌃" |
| Used by a menu item | Rejected: names the menu item |
| Reserved by macOS | Warns once, pressing the same combo again accepts it |

## API reference

### `ShortcutRecorderView`

```swift
ShortcutRecorderView(
    name: KeyboardShortcuts.Name,
    placeholder: String = "Record Shortcut",
    onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
)
```

| Parameter | Description |
|---|---|
| `name` | The shortcut to record. Saved and loaded through KeyboardShortcuts. |
| `placeholder` | Text shown while nothing is set. |
| `onChange` | Called when the user sets a new shortcut or removes it (`nil`). |

Changes made elsewhere, such as `KeyboardShortcuts.setShortcut(_:for:)` or `reset(_:)`,
update the control automatically.

### `.shortcutRecorderStyle(_:)`

```swift
func shortcutRecorderStyle(_ style: ShortcutRecorderStyle) -> some View
```

Applies a style to every `ShortcutRecorderView` below it. Apply it once near the root of
your settings UI.

### `ShortcutRecorderStyle`

Every property has a default that follows the system appearance and accent colour, so
`ShortcutRecorderStyle()` works with no arguments and so does `.default`.

| Property | Type | Used for |
|---|---|---|
| `accent` | `Color` | Recording ring and recording text |
| `background` | `Color` | Idle fill |
| `hoverBackground` | `Color` | Fill while hovered |
| `border` | `Color` | Idle hairline border |
| `text` | `Color` | The recorded shortcut |
| `secondaryText` | `Color` | Placeholder, remove button icon |
| `error` | `Color` | Conflict ring and message |
| `cornerRadius` | `CGFloat` | Default `8` |
| `height` | `CGFloat` | Minimum height, default `28` |
| `minWidth` | `CGFloat` | Minimum width, default `148` |
| `font` | `Font` | Placeholder, prompt and conflict text |
| `shortcutFont` | `Font` | The recorded shortcut |

### Applying your app's theme

The package never imports an app's theme types. Build a style from your own tokens in one
adapter and apply it once (the `PeggoTheme` property names below are illustrative):

```swift
extension ShortcutRecorderStyle {
    static func peggo(_ theme: PeggoTheme) -> ShortcutRecorderStyle {
        ShortcutRecorderStyle(
            accent: theme.accent,
            background: theme.controlBackground,
            border: theme.border,
            text: theme.textPrimary,
            secondaryText: theme.textSecondary,
            cornerRadius: theme.controlRadius
        )
    }
}

SettingsRootView()
    .shortcutRecorderStyle(.peggo(themeManager.current))
```

Because the style is read from the SwiftUI environment, it updates live when the theme
changes.

## Accessibility

- The control is exposed as a button labelled "Keyboard shortcut" whose value is the current
  shortcut, with a "Record shortcut" action for VoiceOver.
- The remove button has a label and a tooltip.
- Known limitation: the control does not take keyboard focus from Tab, because key-view
  navigation for SwiftUI controls needs macOS 14+. Start recording with a click or the
  VoiceOver action.

## Development

```bash
swift build
swift test
```

To review the design, render every state to PNG:

```bash
SHORTCUT_RECORDER_RENDER_DIR=/tmp/shortcut-states swift test --filter RenderStatesTests
```

The visuals live in `ShortcutRecorderPill` and are driven by plain values, so a new state
is one initializer call in `RenderStatesTests`.
