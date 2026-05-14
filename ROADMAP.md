# Roadmap

Tracking work that is intentionally deferred from the v0.1 release.

## v0.2 candidates

- **Custom app icon** — currently uses SF Symbols (`magnifyingglass` idle, severity-tinted warning symbols when alerted). Generate a real app icon via a `Tools/generate-icon.swift` renderer (jubako pattern).
- **Detection rule extension** — flag visible prompt-boundary tokens as `info` severity:
  - `<|im_start|>`, `<|im_end|>`, `<|system|>` (OpenAI / Llama style)
  - `[INST]`, `[/INST]` (Mistral)
  - `<system>`, `</system>`, `<instructions>`
  Decide whether to ship as a separate severity tier or behind a toggle (false positives are likely on plain prose).
- **Allowlist for benign invisible runs** — Indic scripts and certain ZW patterns can be legitimately heavy on zero-width chars; consider opt-in suppression.

## Phase 4: Signed distribution via Homebrew Cask

Infrastructure is **in place** (`.github/workflows/`, `RELEASE.md`, repo is public).
Remaining work is operator action, not code:

1. Add the 7 repository secrets to `snaka/invixray` — see [RELEASE.md](RELEASE.md)
2. (Recommended) trigger a `workflow_dispatch` dry-run to validate signing/notarization
3. Cut `v0.1.1` (annotated tag) → full pipeline runs → Release + `Casks/invixray.rb` lands in `snaka/homebrew-tap`

## Documentation

- README: add a screenshot / GIF of the popover triggering on a malicious paste
- `DESIGN.md` — architecture write-up + the detection rules' derivation from Graves (2026)

## Under consideration

- Detection history log accessible from the popover
- Sanitize behavior options: notification-only / manual / auto-replace (currently manual via "Copy Sanitized")
- Login Items registration UI (so the menu bar app launches at login)
- A separate `Settings` window (currently `EmptyView` to satisfy the `App` protocol; never shown)
