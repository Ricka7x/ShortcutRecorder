import AppKit
import KeyboardShortcuts
import XCTest
@testable import ShortcutRecorder

/// Drives the controller with synthesized key and mouse events, the way the local monitor does.
@MainActor
final class ControllerEventTests: XCTestCase {
    private var shortcutName: KeyboardShortcuts.Name!
    private var controller: ShortcutRecordingController!
    private var changes: [KeyboardShortcuts.Shortcut?] = []

    override func setUp() {
        super.setUp()
        shortcutName = KeyboardShortcuts.Name("ShortcutRecorderTests.events.\(UUID().uuidString)")
        changes = []
        controller = ShortcutRecordingController(name: shortcutName) { [unowned self] in changes.append($0) }
    }

    override func tearDown() {
        controller.stop()
        KeyboardShortcuts.setShortcut(nil, for: shortcutName)
        super.tearDown()
    }

    // MARK: - Helpers

    private func key(_ characters: String, code: UInt16, modifiers: NSEvent.ModifierFlags = []) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0, windowNumber: 0,
            context: nil, characters: characters, charactersIgnoringModifiers: characters.lowercased(),
            isARepeat: false, keyCode: code
        )!
    }

    private func special(_ key: NSEvent.SpecialKey, code: UInt16) -> NSEvent {
        self.key(String(Character(UnicodeScalar(key.rawValue)!)), code: code)
    }

    private func flags(_ modifiers: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(
            with: .flagsChanged, location: .zero, modifierFlags: modifiers, timestamp: 0, windowNumber: 0,
            context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 55
        )!
    }

    private let kVK_B: UInt16 = 11
    private let kVK_Escape: UInt16 = 53

    // MARK: - Recording

    func testModifierComboIsSavedAndEndsRecording() {
        controller.start()
        let result = controller.handle(key("B", code: kVK_B, modifiers: [.command, .shift]))

        XCTAssertNil(result, "The event is consumed")
        XCTAssertEqual(controller.shortcut, .init(.b, modifiers: [.command, .shift]))
        XCTAssertEqual(KeyboardShortcuts.getShortcut(for: shortcutName), controller.shortcut)
        XCTAssertFalse(controller.isRecording)
        XCTAssertFalse(KeyboardShortcuts.isPaused, "Global shortcuts resume so the new one is live")
        XCTAssertEqual(changes, [.init(.b, modifiers: [.command, .shift])])
    }

    func testBareLetterIsRejectedWithFeedback() {
        controller.start()
        let result = controller.handle(key("b", code: kVK_B))

        XCTAssertNil(result)
        XCTAssertNil(controller.shortcut)
        XCTAssertTrue(controller.isRecording, "Stays recording so the user can try again")
        XCTAssertEqual(controller.feedback, .error("Add ⌘, ⌥ or ⌃"))
        XCTAssertTrue(changes.isEmpty)
    }

    func testShiftAloneIsRejected() {
        controller.start()
        _ = controller.handle(key("B", code: kVK_B, modifiers: [.shift]))

        XCTAssertNil(controller.shortcut)
        XCTAssertTrue(controller.isRecording)
    }

    func testFunctionKeyWithoutModifiersIsAccepted() {
        controller.start()
        _ = controller.handle(special(.f5, code: 96))

        XCTAssertEqual(controller.shortcut, .init(.f5, modifiers: []))
        XCTAssertFalse(controller.isRecording)
    }

    func testEscapeCancelsAndKeepsOldShortcut() {
        KeyboardShortcuts.setShortcut(.init(.k, modifiers: [.command]), for: shortcutName)
        controller = ShortcutRecordingController(name: shortcutName)
        controller.start()

        XCTAssertNil(controller.handle(key("\u{1B}", code: kVK_Escape)))
        XCTAssertFalse(controller.isRecording)
        XCTAssertEqual(controller.shortcut, .init(.k, modifiers: [.command]))
    }

    func testDeleteRemovesTheShortcut() {
        KeyboardShortcuts.setShortcut(.init(.k, modifiers: [.command]), for: shortcutName)
        controller = ShortcutRecordingController(name: shortcutName) { [unowned self] in changes.append($0) }
        controller.start()

        XCTAssertNil(controller.handle(special(.delete, code: 51)))
        XCTAssertNil(controller.shortcut)
        XCTAssertNil(KeyboardShortcuts.getShortcut(for: shortcutName))
        XCTAssertFalse(controller.isRecording)
        XCTAssertEqual(changes.count, 1)
        XCTAssertNil(changes[0])
    }

    func testTabEndsRecordingAndPassesTheEventOn() {
        controller.start()
        let tab = special(.tab, code: 48)

        XCTAssertNotNil(controller.handle(tab), "Tab bubbles up so focus can move")
        XCTAssertFalse(controller.isRecording)
    }

    // MARK: - Live modifiers

    func testHeldModifiersAreTrackedWhileRecording() {
        controller.start()
        _ = controller.handle(flags([.command, .shift]))
        XCTAssertEqual(controller.liveModifiers, [.command, .shift])

        _ = controller.handle(flags([]))
        XCTAssertEqual(controller.liveModifiers, [])
    }

    // MARK: - Session lifecycle

    func testStartingTwiceDoesNotStackMonitors() {
        controller.start()
        controller.start()
        controller.stop()
        XCTAssertFalse(controller.isRecording)
        XCTAssertFalse(KeyboardShortcuts.isPaused)
    }

    func testStopClearsFeedback() {
        controller.start()
        _ = controller.handle(key("b", code: kVK_B))
        XCTAssertNotEqual(controller.feedback, .none)

        controller.stop()
        XCTAssertEqual(controller.feedback, .none)
    }

    func testStartResetsPreviousFeedback() {
        controller.start()
        _ = controller.handle(key("b", code: kVK_B))
        controller.stop()
        controller.start()
        XCTAssertEqual(controller.feedback, .none)
    }

    func testExternalChangeUpdatesTheControl() {
        let expectation = expectation(description: "controller refreshes")
        KeyboardShortcuts.setShortcut(.init(.j, modifiers: [.option]), for: shortcutName)

        DispatchQueue.main.async {
            XCTAssertEqual(self.controller.shortcut, .init(.j, modifiers: [.option]))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    func testResetRestoresTheDefaultInTheControl() {
        let defaulted = KeyboardShortcuts.Name("ShortcutRecorderTests.default.\(UUID().uuidString)", default: .init(.v, modifiers: [.command, .shift]))
        let controller = ShortcutRecordingController(name: defaulted)
        XCTAssertEqual(controller.shortcut, .init(.v, modifiers: [.command, .shift]))

        controller.clear()
        XCTAssertNil(controller.shortcut)
    }

    // MARK: - Mouse

    private func window(with view: NSView) -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
        view.frame = NSRect(x: 100, y: 100, width: 150, height: 28)
        window.contentView?.addSubview(view)
        return window
    }

    private func click(at point: NSPoint, in window: NSWindow) -> NSEvent {
        NSEvent.mouseEvent(
            with: .leftMouseDown, location: point, modifierFlags: [], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
        )!
    }

    func testClickOutsideEndsRecording() {
        let anchor = NSView()
        let window = window(with: anchor)
        controller.anchorView = anchor
        controller.start()

        let event = click(at: NSPoint(x: 10, y: 10), in: window)
        XCTAssertNotNil(controller.handle(event), "The click still goes through to what was clicked")
        XCTAssertFalse(controller.isRecording)
    }

    func testClickInsideKeepsRecording() {
        let anchor = NSView()
        let window = window(with: anchor)
        controller.anchorView = anchor
        controller.start()

        let event = click(at: NSPoint(x: 150, y: 114), in: window)
        XCTAssertNotNil(controller.handle(event))
        XCTAssertTrue(controller.isRecording)
    }
}
