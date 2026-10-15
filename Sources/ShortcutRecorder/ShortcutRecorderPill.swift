import SwiftUI

/// The recorder's visuals, with no behaviour attached. Driven by plain values so it can be
/// previewed and snapshot-tested in every state.
struct ShortcutRecorderPill: View {
    var keys: [String]
    var isRecording: Bool
    var liveKeys: [String] = []
    var feedback: ShortcutRecordingController.Feedback = .none
    var placeholder: String = "Record Shortcut"
    var isHovering: Bool = false
    var onClear: () -> Void = {}
    var onCancel: () -> Void = {}

    @Environment(\.shortcutRecorderStyle) private var style

    private var hasShortcut: Bool { !keys.isEmpty }

    var body: some View {
        HStack(spacing: 8) {
            content
            if isRecording {
                Button(action: onCancel) {
                    keycap("esc", dimmed: true)
                }
                .buttonStyle(.plain)
                .help("Cancel")
                .accessibilityLabel("Cancel recording")
            } else if hasShortcut {
                clearButton
            }
        }
        .padding(.horizontal, 8)
        .frame(minWidth: style.minWidth, minHeight: style.height)
        .background(
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .fill(isHovering && !isRecording ? style.hoverBackground : style.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .strokeBorder(ringColor, lineWidth: isRecording || feedbackColor != nil ? 1.5 : 1)
        )
        .shadow(color: isRecording ? style.accent.opacity(0.28) : .clear, radius: 4)
        .contentShape(Rectangle())
    }

    // MARK: - Pieces

    @ViewBuilder
    private var content: some View {
        if let message = feedbackMessage, let color = feedbackColor {
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        } else if isRecording {
            if liveKeys.isEmpty {
                Text("Press shortcut…")
                    .font(style.font)
                    .foregroundStyle(style.accent)
                    .frame(maxWidth: .infinity)
            } else {
                keyRow(liveKeys, tint: style.accent)
                    .frame(maxWidth: .infinity)
            }
        } else if hasShortcut {
            keyRow(keys, tint: nil)
                .frame(maxWidth: .infinity)
        } else {
            Text(placeholder)
                .font(style.font)
                .foregroundStyle(style.secondaryText)
                .frame(maxWidth: .infinity)
        }
    }

    private func keyRow(_ symbols: [String], tint: Color?) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { _, symbol in
                keycap(symbol, tint: tint)
            }
        }
    }

    private func keycap(_ symbol: String, tint: Color? = nil, dimmed: Bool = false) -> some View {
        Text(symbol)
            .font(symbol.count > 1 ? .system(size: 10, weight: .semibold, design: .rounded) : style.keycapFont)
            .foregroundStyle(tint ?? (dimmed ? style.secondaryText : style.text))
            .padding(.horizontal, symbol.count > 1 ? 6 : 0)
            .frame(minWidth: 20, minHeight: 20)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(style.keycapBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder((tint ?? style.keycapBorder).opacity(tint == nil ? 1 : 0.6), lineWidth: 1)
            )
    }

    private var clearButton: some View {
        Button(action: onClear) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(style.secondaryText)
                .frame(width: 18, height: 18)
                .background(Circle().fill(style.keycapBackground))
                .overlay(Circle().strokeBorder(style.keycapBorder, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
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
