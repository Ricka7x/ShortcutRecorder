import SwiftUI

/// Colours, sizing and typography for ``ShortcutRecorderView``.
///
/// The package knows nothing about an app's theme system. Build one of these from your
/// own theme tokens in a single place and apply it with `.shortcutRecorderStyle(_:)`.
public struct ShortcutRecorderStyle {
    /// Accent used for the recording ring and the recording text.
    public var accent: Color
    /// Fill of the recorder in its idle state.
    public var background: Color
    /// Fill of the recorder while the pointer is over it.
    public var hoverBackground: Color
    /// Hairline border in the idle state.
    public var border: Color
    /// Colour of the shortcut glyphs.
    public var text: Color
    /// Secondary text, used for the placeholder and the remove button.
    public var secondaryText: Color
    /// Colour of inline conflict messages and the error ring.
    public var error: Color
    public var cornerRadius: CGFloat
    public var height: CGFloat
    public var minWidth: CGFloat
    /// Placeholder, prompt and conflict text.
    public var font: Font
    /// The recorded shortcut itself.
    public var shortcutFont: Font

    public init(
        accent: Color = .accentColor,
        background: Color = Color(nsColor: .controlBackgroundColor),
        hoverBackground: Color = Color(nsColor: .quaternaryLabelColor).opacity(0.5),
        border: Color = Color(nsColor: .separatorColor),
        text: Color = Color(nsColor: .labelColor),
        secondaryText: Color = Color(nsColor: .secondaryLabelColor),
        error: Color = Color(nsColor: .systemRed),
        cornerRadius: CGFloat = 8,
        height: CGFloat = 28,
        minWidth: CGFloat = 150,
        font: Font = .system(size: 12, weight: .medium),
        shortcutFont: Font = .system(size: 13, weight: .semibold)
    ) {
        self.accent = accent
        self.background = background
        self.hoverBackground = hoverBackground
        self.border = border
        self.text = text
        self.secondaryText = secondaryText
        self.error = error
        self.cornerRadius = cornerRadius
        self.height = height
        self.minWidth = minWidth
        self.font = font
        self.shortcutFont = shortcutFont
    }

    /// Follows the system appearance and the user's system accent colour.
    public static let `default` = ShortcutRecorderStyle()
}

private struct ShortcutRecorderStyleKey: EnvironmentKey {
    static let defaultValue = ShortcutRecorderStyle.default
}

extension EnvironmentValues {
    var shortcutRecorderStyle: ShortcutRecorderStyle {
        get { self[ShortcutRecorderStyleKey.self] }
        set { self[ShortcutRecorderStyleKey.self] = newValue }
    }
}

extension View {
    /// Styles every ``ShortcutRecorderView`` in this view hierarchy.
    public func shortcutRecorderStyle(_ style: ShortcutRecorderStyle) -> some View {
        environment(\.shortcutRecorderStyle, style)
    }
}
