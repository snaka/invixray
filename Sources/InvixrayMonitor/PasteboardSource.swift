import AppKit

/// Abstracts `NSPasteboard.general` so `ClipboardMonitor` can be unit-tested
/// without touching the system pasteboard.
@MainActor
public protocol PasteboardSource {
    func currentChangeCount() -> Int
    func currentString() -> String?
}

@MainActor
public struct NSPasteboardSource: PasteboardSource {
    public init() {}

    public func currentChangeCount() -> Int {
        NSPasteboard.general.changeCount
    }

    public func currentString() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
}
