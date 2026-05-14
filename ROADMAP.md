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

## Phase 4: Signed distribution via Homebrew Cask (deferred)

The current v0.1.0 ships as an unsigned zip on a private GitHub Release. To match the jubako distribution pattern:

1. Register Apple Developer ID certificate + `notarytool` API key as GitHub Secrets
2. Port `.github/workflows/release.yml` from jubako (sign → notarize → staple → DMG → Release → Cask bump)
3. Add `.github/workflows/build.yml` for unsigned compile-only PR checks
4. Add a `RELEASE.md` operator runbook (jubako has one)
5. Open the repo to **Public**
6. Add `Casks/invixray.rb` to **snaka/homebrew-tap** so `brew install --cask snaka/tap/invixray` works
7. Cut `v0.x.0` tag → full pipeline runs

## Documentation

- README: add a screenshot / GIF of the popover triggering on a malicious paste
- `DESIGN.md` — architecture write-up + the detection rules' derivation from Graves (2026)

## Under consideration

- Detection history log accessible from the popover
- Sanitize behavior options: notification-only / manual / auto-replace (currently manual via "Copy Sanitized")
- Login Items registration UI (so the menu bar app launches at login)
- A separate `Settings` window (currently `EmptyView` to satisfy the `App` protocol; never shown)
