import AppKit
import SwiftUI

@main
struct InvixrayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu-bar only app: SwiftUI Settings scene satisfies the App protocol
        // without showing a window. All actual UI is owned by AppDelegate.
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let coord = AppCoordinator()
        coord.start()
        self.coordinator = coord
    }
}
