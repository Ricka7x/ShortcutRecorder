import AppKit
import SwiftUI
import XCTest
@testable import ShortcutRecorder

/// Writes a PNG of every state when `SHORTCUT_RECORDER_RENDER_DIR` is set. Used to review the design.
@MainActor
final class RenderStatesTests: XCTestCase {
    func testRenderAllStates() throws {
        guard let dir = ProcessInfo.processInfo.environment["SHORTCUT_RECORDER_RENDER_DIR"] else {
            throw XCTSkip("Set SHORTCUT_RECORDER_RENDER_DIR to render the states.")
        }

        for (appearance, name) in [(NSAppearance.Name.darkAqua, "dark"), (.aqua, "light")] {
            let sheet = VStack(alignment: .leading, spacing: 14) {
                row("Empty") { ShortcutRecorderPill(shortcutText: nil, isRecording: false) }
                row("Hover") { ShortcutRecorderPill(shortcutText: nil, isRecording: false, isHovering: true) }
                row("Filled") { ShortcutRecorderPill(shortcutText: "⇧⌘B", isRecording: false) }
                row("Filled hover") { ShortcutRecorderPill(shortcutText: "⇧⌘B", isRecording: false, isHovering: true) }
                row("Recording") { ShortcutRecorderPill(shortcutText: "⇧⌘B", isRecording: true) }
                row("Live keys") { ShortcutRecorderPill(shortcutText: nil, isRecording: true, liveModifiers: "⇧⌘") }
                row("Error") { ShortcutRecorderPill(shortcutText: nil, isRecording: true, feedback: .error("Used by “Quit Peggo”")) }
                row("Warning") { ShortcutRecorderPill(shortcutText: nil, isRecording: true, feedback: .warning("Reserved by macOS. Press again")) }
            }
            .padding(20)
            .background(name == "dark" ? Color(white: 0.11) : Color(white: 0.97))

            let host = NSHostingView(rootView: sheet)
            host.appearance = NSAppearance(named: appearance)
            host.frame = NSRect(origin: .zero, size: host.fittingSize)
            host.layoutSubtreeIfNeeded()
            let rep = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: rep)
            let data = try XCTUnwrap(rep.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("states-\(name).png"))
        }
    }

    private func row(_ label: String, @ViewBuilder _ pill: () -> some View) -> some View {
        HStack(spacing: 16) {
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary).frame(width: 70, alignment: .leading)
            pill()
        }
    }
}
