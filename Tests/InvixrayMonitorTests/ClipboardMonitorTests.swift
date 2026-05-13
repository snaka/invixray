import Testing
@testable import InvixrayMonitor
import InvixrayCore

@MainActor
final class MockPasteboardSource: PasteboardSource {
    var changeCount: Int = 0
    var content: String?

    func currentChangeCount() -> Int { changeCount }
    func currentString() -> String? { content }

    func write(_ text: String) {
        changeCount += 1
        content = text
    }
}

@Suite("ClipboardMonitor")
@MainActor
struct ClipboardMonitorTests {

    @Test("Initial tick yields nothing")
    func initialTickYieldsNothing() {
        let mock = MockPasteboardSource()
        let monitor = ClipboardMonitor(source: mock)
        #expect(monitor.tick() == nil)
    }

    @Test("Clipboard change with no findings yields nothing")
    func benignChangeYieldsNothing() {
        let mock = MockPasteboardSource()
        let monitor = ClipboardMonitor(source: mock)
        mock.write("plain text, no invisibles")
        #expect(monitor.tick() == nil)
    }

    @Test("Clipboard change with Unicode Tag triggers an event")
    func tagTriggersEvent() {
        let mock = MockPasteboardSource()
        let monitor = ClipboardMonitor(source: mock)
        mock.write("safe-looking\u{E0048}text")
        let event = monitor.tick()
        #expect(event != nil)
        #expect(event?.findings.first?.kind == .unicodeTag)
        #expect(event?.findings.first?.severity == .critical)
    }

    @Test("Identical changeCount does not re-trigger")
    func sameChangeCountIsIdle() {
        let mock = MockPasteboardSource()
        let monitor = ClipboardMonitor(source: mock)
        mock.write("hi\u{E0048}")
        _ = monitor.tick()
        // No new write -> changeCount unchanged
        #expect(monitor.tick() == nil)
    }

    @Test("Successive distinct changes each fire once")
    func successiveChangesFire() {
        let mock = MockPasteboardSource()
        let monitor = ClipboardMonitor(source: mock)

        mock.write("first\u{E0041}")
        #expect(monitor.tick() != nil)

        mock.write("second\u{E0042}")
        #expect(monitor.tick() != nil)

        // No write between ticks -> nothing
        #expect(monitor.tick() == nil)
    }

    @Test("Empty clipboard string is ignored")
    func emptyStringIgnored() {
        let mock = MockPasteboardSource()
        let monitor = ClipboardMonitor(source: mock)
        mock.write("")
        #expect(monitor.tick() == nil)
    }
}
