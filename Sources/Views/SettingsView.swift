#if os(macOS)
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var modelCache: ModelListCache
    @EnvironmentObject private var openRouterClient: OpenRouterClient
    @EnvironmentObject private var historyStore: HistoryStore

    @State private var selectedDirection: TranslationDirection = .auto
    @State private var defaultModel: String = ""
    @State private var message: String = ""

    private let exportImportManager = ExportImportManager()

    var body: some View {
        Form {
            Section("OpenRouter") {
                SecureField("API Key", text: $settingsStore.apiKey)
                    .onSubmit { settingsStore.persist() }
                HStack {
                    Button("Save Key") { settingsStore.persist() }
                    Button("Clear Key", role: .destructive) { settingsStore.clearAPIKey() }
                }
                Picker("Default Direction", selection: $selectedDirection) {
                    ForEach(TranslationDirection.allCases) { direction in
                        Text(direction.displayName).tag(direction)
                    }
                }
                TextField("Default Model", text: $defaultModel)
                Button("Refresh Model List") { fetchModels() }
                if let updated = modelCache.lastUpdated {
                    Text("Cached models: \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Behavior") {
                Toggle("Automatically copy translation", isOn: $settingsStore.settings.autoCopyResult)
                    .onChange(of: settingsStore.settings.autoCopyResult) { _ in settingsStore.persist() }
            }

            Section("Export / Import") {
                HStack {
                    Button("Export Settings + History") { exportData() }
                    Button("Import JSON") { importData() }
                }
                if !message.isEmpty {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .onAppear {
            selectedDirection = settingsStore.settings.languageDirection
            defaultModel = settingsStore.settings.defaultModel
        }
        .onChange(of: selectedDirection) { newValue in
            settingsStore.update { $0.languageDirection = newValue }
        }
        .onChange(of: defaultModel) { newValue in
            settingsStore.update { $0.defaultModel = newValue }
        }
    }

    private func fetchModels() {
        guard !settingsStore.apiKey.isEmpty else {
            message = "Add your API key first"
            return
        }
        Task {
            do {
                let models = try await openRouterClient.fetchModels(apiKey: settingsStore.apiKey)
                await MainActor.run {
                    modelCache.save(models: models)
                    message = "Loaded \(models.count) models"
                }
            } catch {
                await MainActor.run {
                    message = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func exportData() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "TranslateTopBar-Export.json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try exportImportManager.exportData(settings: settingsStore.settings, history: historyStore.entries, to: url)
                message = "Exported to \(url.lastPathComponent)"
            } catch {
                message = "Export failed: \(error.localizedDescription)"
            }
        }
    }

    private func importData() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let payload = try exportImportManager.importData(from: url)
                settingsStore.settings = payload.settings
                settingsStore.persist()
                historyStore.replaceAll(with: payload.history)
                message = "Import complete"
            } catch {
                message = "Import failed: \(error.localizedDescription)"
            }
        }
    }
}
#endif
