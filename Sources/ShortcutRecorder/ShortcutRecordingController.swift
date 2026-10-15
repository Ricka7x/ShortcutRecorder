import AppKit
import KeyboardShortcuts

/// Drives one recorder: owns the key-capture monitor and applies the conflict checks.
@MainActor
final class ShortcutRecordingController: ObservableObject {
    enum Feedback: Equatable {
        case none
        case error(String)
        case warning(String)
    }

    @Published private(set) var shortcut: KeyboardShortcuts.Shortcut?
    @Published private(set) var isRecording = false
    @Published private(set) var liveModifiers: NSEvent.ModifierFlags = []
    @Published private(set) var feedback: Feedback = .none

    let name: KeyboardShortcuts.Name
    var onChange: ((KeyboardShortcuts.Shortcut?) -> Void)?

    /// The recorder's view. Used to tell clicks inside the recorder from clicks outside it.
    weak var anchorView: NSView?

    // The monitor token must be held strongly. `NSEvent.addLocalMonitorForEvents` returns
    // an object the caller owns until `removeMonitor`.
    private var monitor: Any?
    private var nameObserver: NSObjectProtocol?
    private var resignObserver: NSObjectProtocol?
    private var pendingSystemShortcut: KeyboardShortcuts.Shortcut?

    private static let relevantModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

    init(name: KeyboardShortcuts.Name, onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil) {
        self.name = name
        self.onChange = onChange
        shortcut = KeyboardShortcuts.getShortcut(for: name)

        nameObserver = NotificationCenter.default.addObserver(
            forName: .shortcutByNameDidChange, object: nil, queue: .main
        ) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self, let changed = note.userInfo?["name"] as? KeyboardShortcuts.Name, changed == self.name else { return }
                self.shortcut = KeyboardShortcuts.getShortcut(for: self.name)
            }
        }
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let nameObserver { NotificationCenter.default.removeObserver(nameObserver) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
    }

    // MARK: - Session

    func start() {
        guard !isRecording else { return }
        isRecording = true
        feedback = .none
        pendingSystemShortcut = nil

        // Pause global shortcuts so pressing an existing one is recorded, not triggered.
        KeyboardShortcuts.isPaused = true
        NotificationCenter.default.post(name: .recorderActiveStatusDidChange, object: nil, userInfo: ["isActive": true])

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return event }
            nonisolated(unsafe) let event = event
            return MainActor.assumeIsolated { self.handle(event) }
        }

        if let window = anchorView?.window {
            resignObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification, object: window, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.stop() }
            }
        }
    }

    func stop() {
        guard isRecording else { return }
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        resignObserver = nil

        isRecording = false
        liveModifiers = []
        feedback = .none
        pendingSystemShortcut = nil

        KeyboardShortcuts.isPaused = false
        NotificationCenter.default.post(name: .recorderActiveStatusDidChange, object: nil, userInfo: ["isActive": false])
    }

    func clear() {
        save(nil)
        stop()
    }

    // MARK: - Events

    private func handle(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .flagsChanged:
            liveModifiers = event.modifierFlags.intersection(Self.relevantModifiers)
            return event

        case .leftMouseDown, .rightMouseDown:
            if isInsideAnchor(event) { return event }
            stop()
            return event

        case .keyDown:
            return handleKeyDown(event)

        default:
            return event
        }
    }

    private func isInsideAnchor(_ event: NSEvent) -> Bool {
        guard let view = anchorView, event.window === view.window else { return false }
        return view.bounds.insetBy(dx: -3, dy: -3).contains(view.convert(event.locationInWindow, from: nil))
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        let modifiers = event.modifierFlags.intersection(Self.relevantModifiers)
        let isBare = modifiers.isEmpty

        if isBare, event.keyCode == 53 { // Escape
            stop()
            return nil
        }

        if isBare, event.specialKey == .tab {
            stop()
            return event // Let focus move on.
        }

        if isBare, [.delete, .deleteForward, .backspace].contains(event.specialKey) {
            clear()
            return nil
        }

        let isFunctionKey = event.specialKey.map(Self.functionKeys.contains) ?? false
        guard !isBare || isFunctionKey, let candidate = KeyboardShortcuts.Shortcut(event: event) else {
            reject("Add ⌘, ⌥ or ⌃")
            return nil
        }

        if let menuItem = candidate.takenByMainMenu {
            reject("Used by “\(menuItem.title)”")
            return nil
        }

        if candidate.isDisallowed {
            reject("Not allowed on this macOS")
            return nil
        }

        if candidate.isTakenBySystem, pendingSystemShortcut != candidate {
            // First press warns, pressing the same combination again overrides.
            pendingSystemShortcut = candidate
            feedback = .warning("Reserved by macOS. Press again to use it")
            NSSound.beep()
            return nil
        }

        save(candidate)
        stop()
        return nil
    }

    private func reject(_ message: String) {
        pendingSystemShortcut = nil
        feedback = .error(message)
        NSSound.beep()
    }

    private func save(_ newValue: KeyboardShortcuts.Shortcut?) {
        KeyboardShortcuts.setShortcut(newValue, for: name)
        shortcut = newValue
        onChange?(newValue)
    }

    private static let functionKeys: Set<NSEvent.SpecialKey> = [
        .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10,
        .f11, .f12, .f13, .f14, .f15, .f16, .f17, .f18, .f19, .f20
    ]
}
