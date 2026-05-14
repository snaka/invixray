import Foundation
@preconcurrency import UserNotifications
import InvixrayCore
import InvixrayMonitor

@MainActor
final class NotificationManager {
    private let center = UNUserNotificationCenter.current()
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        print("[Invixray] notification authorization status: \(describe(settings.authorizationStatus))")
        guard settings.authorizationStatus == .notDetermined else { return }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            let updated = await center.notificationSettings()
            authorizationStatus = updated.authorizationStatus
            print("[Invixray] requestAuthorization granted=\(granted), now=\(describe(updated.authorizationStatus))")
        } catch {
            print("[Invixray] requestAuthorization error: \(error)")
        }
    }

    private func describe(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .denied:        return "denied"
        case .authorized:    return "authorized"
        case .provisional:   return "provisional"
        case .ephemeral:     return "ephemeral"
        @unknown default:    return "unknown(\(status.rawValue))"
        }
    }

    func deliver(_ event: ClipboardEvent) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
        else { return }

        let content = UNMutableNotificationContent()
        content.title = title(for: event)
        content.body = body(for: event)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }

    private func title(for event: ClipboardEvent) -> String {
        let topSeverity = event.findings.map(\.severity).min() ?? .warn
        switch topSeverity {
        case .critical: return "⚠ Critical: invisible Unicode in clipboard"
        case .high:     return "⚠ High: zero-width payload in clipboard"
        case .warn:     return "Notice: invisible characters in clipboard"
        }
    }

    private func body(for event: ClipboardEvent) -> String {
        let summary = event.findings
            .prefix(3)
            .map(\.label)
            .joined(separator: ", ")
        let extra = event.findings.count > 3 ? " +\(event.findings.count - 3) more" : ""
        return "\(summary)\(extra)"
    }
}
