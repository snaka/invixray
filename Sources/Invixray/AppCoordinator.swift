import AppKit
import InvixrayCore
import InvixrayMonitor

/// Wires `ClipboardMonitor` events to the menu bar UI and the system
/// notification layer. Owns the long-running monitor task.
@MainActor
final class AppCoordinator {
    private let monitor: ClipboardMonitor
    private let menuBar: MenuBarController
    private let notifier: NotificationManager
    private var monitorTask: Task<Void, Never>?

    init() {
        let monitor = ClipboardMonitor()
        self.monitor = monitor
        self.menuBar = MenuBarController()
        self.notifier = NotificationManager()
    }

    func start() {
        menuBar.notificationStatusProvider = { [notifier] in
            notifier.authorizationStatus
        }
        menuBar.install()
        Task { [notifier] in
            await notifier.requestAuthorizationIfNeeded()
        }
        monitorTask = Task { [monitor, menuBar, notifier] in
            for await event in monitor.events() {
                menuBar.handle(event)
                await notifier.deliver(event)
            }
        }
    }
}
