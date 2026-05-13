# Invixray

> **Invi**sible + X-**ray** — a macOS menu bar app that watches your clipboard for invisible Unicode characters used in LLM prompt-injection attacks.

## What it detects

Clipboard text is scanned every time it changes. Findings are reported with a severity:

| Severity | What | Why it matters |
|----------|------|----------------|
| 🔴 Critical | Unicode Tag characters (U+E0000 – U+E007F) | Invisible to humans, decoded by LLM tokenizers as instructions. Almost never legitimate. |
| 🟠 High | Long runs (≥ 8) of Zero-Width characters (U+200B, U+200C) | Pattern used to encode binary-packed hidden instructions. |
| 🟡 Warn | Bidi overrides (U+202A–202E, U+2066–2069), Word Joiner (U+2060), BOM (U+FEFF), Soft Hyphen (U+00AD) | Context-dependent. Can hide or reorder visible text. |

Detection rules are based on [Graves, 2026 — *Reverse CAPTCHA: Evaluating LLM Susceptibility to Invisible Unicode Instruction Injection*](https://arxiv.org/html/2603.00164v1).

## Status

Early development. No release yet.

## Build

The Xcode project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen) and is gitignored — regenerate after pulling or editing `project.yml`.

```bash
xcodegen generate
open Invixray.xcodeproj
```

Or build from the command line (unsigned, for local debugging):

```bash
xcodebuild -project Invixray.xcodeproj -scheme Invixray -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

The pure-Swift detection module has unit tests:

```bash
swift test
```

## License

MIT — see [LICENSE](LICENSE).
