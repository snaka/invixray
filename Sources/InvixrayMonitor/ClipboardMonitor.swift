import Foundation
import InvixrayCore

public struct ClipboardEvent: Equatable, Sendable {
    public let text: String
    public let findings: [Finding]

    public init(text: String, findings: [Finding]) {
        self.text = text
        self.findings = findings
    }
}

@MainActor
public final class ClipboardMonitor {
    private let source: PasteboardSource
    private var lastChangeCount: Int

    public init(source: PasteboardSource = NSPasteboardSource()) {
        self.source = source
        self.lastChangeCount = source.currentChangeCount()
    }

    /// Single check: returns an event when the pasteboard has changed since
    /// the previous tick AND the new text contains at least one finding.
    /// Designed for unit tests; the production loop calls this on a timer.
    @discardableResult
    public func tick() -> ClipboardEvent? {
        let current = source.currentChangeCount()
        guard current != lastChangeCount else { return nil }
        lastChangeCount = current
        guard let text = source.currentString(), !text.isEmpty else { return nil }
        let findings = InvisibleCharacterDetector.detect(text)
        guard !findings.isEmpty else { return nil }
        return ClipboardEvent(text: text, findings: findings)
    }

    /// Long-running event stream. Ticks every `interval`. Cancel by terminating
    /// the AsyncStream iteration (e.g. by deinit of the consumer task).
    public func events(
        interval: Duration = .milliseconds(500)
    ) -> AsyncStream<ClipboardEvent> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                while !Task.isCancelled {
                    if let event = self.tick() {
                        continuation.yield(event)
                    }
                    try? await Task.sleep(for: interval)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
