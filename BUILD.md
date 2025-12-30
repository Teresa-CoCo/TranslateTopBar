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

### 配置代码签名（必须）
Archive 前必须先配置签名，否则会遇到 `code object is not signed at all` 错误：

1. **在 Xcode 中打开项目**
2. **选择项目和 Target**：
   - 左侧导航器点击 TranslateTopBar 项目（蓝色图标）
   - 在中间面板选择 **TranslateTopBarApp** target
3. **配置 Signing & Capabilities**：
   - 点击 **Signing & Capabilities** 标签
   - 勾选 **Automatically manage signing**
   - **Team**：选择你的 Apple ID 或开发团队
     - 如果没有选项，点击 **Add Account** 登录 Apple ID
     - 个人开发者账号也可以用于本地签名
   - Bundle Identifier 保持 `com.example.TranslateTopBar` 或改为你自己的

### 创建 Archive
1. 确认 scheme 的 Build Configuration 是 **Release**
2. 选择 **Product → Archive**
3. Archive 成功后，Organizer 窗口会打开

### 导出应用

#### 方法 1：Copy App（推荐，适用于免费 Apple ID）
1. 在 Organizer 中选择 archive
2. 点击 **Distribute App**
3. 选择 **Copy App**
4. 点击 **Export**，选择保存位置
5. 导出的文件夹中直接包含 `TranslateTopBarApp.app`

#### 方法 2：直接从 Archive 提取（无需导出）
1. 在 Organizer 中右键点击 archive
2. 选择 **Show in Finder**
3. 右键点击 `.xcarchive` 文件 → **显示包内容**
4. 进入 `Products/Applications/`
5. 复制 `TranslateTopBarApp.app` 到需要的位置

#### 方法 3：付费开发者账号的选项
如果你有付费的 Apple Developer 账号，可以选择：
   - **Developer ID**：用于在 Mac App Store 外分发
   - **App Store Connect**：提交到 Mac App Store

> **注意**：免费 Apple ID（Personal Team）只能用于本地开发和测试，使用 **Copy App** 或直接从 Archive 提取即可。
## Creating a DMG for Distribution
After exporting the `.app` bundle, create a DMG file for easy distribution:

### Method 1: Using hdiutil (built-in)
```bash
# Navigate to the directory containing your exported .app
cd /path/to/exported/app

# Create a DMG with compression
hdiutil create -volname "TranslateTopBar" \
  -srcfolder TranslateTopBarApp.app \
  -ov -format UDZO \
  TranslateTopBar-1.0.dmg
```

### Method 2: Using create-dmg (recommended for polished installers)
```bash
# Install create-dmg via Homebrew
brew install create-dmg

### "Personal Team is not enrolled in the Apple Developer Program"
- **错误信息**：在导出时提示未注册开发者计划
- **原因**：使用免费 Apple ID，尝试用 Development 方式导出
- **解决方法**：
  - 使用 **Copy App** 导出方式（见上面"导出应用"部分）
  - 或直接从 Archive 中提取 .app 文件
  - 免费账号签名的 app 可以在本地运行和测试# Create a DMG with custom layout and Application folder link
create-dmg \
  --代码签名失败：`code object is not signed at all`
- **错误信息**：`Command CodeSign failed with a nonzero exit code`
- **原因**：没有配置 Development Team 或签名设置
- **解决方法**：
  1. 在 Xcode 中选择项目 → TranslateTopBarApp target
  2. 点击 **Signing & Capabilities** 标签
  3. 勾选 **Automatically manage signing**
  4. 在 **Team** 下拉菜单中：
     - 如果没有看到任何选项，点击下拉菜单 → **Add Account** → 登录 Apple ID
     - 选择你的 Apple ID（即使是免费账号也可以用于本地开发）
  5. Clean Build Folder: **⇧⌘K**
  6. 重新 Archive

### volname "TranslateTopBar" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "TranslateTopBarApp.app" 175 120 \
  --app-drop-link 425 120 \
  "TranslateTopBar-1.0.dmg" \
  "TranslateTopBarApp.app"
```
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

### Archive produces Unix executable instead of .app
- **症状**：Archive 后导出的文件夹为空或只有可执行文件
- **原因**：Xcode 使用了 Package.swift 而不是 .xcodeproj
- **解决方法**：
  1. 在 Xcode 中，**关闭项目**
  2. 双击打开 `TranslateTopBar.xcodeproj`（不是 Package.swift）
  3. 在 Xcode 左上角确认显示的是 **TranslateTopBarApp** scheme
  4. 检查 Build Settings:
     - 在项目导航器中选择 TranslateTopBar 项目
     - 选择 TranslateTopBarApp target
     - Build Settings → Product Name 应该是 `$(TARGET_NAME)`
     - Build Settings → Info.plist File 应该指向 `Sources/Resources/Info.plist`
  5. Clean Build Folder: **⇧⌘K**
  6. 重新 Archive: **Product → Archive**

### Export 导出的文件夹为空
- **检查签名配置**：
  - Xcode → Settings → Accounts → 确认已登录 Apple ID
  - 在 Signing & Capabilities tab 中选择正确的 Team
- **导出方式选择**：
  - 对于测试：选择 **Development** 或 **Copy App**
  - 对于分发：选择 **Developer ID** 或 **App Store Connect**
- **验证 Archive**：
  - 在 Organizer 中右键 archive → Show in Finder
  - 右键 .xcarchive → Show Package Contents
  - 应该能看到 `Products/Applications/TranslateTopBarApp.app`
  - 如果这个文件存在，Archive 是成功的，问题出在导出步骤

### 快速测试构建是否正确
在终端运行：
```bash
cd /Users/teresa/develop/TranslateTopBar
xcodebuild -project TranslateTopBar.xcodeproj \
  -scheme TranslateTopBarApp \
  -configuration Release \
  clean build
```
构建成功后，在 `~/Library/Developer/Xcode/DerivedData/TranslateTopBar-*/Build/Products/Release/` 应该能找到 `TranslateTopBarApp.app`

### 其他常见问题
- **Popover does not show**: ensure the app is running (menu bar icon visible). Quit and relaunch if necessary.
- **Model list fetch fails**: verify connectivity and API key validity; manual model entry remains available.
