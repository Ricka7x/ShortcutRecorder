import AppKit
import KeyboardShortcuts
import XCTest
@testable import ShortcutRecorder

@MainActor
final class ShortcutRecorderTests: XCTestCase {
    func testModifiersUseStandardOrder() {
        XCTAssertEqual(ModifierGlyphs.string(for: [.command, .shift, .option, .control]), "⌃⌥⇧⌘")
    }

    func testShortcutDescriptionIsPlainGlyphs() {
        XCTAssertEqual(KeyboardShortcuts.Shortcut(.b, modifiers: [.command, .shift]).description, "⇧⌘B")
        XCTAssertEqual(KeyboardShortcuts.Shortcut(.f5, modifiers: []).description, "F5")
    }

    func testControllerStartsWithStoredShortcut() {
        let name = KeyboardShortcuts.Name("ShortcutRecorderTests.stored")
        KeyboardShortcuts.setShortcut(.init(.k, modifiers: [.command]), for: name)
        defer { KeyboardShortcuts.setShortcut(nil, for: name) }

        let controller = ShortcutRecordingController(name: name)
        XCTAssertEqual(controller.shortcut, .init(.k, modifiers: [.command]))
        controller.clear()
        XCTAssertNil(KeyboardShortcuts.getShortcut(for: name))
    }

    func testRecordingPausesAndResumesGlobalShortcuts() {
        let controller = ShortcutRecordingController(name: .init("ShortcutRecorderTests.pause"))
        controller.start()
        XCTAssertTrue(KeyboardShortcuts.isPaused)
        controller.stop()
        XCTAssertFalse(KeyboardShortcuts.isPaused)
    }
}
