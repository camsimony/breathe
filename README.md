# Breathe

macOS menu bar app for guided box breathing with an optional Dynamic Island / notch overlay.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16+ (to build from source)

## Build from source

```bash
git clone https://github.com/camsimony/breathe.git
cd breathe
open Breathe.xcodeproj
```

Select the **Breathe** scheme, then **Product → Run**.

### Regenerate the Xcode project (maintainers)

The repo includes `project.yml` for [XcodeGen](https://github.com/yonaskolb/XcodeGen). After changing targets, schemes, or file structure in `project.yml`, regenerate:

```bash
brew install xcodegen   # once
xcodegen generate
```

Commit the updated `Breathe.xcodeproj` so contributors can open the project without XcodeGen.

## Test

```bash
xcodebuild test -project "Breathe.xcodeproj" -scheme "Breathe" -destination "platform=macOS"
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Release builds (maintainers)

If you ship signed or notarized builds, see [docs/releasing.md](docs/releasing.md) for a starting checklist.

## License

MIT — see [LICENSE](LICENSE).
