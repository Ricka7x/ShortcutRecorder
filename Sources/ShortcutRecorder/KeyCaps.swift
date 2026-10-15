import AppKit
import KeyboardShortcuts

/// Splits a shortcut into the individual keys shown as keycap chips, e.g. `⇧ ⌘ B`.
enum KeyCaps {
    private static let modifierOrder: [(NSEvent.ModifierFlags, String)] = [
        (.control, "⌃"),
        (.option, "⌥"),
        (.shift, "⇧"),
        (.command, "⌘")
    ]

    /// Modifier symbols in the standard macOS order (⌃ ⌥ ⇧ ⌘).
    static func modifierSymbols(for modifiers: NSEvent.ModifierFlags) -> [String] {
        modifierOrder.filter { modifiers.contains($0.0) }.map(\.1)
    }

    /// Every keycap for a shortcut: the modifiers followed by the key itself.
    @MainActor
    static func symbols(for shortcut: KeyboardShortcuts.Shortcut) -> [String] {
        let modifiers = modifierSymbols(for: shortcut.modifiers)
        let description = shortcut.description
        let modifierGlyphs = Set(modifierOrder.map(\.1).joined())
        let key = String(description.drop(while: { modifierGlyphs.contains(String($0)) }))
        return key.isEmpty ? modifiers : modifiers + [key]
    }
}
