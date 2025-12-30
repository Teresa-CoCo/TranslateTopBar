#if os(macOS)
import Foundation

struct HistoryEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let sourceText: String
    let translatedText: String
    let direction: TranslationDirection
    let model: String
    let latency: TimeInterval?
    let tokenUsage: Int?

    init(id: UUID = UUID(), timestamp: Date = .init(), sourceText: String, translatedText: String, direction: TranslationDirection, model: String, latency: TimeInterval? = nil, tokenUsage: Int? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.direction = direction
        self.model = model
        self.latency = latency
        self.tokenUsage = tokenUsage
    }
}

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = directory.appendingPathComponent("TranslateTopBar", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        self.fileURL = folder.appendingPathComponent("history.json")
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        load()
    }

    func append(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(_ entry: HistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    func search(query: String) -> [HistoryEntry] {
        guard !query.isEmpty else { return entries }
        return entries.filter { $0.sourceText.localizedCaseInsensitiveContains(query) || $0.translatedText.localizedCaseInsensitiveContains(query) }
    }

    func replaceAll(with newEntries: [HistoryEntry]) {
        entries = newEntries
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            entries = try decoder.decode([HistoryEntry].self, from: data)
        } catch {
            print("History load error: \(error)")
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(entries)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("History save error: \(error)")
        }
    }
}
#endif
