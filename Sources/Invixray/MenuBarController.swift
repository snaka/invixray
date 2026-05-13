import AppKit
import SwiftUI
import UserNotifications
import InvixrayCore
import InvixrayMonitor

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var latestEvent: ClipboardEvent?

    /// Set by AppCoordinator so the popover can show a hint when notifications
    /// are disabled.
    var notificationStatusProvider: (() -> UNAuthorizationStatus)?

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            applyIdleIcon(to: button)
            button.target = self
            button.action = #selector(toggle(_:))
        }
        self.statusItem = item

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 260)
        self.popover = popover

        renderPopoverContent()
    }

    func handle(_ event: ClipboardEvent) {
        self.latestEvent = event
        updateMenuBarIcon(for: event)
        renderPopoverContent()
        autoShowPopover()
    }

    /// Returns to the idle state: clears the latest event, resets the menu bar
    /// icon, and closes the popover. Called from the Dismiss button and after
    /// a successful sanitize.
    func reset() {
        self.latestEvent = nil
        if let button = statusItem?.button {
            applyIdleIcon(to: button)
        }
        renderPopoverContent()
        popover?.performClose(nil)
    }

    @objc private func toggle(_ sender: NSStatusBarButton) {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func autoShowPopover() {
        guard let popover, let button = statusItem?.button else { return }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func renderPopoverContent() {
        guard let popover else { return }
        let status = notificationStatusProvider?() ?? .notDetermined
        let view = FindingsPopoverView(
            event: latestEvent,
            notificationStatus: status,
            onSanitize: { [weak self] in self?.copySanitizedAndReset() },
            onDismiss: { [weak self] in self?.reset() }
        )
        popover.contentViewController = NSHostingController(rootView: view)
    }

    private func applyIdleIcon(to button: NSStatusBarButton) {
        let img = NSImage(
            systemSymbolName: "magnifyingglass",
            accessibilityDescription: "Invixray (idle)"
        )
        img?.isTemplate = true
        button.image = img
        button.contentTintColor = nil
    }

    private func updateMenuBarIcon(for event: ClipboardEvent) {
        guard let button = statusItem?.button else { return }
        let topSeverity = event.findings.map(\.severity).min() ?? .warn
        let symbolName: String
        let tint: NSColor
        switch topSeverity {
        case .critical:
            symbolName = "exclamationmark.triangle.fill"
            tint = .systemRed
        case .high:
            symbolName = "exclamationmark.circle.fill"
            tint = .systemOrange
        case .warn:
            symbolName = "exclamationmark.circle"
            tint = .systemYellow
        }
        let img = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "Invixray (\(topSeverity.rawValue))"
        )
        img?.isTemplate = false
        button.image = img
        button.contentTintColor = tint
    }

    private func copySanitizedAndReset() {
        guard let event = latestEvent else { return }
        let cleaned = InvisibleCharacterDetector.sanitize(
            event.text,
            removing: event.findings
        )
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(cleaned, forType: .string)
        reset()
    }
}
