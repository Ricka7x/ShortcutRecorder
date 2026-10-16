import AppKit
import KeyboardShortcuts
import SwiftUI

/// A control for recording a global keyboard shortcut. Drop-in replacement for
/// `KeyboardShortcuts.Recorder`, built on the same storage and registration.
///
/// ```swift
/// ShortcutRecorderView(name: .togglePanel)
/// ```
///
/// Click it, press the combination, done. Esc cancels, Delete removes, clicking outside
/// stops recording, and hovering a set shortcut reveals a remove button. Style it with `.shortcutRecorderStyle(_:)`.
public struct ShortcutRecorderView: View {
    @StateObject private var controller: ShortcutRecordingController
    @Environment(\.shortcutRecorderStyle) private var style
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    private let placeholder: String

    /// - Parameters:
    ///   - name: The shortcut to record. Storage is handled by KeyboardShortcuts.
    ///   - placeholder: Text shown while no shortcut is set.
    ///   - onChange: Called when the user sets or removes the shortcut.
    public init(
        name: KeyboardShortcuts.Name,
        placeholder: String = "Record Shortcut",
        onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        _controller = StateObject(wrappedValue: ShortcutRecordingController(name: name, onChange: onChange))
    }

    public var body: some View {
        ShortcutRecorderPill(
            shortcutText: controller.shortcut?.description,
            isRecording: controller.isRecording,
            liveModifiers: ModifierGlyphs.string(for: controller.liveModifiers),
            feedback: controller.feedback,
            placeholder: placeholder,
            isHovering: isHovering,
            onClear: { controller.clear() }
        )
        .background(AnchorView(controller: controller))
        .onHover { isHovering = $0 }
        .onTapGesture {
            // `onTapGesture` still fires on a view marked `.disabled`, so check explicitly.
            if isEnabled { controller.start() }
        }
        .onChange(of: isEnabled) { enabled in
            if !enabled { controller.stop() }
        }
        .opacity(isEnabled ? 1 : 0.5)
        .onDisappear { controller.stop() }
        .fixedSize()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Keyboard shortcut")
        .accessibilityValue(controller.shortcut?.description ?? "Not set")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Record shortcut") {
            if isEnabled { controller.start() }
        }
    }
}

/// Hands the controller the recorder's backing `NSView` so it can hit-test clicks.
private struct AnchorView: NSViewRepresentable {
    let controller: ShortcutRecordingController

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        controller.anchorView = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        controller.anchorView = nsView
    }
}
