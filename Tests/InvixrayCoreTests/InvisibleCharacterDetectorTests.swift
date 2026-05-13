import Testing
@testable import InvixrayCore

@Suite("InvisibleCharacterDetector")
struct InvisibleCharacterDetectorTests {

    // MARK: - Negative cases

    @Test("Empty string yields no findings")
    func emptyString() {
        #expect(InvisibleCharacterDetector.detect("") == [])
    }

    @Test("Plain ASCII yields no findings")
    func plainAscii() {
        #expect(InvisibleCharacterDetector.detect("hello world") == [])
    }

    @Test("Plain Japanese yields no findings")
    func plainJapanese() {
        #expect(InvisibleCharacterDetector.detect("こんにちは、世界。") == [])
    }

    @Test("ZWJ in emoji sequence is not flagged")
    func zwjEmojiNotFlagged() {
        // 👨‍👩‍👧 = U+1F468 U+200D U+1F469 U+200D U+1F467
        #expect(InvisibleCharacterDetector.detect("👨‍👩‍👧 family") == [])
    }

    @Test("Short ZW run below threshold is not flagged")
    func shortZeroWidthRunIgnored() {
        let zwsp = String(repeating: "\u{200B}", count: 7)
        let input = "abc" + zwsp + "def"
        #expect(InvisibleCharacterDetector.detect(input) == [])
    }

    // MARK: - Unicode Tags (Critical)

    @Test("Single Unicode Tag char flagged as critical")
    func singleUnicodeTag() {
        let input = "abc\u{E0052}def" // tag-encoded 'R'
        let findings = InvisibleCharacterDetector.detect(input)
        #expect(findings.count == 1)
        #expect(findings.first?.kind == .unicodeTag)
        #expect(findings.first?.severity == .critical)
        #expect(findings.first?.codepoints == [0xE0052])
    }

    @Test("Consecutive Unicode Tag chars are grouped into one finding")
    func groupedUnicodeTags() {
        let tags = "\u{E0048}\u{E0045}\u{E004C}\u{E004C}\u{E004F}" // tag-encoded "HELLO"
        let input = "ignore me " + tags
        let findings = InvisibleCharacterDetector.detect(input)
        #expect(findings.count == 1)
        #expect(findings.first?.codepoints.count == 5)
    }

    @Test("Tag range boundaries are inclusive")
    func tagBoundaries() {
        let lower = String(Unicode.Scalar(0xE0000)!)
        let upper = String(Unicode.Scalar(0xE007F)!)
        #expect(InvisibleCharacterDetector.detect(lower).count == 1)
        #expect(InvisibleCharacterDetector.detect(upper).count == 1)
        let justOutside = String(Unicode.Scalar(0xE0080)!)
        #expect(InvisibleCharacterDetector.detect(justOutside).isEmpty)
    }

    // MARK: - Zero-Width Binary (High)

    @Test("ZW run at threshold flagged as high")
    func zeroWidthRunAtThreshold() {
        let zw = String(repeating: "\u{200B}", count: 8)
        let findings = InvisibleCharacterDetector.detect(zw)
        #expect(findings.count == 1)
        #expect(findings.first?.kind == .zeroWidthBinary)
        #expect(findings.first?.severity == .high)
        #expect(findings.first?.codepoints.count == 8)
    }

    @Test("Mixed U+200B / U+200C run treated as binary")
    func mixedZeroWidthBinaryRun() {
        // 16 scalars of mixed 200B/200C — 2 ASCII chars worth
        let mixed = "\u{200B}\u{200C}\u{200B}\u{200B}\u{200C}\u{200C}\u{200B}\u{200C}"
                  + "\u{200C}\u{200B}\u{200C}\u{200B}\u{200B}\u{200C}\u{200B}\u{200C}"
        let findings = InvisibleCharacterDetector.detect(mixed)
        #expect(findings.count == 1)
        #expect(findings.first?.kind == .zeroWidthBinary)
        #expect(findings.first?.codepoints.count == 16)
    }

    // MARK: - Bidi (Warn)

    @Test("RTL Override flagged")
    func rtlOverride() {
        let input = "user\u{202E}txt.exe"
        let findings = InvisibleCharacterDetector.detect(input)
        #expect(findings.count == 1)
        #expect(findings.first?.kind == .bidiOverride)
        #expect(findings.first?.severity == .warn)
    }

    // MARK: - Other invisible (Warn)

    @Test("BOM flagged")
    func bomFlagged() {
        let findings = InvisibleCharacterDetector.detect("\u{FEFF}hello")
        #expect(findings.count == 1)
        #expect(findings.first?.kind == .otherInvisible)
        #expect(findings.first?.label.contains("BOM") == true)
    }

    @Test("Soft Hyphen flagged")
    func softHyphenFlagged() {
        let findings = InvisibleCharacterDetector.detect("foo\u{00AD}bar")
        #expect(findings.count == 1)
        #expect(findings.first?.kind == .otherInvisible)
    }

    @Test("Word Joiner flagged")
    func wordJoinerFlagged() {
        let findings = InvisibleCharacterDetector.detect("a\u{2060}b")
        #expect(findings.count == 1)
    }

    // MARK: - Mixed inputs

    @Test("Multiple distinct findings preserve order")
    func multipleDistinctFindings() {
        let input =
            "\u{FEFF}intro "                          // BOM (warn)
            + "\u{E0048}\u{E0049}"                    // Unicode Tag (critical)
            + " mid "
            + String(repeating: "\u{200B}", count: 8) // ZW binary (high)
        let findings = InvisibleCharacterDetector.detect(input)
        #expect(findings.count == 3)
        #expect(findings.map(\.kind) == [.otherInvisible, .unicodeTag, .zeroWidthBinary])
    }

    // MARK: - Sanitize

    @Test("Sanitize removes flagged ranges only")
    func sanitizeRemovesOnlyFlagged() {
        let input = "hello\u{E0048}\u{E0049}world"
        let findings = InvisibleCharacterDetector.detect(input)
        let cleaned = InvisibleCharacterDetector.sanitize(input, removing: findings)
        #expect(cleaned == "helloworld")
    }

    @Test("Sanitize preserves benign ZWJ emoji even with other findings")
    func sanitizePreservesEmoji() {
        let input = "\u{FEFF}👨‍👩‍👧 family"
        let findings = InvisibleCharacterDetector.detect(input)
        let cleaned = InvisibleCharacterDetector.sanitize(input, removing: findings)
        #expect(cleaned == "👨‍👩‍👧 family")
    }

    // MARK: - Severity ordering

    @Test("Severity comparable: critical < high < warn")
    func severityOrdering() {
        #expect(Finding.Severity.critical < Finding.Severity.high)
        #expect(Finding.Severity.high < Finding.Severity.warn)
    }
}
