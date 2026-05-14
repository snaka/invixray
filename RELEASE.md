# Releasing Invixray

The release pipeline lives in [`.github/workflows/release.yml`](.github/workflows/release.yml).
It signs, notarizes, packages a `.dmg`, publishes a GitHub Release, and bumps the
[`snaka/homebrew-tap`](https://github.com/snaka/homebrew-tap) formula.

## One-time setup

The Apple Developer assets are the **same account** used by `snaka/jubako` — you
can reuse the certificate, Team ID, and app-specific password. They still have to
be added as repository secrets on `snaka/invixray` (secrets are per-repo).

### 1. Apple Developer assets

- A **Developer ID Application** certificate, exported as a `.p12` from Keychain
  Access (right-click → Export) with a password.
- Your **Team ID** (10-char string, Apple Developer → Account → Membership).
- An **app-specific password** for `notarytool`
  ([appleid.apple.com](https://appleid.apple.com) → Sign-in and Security →
  App-Specific Passwords), e.g. labelled `invixray-notarytool`.

### 2. GitHub PAT for the tap

A **fine-grained personal access token** restricted to `snaka/homebrew-tap`
with `Contents: Read and write`. The token jubako uses is scoped to the same
tap repo — if it is still valid you can reuse the value.

### 3. Add repository secrets to `snaka/invixray`

`Settings → Secrets and variables → Actions → New repository secret`:

| Secret | Value |
|---|---|
| `DEVELOPER_ID_CERT_P12_BASE64` | `base64 -i cert.p12 \| pbcopy` and paste |
| `DEVELOPER_ID_CERT_PASSWORD` | The .p12 export password |
| `KEYCHAIN_PASSWORD` | Any random string (`openssl rand -hex 32`); only used for the temp keychain |
| `AC_USERNAME` | Your Apple ID email |
| `AC_PASSWORD` | The app-specific password from step 1 |
| `AC_TEAM_ID` | Your 10-char Team ID |
| `TAP_PUSH_TOKEN` | The fine-grained PAT from step 2 |

## Cutting a release

> The first signed release should be **v0.1.1** — `v0.1.0` already exists as the
> earlier unsigned manual zip.

### Dry-run (recommended before the first real tag)

Actions tab → **Release** → **Run workflow** → enter a version like `0.1.1-dryrun`.
This builds, signs, notarizes, and creates the `.dmg`, uploads it as a workflow
**artifact**, and **skips** the GitHub Release + tap bump. Use it to validate
signing/notarization without polluting Releases or the tap.

### Real release

```bash
git tag -a v0.1.1 -m "v0.1.1"
git push origin v0.1.1
```

(Tags must be annotated — the repo has `tag.gpgSign = true` globally; lightweight
tags fail to sign.)

The workflow will:

1. Resolve version from the tag (`v0.1.1` → `0.1.1`).
2. Build a Release archive with `MARKETING_VERSION=0.1.1`.
3. Sign with Developer ID and notarize the `.app`.
4. Build a `.dmg`, notarize and staple it.
5. Create a GitHub Release with auto-generated notes, attach the `.dmg`.
6. Push an updated `Casks/invixray.rb` to `snaka/homebrew-tap`.

After it succeeds, `brew install --cask snaka/tap/invixray` should work.

## Troubleshooting

- **`security: SecKeychainItemImport: error -25257`** — the `.p12` password in
  `DEVELOPER_ID_CERT_PASSWORD` is wrong.
- **`No identity found`** — the certificate didn't import cleanly. Verify the
  `.p12` contains both the cert and the private key.
- **Notarization rejected** — inspect with:
  ```bash
  xcrun notarytool log <submission-id> \
    --apple-id "$AC_USERNAME" --password "$AC_PASSWORD" --team-id "$AC_TEAM_ID"
  ```
  Common cause: missing hardened runtime, or signing with a non-Developer-ID
  identity. `ENABLE_HARDENED_RUNTIME` is already `YES` in `project.yml`.
- **Tap push fails with 403** — the PAT scope is wrong; it needs
  `Contents: Read and write` for `snaka/homebrew-tap`.
- **Package resolution errors in CI** — Invixray's SwiftPM packages are local
  (`path: .`) with no remote dependencies, so there is nothing to resolve. If
  `xcodebuild archive` complains, regenerate the project with `xcodegen generate`.

## Future migrations

- Replace `AC_USERNAME` / `AC_PASSWORD` with an App Store Connect API key for
  `notarytool` (`--key` / `--key-id` / `--issuer`) once the project is mature.
- Add a custom app icon before a v1.0 release — currently the `.app` uses a
  generic icon (see [ROADMAP.md](ROADMAP.md)).
