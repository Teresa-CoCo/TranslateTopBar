# TranslateTopBar

TranslateTopBar is a macOS-only SwiftUI app that lives in the menu bar for quick Chinese ↔ English translations using OpenRouter models. A dock-accessible main window provides history, settings, and JSON export/import.

## Features
- Menu bar popover for instant translations with language direction control and model selection.
- Model list fetch from OpenRouter with caching and manual model entry support.
- Persistent history with search, per-item copy/delete, and clear-all.
- Settings for API key management, default model/direction, and auto-copy behavior.
- JSON export/import for settings and history.

## Repository layout
- `Package.swift`: Swift Package manifest (macOS 13+, executable target)
- `Sources/`: SwiftUI app source code
  - `App/`: app lifecycle, menu bar controller
  - `Networking/`: OpenRouter client and translation direction definitions
  - `Persistence/`: settings, history, model cache, and export/import helpers
  - `Views/`: SwiftUI views for the popover and main window
  - `Resources/`: Info.plist for bundle metadata
- `BUILD.md`: build and run instructions for Xcode

## Quick start
1. Open `TranslateTopBar.xcodeproj` (or the Swift package) in Xcode 15+ on macOS 13+.
2. Set the `OPENROUTER_API_KEY` in Settings or Keychain during first launch.
3. Run the app; a menu bar icon will appear with the translation popover.
