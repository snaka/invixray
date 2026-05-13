import SwiftUI
import UserNotifications
import InvixrayCore
import InvixrayMonitor

struct FindingsPopoverView: View {
    let event: ClipboardEvent?
    let notificationStatus: UNAuthorizationStatus
    let onSanitize: () -> Void
    let onDismiss: () -> Void

    private var topSeverity: Finding.Severity? {
        event?.findings.map(\.severity).min()
    }

    var body: some View {
        VStack(spacing: 0) {
            banner
            content
        }
        .frame(width: 380)
    }

    @ViewBuilder
    private var banner: some View {
        HStack(spacing: 8) {
            Image(systemName: bannerIcon)
                .font(.system(size: 18, weight: .bold))
            Text(bannerTitle)
                .font(.system(.headline, design: .rounded).weight(.bold))
            Spacer()
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.white.opacity(0.85))
            .help("Quit Invixray")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(bannerBackground)
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var bannerBackground: some View {
        switch topSeverity {
        case .critical: Color(red: 0.86, green: 0.20, blue: 0.20)
        case .high:     Color(red: 0.95, green: 0.55, blue: 0.10)
        case .warn:     Color(red: 0.85, green: 0.65, blue: 0.10)
        case .none:     Color(red: 0.20, green: 0.55, blue: 0.30)
        }
    }

    private var bannerIcon: String {
        topSeverity == nil ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
    }

    private var bannerTitle: String {
        switch topSeverity {
        case .critical: return "Critical: Invisible Unicode"
        case .high:     return "High: Zero-Width Payload"
        case .warn:     return "Notice: Invisible Characters"
        case .none:     return "Invixray — All clear"
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let event {
                findingsList(event)
                if notificationStatus == .denied {
                    notificationHint
                }
                Divider()
                actions
            } else {
                idleState
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(contentBackground)
    }

    @ViewBuilder
    private var contentBackground: some View {
        switch topSeverity {
        case .critical: Color.red.opacity(0.08)
        case .high:     Color.orange.opacity(0.10)
        case .warn:     Color.yellow.opacity(0.12)
        case .none:     Color.green.opacity(0.06)
        }
    }

    @ViewBuilder
    private var idleState: some View {
        VStack(spacing: 6) {
            Text("Watching the clipboard for invisible Unicode used in LLM prompt-injection.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
    }

    @ViewBuilder
    private func findingsList(_ event: ClipboardEvent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(event.findings.enumerated()), id: \.offset) { _, finding in
                HStack(alignment: .top, spacing: 8) {
                    severityBadge(finding.severity)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(finding.label)
                            .font(.system(.callout, design: .rounded))
                        Text(codepointDescription(finding.codepoints))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private func severityBadge(_ severity: Finding.Severity) -> some View {
        Text(severity.rawValue.uppercased())
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severityColor(severity).opacity(0.25))
            .foregroundStyle(severityColor(severity))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func severityColor(_ severity: Finding.Severity) -> Color {
        switch severity {
        case .critical: return .red
        case .high:     return .orange
        case .warn:     return .yellow
        }
    }

    private func codepointDescription(_ codepoints: [UInt32]) -> String {
        let head = codepoints.prefix(4).map { String(format: "U+%04X", $0) }
        let suffix = codepoints.count > 4 ? " +\(codepoints.count - 4) more" : ""
        return head.joined(separator: " ") + suffix
    }

    @ViewBuilder
    private var notificationHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "bell.slash")
            Text("System notifications disabled — enable in System Settings → Notifications → Invixray")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var actions: some View {
        HStack {
            Button("Dismiss") { onDismiss() }
                .keyboardShortcut(.escape, modifiers: [])
            Spacer()
            Button("Copy Sanitized") { onSanitize() }
                .keyboardShortcut("s", modifiers: [.command])
                .buttonStyle(.borderedProminent)
        }
    }
}
