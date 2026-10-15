import AppKit
import KeyboardShortcuts
import XCTest
@testable import ShortcutRecorder

@MainActor
final class KeyCapsTests: XCTestCase {
    func testModifiersUseStandardOrder() {
        XCTAssertEqual(KeyCaps.modifierSymbols(for: [.command, .shift, .option, .control]), ["⌃", "⌥", "⇧", "⌘"])
    }

    func testShortcutSplitsIntoModifiersAndKey() {
        let shortcut = KeyboardShortcuts.Shortcut(.b, modifiers: [.command, .shift])
        XCTAssertEqual(KeyCaps.symbols(for: shortcut), ["⇧", "⌘", "B"])
    }

    func testFunctionKeyWithoutModifiers() {
        let shortcut = KeyboardShortcuts.Shortcut(.f5, modifiers: [])
        XCTAssertEqual(KeyCaps.symbols(for: shortcut), ["F5"])
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
