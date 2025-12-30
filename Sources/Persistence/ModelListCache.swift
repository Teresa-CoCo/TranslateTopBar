#if os(macOS)
import Foundation

@MainActor
final class ModelListCache: ObservableObject {
    @Published var models: [ModelDescriptor] = []
    @Published var lastUpdated: Date?

    private let cacheURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = directory.appendingPathComponent("TranslateTopBar", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        cacheURL = folder.appendingPathComponent("models.json")
        load()
    }

    func save(models: [ModelDescriptor]) {
        self.models = models
        lastUpdated = Date()
        persist()
    }

    private func persist() {
        do {
            let payload = CachedModels(models: models, lastUpdated: lastUpdated)
            let data = try encoder.encode(payload)
            try data.write(to: cacheURL, options: [.atomic])
        } catch {
            print("Model cache save error: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return }
        do {
            let data = try Data(contentsOf: cacheURL)
            let payload = try decoder.decode(CachedModels.self, from: data)
            models = payload.models
            lastUpdated = payload.lastUpdated
        } catch {
            print("Model cache load error: \(error)")
        }
    }
}

private struct CachedModels: Codable {
    let models: [ModelDescriptor]
    let lastUpdated: Date?
}
#endif
