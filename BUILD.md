# Build & Run Guide

## Requirements
- **Minimum macOS**: 13.0 (Ventura)
- **Recommended macOS**: 14+
- **Xcode**: 15.0 or later with Swift 5.9 toolchain
- **Supported architectures**: Apple Silicon (arm64) and Intel (x86_64)

## Project layout
- The Swift package lives at the repository root and targets macOS-only SwiftUI/AppKit APIs.
- An Xcode project file is provided at `TranslateTopBar.xcodeproj`. Xcode can also open the Swift Package directly if preferred.

## Configure the OpenRouter API key
Two approaches are supported:
1. **In-app Settings (recommended)**: Launch the app and paste your API key into *Settings → OpenRouter → API Key*, then press **Save Key**. The key is stored in the user Keychain.
2. **Environment variable (for Debug runs)**: In Xcode, edit the scheme → *Run* → *Arguments* and add `OPENROUTER_API_KEY=<your key>` to *Environment Variables*. The Settings view will read this value on first launch and allow you to persist it.

## Build & Run (Debug)
1. Open `TranslateTopBar.xcodeproj` in Xcode 15+.
2. Select the **TranslateTopBarApp** scheme.
3. Ensure the target device is **My Mac (Designed for macOS)**.
4. Press **⌘R** to build and run. The menu bar icon appears; click it to open the translation popover. The Dock icon opens the main window.

## Archive & Export (Release)
1. In Xcode, switch the scheme’s Build Configuration to **Release**.
2. Choose **Product → Archive**. Once the archive finishes, the Organizer window opens.
3. In Organizer, select the archive and click **Distribute App → Developer ID** (or **App Store** if applicable).
4. Follow the signing prompts. Export the signed `.app` or `.pkg` installer.

## Installation flow
1. Drag the signed `TranslateTopBar.app` into `/Applications`.
2. On first launch, grant any requested permissions (e.g., network access is implicit; no extra prompts expected).
3. Enter your OpenRouter API key in Settings. The menu bar icon appears automatically.

## Local data storage
- **Settings**: `UserDefaults` (non-sensitive) in `~/Library/Preferences` plus API key in **Keychain** under the service name `TranslateTopBar.openrouter.apiKey`.
- **History**: JSON file at `~/Library/Application Support/TranslateTopBar/history.json`.
- **Model cache**: `~/Library/Caches/TranslateTopBar/models.json`.
- **Exports**: User-selected path from the save panel.

## Permissions / Entitlements
- Network access only; no additional sandbox entitlements are required beyond the default macOS app capabilities.

## Troubleshooting
- **Popover does not show**: ensure the app is running (menu bar icon visible). Quit and relaunch if necessary.
- **Model list fetch fails**: verify connectivity and API key validity; manual model entry remains available.
- **Signing issues**: confirm your Apple Developer certificate is installed and selected during the archive export.
