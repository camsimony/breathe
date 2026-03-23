# Releasing Breathe

Optional notes for maintainers who distribute signed macOS builds (similar in spirit to [port-menu’s releasing doc](https://github.com/wieandteduard/port-menu/blob/main/docs/releasing.md)).

## What this project does *not* include yet

There is no automated `release-macos.sh` or Sparkle appcast in this repo. Add those when you are ready to ship DMGs or auto-updates.

## Suggested first steps when you publish

1. **Archive** in Xcode (Release, `Breathe` scheme) or use `xcodebuild archive` with your signing settings.
2. **Notarize** with `notarytool` (store credentials in the Keychain; avoid committing secrets).
3. **Staple** the app and any DMG, then verify with `spctl` / `stapler validate` as in Apple’s documentation.
4. **GitHub Releases**: upload the stapled artifact and describe changes.

## Open source hygiene

- Tag versions (`v1.0.0`) to match release titles when possible.
- Keep `README.md` in sync if install or requirements change.
