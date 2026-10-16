import SwiftUI

/// The recorder's visuals, with no behaviour attached. Driven by plain values so it can be
/// previewed and snapshot-tested in every state.
struct ShortcutRecorderPill: View {
    /// The saved shortcut as glyphs, e.g. `⇧⌘B`. `nil` when none is set.
    var shortcutText: String?
    var isRecording: Bool
    /// Modifiers currently held while recording, e.g. `⇧⌘`.
    var liveModifiers: String = ""
    var feedback: ShortcutRecordingController.Feedback = .none
    var placeholder: String = "Record Shortcut"
    var isHovering: Bool = false
    var onClear: () -> Void = {}

    @Environment(\.shortcutRecorderStyle) private var style

    private var showsClear: Bool { isHovering && !isRecording && shortcutText != nil }

    var body: some View {
        content
            .padding(.horizontal, 26) // Room for the remove button so the label never shifts.
            .frame(minWidth: style.minWidth, minHeight: style.height)
            .background(
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .fill(isHovering && !isRecording ? style.hoverBackground : style.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .strokeBorder(ringColor, lineWidth: ringColor == style.border ? 1 : 1.5)
            )
            .overlay(alignment: .trailing) {
                if showsClear { clearButton }
            }
            .contentShape(Rectangle())
    }

    // MARK: - Pieces

    @ViewBuilder
    private var content: some View {
        if let message = feedbackMessage, let color = feedbackColor {
            Text(message)
                .font(style.font)
                .foregroundStyle(color)
                .lineLimit(1)
        } else if isRecording {
            if liveModifiers.isEmpty {
                Text("Press shortcut…")
                    .font(style.font)
                    .foregroundStyle(style.accent)
            } else {
                Text(liveModifiers + "…")
                    .font(style.shortcutFont)
                    .tracking(1.5)
                    .foregroundStyle(style.accent)
            }
        } else if let shortcutText {
            Text(shortcutText)
                .font(style.shortcutFont)
                .tracking(1.5)
                .foregroundStyle(style.text)
        } else {
            Text(placeholder)
                .font(style.font)
                .foregroundStyle(style.secondaryText)
        }
    }

    private var clearButton: some View {
        Button(action: onClear) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(style.secondaryText)
                .frame(width: 24, height: style.height)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 2)
        .help("Remove shortcut")
        .accessibilityLabel("Remove shortcut")
    }

    // MARK: - Colours

    private var feedbackMessage: String? {
        switch feedback {
        case .none: nil
        case .error(let message), .warning(let message): message
        }
    }

    private var feedbackColor: Color? {
        switch feedback {
        case .none: nil
        case .error: style.error
        case .warning: .orange
        }
    }

    private var ringColor: Color {
        if let feedbackColor { return feedbackColor }
        return isRecording ? style.accent : style.border
    }
}
