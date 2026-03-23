# Contributing

Thanks for helping improve Breathe.

## Getting started

1. Clone the repo and open `Breathe.xcodeproj` (see [README.md](README.md)).
2. Run the **Breathe** scheme locally before opening a PR.
3. Run tests:

   ```bash
   xcodebuild test -project "Breathe.xcodeproj" -scheme "Breathe" -destination "platform=macOS"
   ```

## Pull requests

- Keep changes focused on one concern when possible.
- If you change UI or timing, describe what you tested on which macOS version.
- CI runs `xcodebuild test` on pull requests; a green check is required before merge.

## Project layout

- `Breathe/` — app sources (SwiftUI, services, models).
- `BreatheTests/` — unit tests (`@testable import Breathe`).
- `project.yml` — XcodeGen spec; regenerate `Breathe.xcodeproj` with `xcodegen generate` when you change it.

## Code style

Match surrounding code (naming, spacing, SwiftUI patterns). No strict formatter is enforced yet.
