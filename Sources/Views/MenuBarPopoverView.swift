#if os(macOS)
import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var historyStore: HistoryStore
    @EnvironmentObject private var openRouterClient: OpenRouterClient
    @EnvironmentObject private var modelCache: ModelListCache

    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var direction: TranslationDirection = .auto
    @State private var selectedModel: String = ""
    @State private var isCopyFlashVisible = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Translate")
                    .font(.headline)
                Spacer()
                if openRouterClient.isTranslating {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            TextField("Type Chinese or English", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .focused($isInputFocused)
                .onAppear {
                    direction = settingsStore.settings.languageDirection
                    selectedModel = settingsStore.settings.lastUsedModel ?? settingsStore.settings.defaultModel
                    isInputFocused = true
                }

            HStack {
                Picker("Direction", selection: $direction) {
                    ForEach(TranslationDirection.allCases) { direction in
                        Text(direction.displayName).tag(direction)
                    }
                }
                .pickerStyle(.segmented)

                Button(action: swapDirection) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .help("Swap direction")
                .buttonStyle(.borderless)
            }

            VStack(alignment: .leading, spacing: 4) {
                Picker("Model", selection: $selectedModel) {
                    if selectedModel.isEmpty {
                        Text("Manual entry").tag("")
                    }
                    ForEach(modelCache.models) { model in
                        Text(model.name).tag(model.id)
                    }
                }
                .onAppear {
                    if modelCache.models.isEmpty, let key = optionalApiKey {
                        Task { await loadModels(apiKey: key) }
                    }
                }

                TextField("Or type model id", text: $selectedModel)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button(action: performTranslation) {
                    Label("Translate", systemImage: "arrow.right.circle.fill")
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(openRouterClient.isTranslating || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button(action: { inputText = ""; outputText = "" }) {
                    Label("Clear", systemImage: "xmark.circle")
                }
                Spacer()
                Button(action: copyOutput) {
                    Label(isCopyFlashVisible ? "Copied" : "Copy", systemImage: "doc.on.doc")
                }
                .disabled(outputText.isEmpty)
            }

            Divider()
            ScrollView {
                Text(outputText.isEmpty ? "Translation will appear here" : outputText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 80, maxHeight: 120)
        }
        .padding()
        .frame(width: 400)
    }

    private var optionalApiKey: String? {
        settingsStore.apiKey.isEmpty ? nil : settingsStore.apiKey
    }

    private func performTranslation() {
        guard let apiKey = optionalApiKey else {
            outputText = "Please set your OpenRouter API key in Settings"
            return
        }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Task {
            do {
                let result = try await openRouterClient.translate(
                    text: text,
                    direction: direction,
                    model: selectedModel.isEmpty ? settingsStore.settings.defaultModel : selectedModel,
                    apiKey: apiKey
                )
                await MainActor.run {
                    outputText = result.translatedText
                    settingsStore.update { settings in
                        settings.lastUsedModel = result.modelId
                    }
                    let entry = HistoryEntry(
                        sourceText: text,
                        translatedText: result.translatedText,
                        direction: direction,
                        model: result.modelId,
                        latency: result.latency,
                        tokenUsage: nil
                    )
                    historyStore.append(entry)
                    if settingsStore.settings.autoCopyResult {
                        copyOutput()
                    }
                }
            } catch {
                await MainActor.run {
                    outputText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func loadModels(apiKey: String) async {
        do {
            let models = try await openRouterClient.fetchModels(apiKey: apiKey)
            await MainActor.run {
                modelCache.save(models: models)
            }
        } catch {
            await MainActor.run {
                outputText = "Model list failed: \(error.localizedDescription)"
            }
        }
    }

    private func swapDirection() {
        switch direction {
        case .auto:
            direction = .zhToEn
        case .zhToEn:
            direction = .enToZh
        case .enToZh:
            direction = .zhToEn
        }
    }

    private func copyOutput() {
        guard !outputText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
        withAnimation(.easeInOut(duration: 0.15)) {
            isCopyFlashVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopyFlashVisible = false
            }
        }
    }
}
#endif
