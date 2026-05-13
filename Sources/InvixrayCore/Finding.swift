import Foundation

public struct Finding: Equatable, Sendable, Hashable {
    public enum Severity: String, Sendable, Comparable, CaseIterable {
        case critical
        case high
        case warn

        private var rank: Int {
            switch self {
            case .critical: return 0
            case .high: return 1
            case .warn: return 2
            }
        }

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rank < rhs.rank
        }
    }

    public enum Kind: String, Sendable, Hashable {
        case unicodeTag
        case zeroWidthBinary
        case bidiOverride
        case otherInvisible
    }

    public let kind: Kind
    public let severity: Severity
    public let range: Range<String.Index>
    public let codepoints: [UInt32]
    public let label: String

    public init(
        kind: Kind,
        severity: Severity,
        range: Range<String.Index>,
        codepoints: [UInt32],
        label: String
    ) {
        self.kind = kind
        self.severity = severity
        self.range = range
        self.codepoints = codepoints
        self.label = label
    }
}
