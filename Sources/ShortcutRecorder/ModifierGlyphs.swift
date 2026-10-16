import AppKit

/// Modifier glyphs in the standard macOS order (⌃ ⌥ ⇧ ⌘), for the live preview while recording.
enum ModifierGlyphs {
    private static let order: [(NSEvent.ModifierFlags, String)] = [
        (.control, "⌃"),
        (.option, "⌥"),
        (.shift, "⇧"),
        (.command, "⌘")
    ]

    static func string(for modifiers: NSEvent.ModifierFlags) -> String {
        order.filter { modifiers.contains($0.0) }.map(\.1).joined()
    }
}
