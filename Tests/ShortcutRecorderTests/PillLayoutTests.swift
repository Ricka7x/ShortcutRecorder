import AppKit
import SwiftUI
import XCTest
@testable import ShortcutRecorder

@MainActor
final class PillLayoutTests: XCTestCase {
    private func size(of pill: ShortcutRecorderPill, style: ShortcutRecorderStyle = .default) -> CGSize {
        NSHostingView(rootView: pill.shortcutRecorderStyle(style)).fittingSize
    }

    func testEveryStateRespectsTheMinimumSize() {
        let style = ShortcutRecorderStyle.default
        let pills: [ShortcutRecorderPill] = [
            .init(shortcutText: nil, isRecording: false),
            .init(shortcutText: "⇧⌘B", isRecording: false),
            .init(shortcutText: "⇧⌘B", isRecording: false, isHovering: true),
            .init(shortcutText: "⇧⌘B", isRecording: true),
            .init(shortcutText: nil, isRecording: true, liveModifiers: "⇧⌘"),
            .init(shortcutText: nil, isRecording: true, feedback: .error("Used by “Quit”")),
        ]
        for pill in pills {
            let fitted = size(of: pill)
            XCTAssertGreaterThanOrEqual(fitted.width, style.minWidth)
            XCTAssertGreaterThanOrEqual(fitted.height, style.height)
        }
    }

    func testHoveringAFilledShortcutDoesNotChangeItsSize() {
        let idle = size(of: .init(shortcutText: "⇧⌘B", isRecording: false))
        let hovered = size(of: .init(shortcutText: "⇧⌘B", isRecording: false, isHovering: true))
        XCTAssertEqual(idle, hovered, "The remove button must not shift the layout")
    }

    func testStyleOverridesAreApplied() {
        var style = ShortcutRecorderStyle.default
        style.minWidth = 220
        style.height = 36
        let fitted = size(of: .init(shortcutText: nil, isRecording: false), style: style)
        XCTAssertGreaterThanOrEqual(fitted.width, 220)
        XCTAssertGreaterThanOrEqual(fitted.height, 36)
    }

    func testLongConflictMessageGrowsInsteadOfClipping() {
        let short = size(of: .init(shortcutText: nil, isRecording: true))
        let long = size(of: .init(shortcutText: nil, isRecording: true, feedback: .error("Used by “A Very Long Menu Item Title”")))
        XCTAssertGreaterThan(long.width, short.width)
    }
}
