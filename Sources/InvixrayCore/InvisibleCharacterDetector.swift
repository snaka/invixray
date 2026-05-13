import Foundation

/// Detects invisible Unicode characters that are weaponized for LLM prompt-injection
/// attacks. Detection rules are derived from Graves (2026):
/// "Reverse CAPTCHA: Evaluating LLM Susceptibility to Invisible Unicode Instruction Injection"
/// https://arxiv.org/html/2603.00164v1
public enum InvisibleCharacterDetector {
    /// Threshold (in scalars) at which a contiguous run of binary-encoding zero-width
    /// characters (U+200B / U+200C) is reported. 8 scalars = 1 ASCII char of payload.
    public static let zeroWidthBinaryRunThreshold = 8

    public static func detect(_ text: String) -> [Finding] {
        var findings: [Finding] = []
        let scalars = text.unicodeScalars

        var i = scalars.startIndex
        while i < scalars.endIndex {
            let s = scalars[i]

            if isUnicodeTag(s) {
                let (end, codepoints) = collectRun(from: i, in: scalars, where: isUnicodeTag)
                findings.append(
                    Finding(
                        kind: .unicodeTag,
                        severity: .critical,
                        range: i..<end,
                        codepoints: codepoints,
                        label: "Unicode Tag (\(codepoints.count))"
                    )
                )
                i = end
            } else if isBinaryZeroWidth(s) {
                let (end, codepoints) = collectRun(from: i, in: scalars, where: isBinaryZeroWidth)
                if codepoints.count >= zeroWidthBinaryRunThreshold {
                    findings.append(
                        Finding(
                            kind: .zeroWidthBinary,
                            severity: .high,
                            range: i..<end,
                            codepoints: codepoints,
                            label: "Zero-Width binary run (\(codepoints.count))"
                        )
                    )
                }
                i = end
            } else if isBidiOverride(s) {
                let next = scalars.index(after: i)
                findings.append(
                    Finding(
                        kind: .bidiOverride,
                        severity: .warn,
                        range: i..<next,
                        codepoints: [s.value],
                        label: bidiOverrideName(s)
                    )
                )
                i = next
            } else if let label = otherInvisibleLabel(s) {
                let next = scalars.index(after: i)
                findings.append(
                    Finding(
                        kind: .otherInvisible,
                        severity: .warn,
                        range: i..<next,
                        codepoints: [s.value],
                        label: label
                    )
                )
                i = next
            } else {
                i = scalars.index(after: i)
            }
        }

        return findings
    }

    /// Removes ranges in `findings` from `text`. The caller is expected to first call
    /// `detect` and pass the result here. This avoids the "remove every zero-width
    /// scalar" anti-pattern called out in the paper (would corrupt Indic scripts and
    /// ZWJ emoji sequences).
    public static func sanitize(_ text: String, removing findings: [Finding]) -> String {
        guard !findings.isEmpty else { return text }
        let sorted = findings.sorted { $0.range.lowerBound > $1.range.lowerBound }
        var result = text
        for finding in sorted {
            result.removeSubrange(finding.range)
        }
        return result
    }

    // MARK: - Classifiers

    private static func isUnicodeTag(_ s: Unicode.Scalar) -> Bool {
        (0xE0000...0xE007F).contains(s.value)
    }

    /// Only U+200B (Zero-Width Space) and U+200C (Zero-Width Non-Joiner) — these are
    /// the two scalars used in the paper's binary encoding scheme. U+200D (ZWJ) is
    /// excluded because it is heavily used in legitimate emoji sequences.
    private static func isBinaryZeroWidth(_ s: Unicode.Scalar) -> Bool {
        s.value == 0x200B || s.value == 0x200C
    }

    private static func isBidiOverride(_ s: Unicode.Scalar) -> Bool {
        (0x202A...0x202E).contains(s.value) || (0x2066...0x2069).contains(s.value)
    }

    private static func otherInvisibleLabel(_ s: Unicode.Scalar) -> String? {
        switch s.value {
        case 0x2060: return "Word Joiner"
        case 0xFEFF: return "Zero-Width No-Break Space (BOM)"
        case 0x00AD: return "Soft Hyphen"
        case 0x180E: return "Mongolian Vowel Separator"
        case 0x2061: return "Function Application"
        case 0x2062: return "Invisible Times"
        case 0x2063: return "Invisible Separator"
        case 0x2064: return "Invisible Plus"
        default: return nil
        }
    }

    private static func bidiOverrideName(_ s: Unicode.Scalar) -> String {
        switch s.value {
        case 0x202A: return "Left-to-Right Embedding"
        case 0x202B: return "Right-to-Left Embedding"
        case 0x202C: return "Pop Directional Formatting"
        case 0x202D: return "Left-to-Right Override"
        case 0x202E: return "Right-to-Left Override"
        case 0x2066: return "Left-to-Right Isolate"
        case 0x2067: return "Right-to-Left Isolate"
        case 0x2068: return "First Strong Isolate"
        case 0x2069: return "Pop Directional Isolate"
        default: return "Bidi control"
        }
    }

    // MARK: - Helpers

    private static func collectRun(
        from start: String.UnicodeScalarView.Index,
        in scalars: String.UnicodeScalarView,
        where predicate: (Unicode.Scalar) -> Bool
    ) -> (end: String.UnicodeScalarView.Index, codepoints: [UInt32]) {
        var codepoints: [UInt32] = []
        var i = start
        while i < scalars.endIndex, predicate(scalars[i]) {
            codepoints.append(scalars[i].value)
            i = scalars.index(after: i)
        }
        return (i, codepoints)
    }
}
