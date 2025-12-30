#if os(macOS)
import Foundation

struct ExportPayload: Codable {
    let schemaVersion: Int
    let settings: Settings
    let history: [HistoryEntry]
}

enum ExportImportError: Error {
    case invalidPayload
}

final class ExportImportManager {
    func exportData(settings: Settings, history: [HistoryEntry], to url: URL) throws {
        let payload = ExportPayload(schemaVersion: 1, settings: settings, history: history)
        let data = try JSONEncoder().encode(payload)
        try data.write(to: url, options: [.atomic])
    }

    func importData(from url: URL) throws -> ExportPayload {
        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder().decode(ExportPayload.self, from: data)
        guard payload.schemaVersion == 1 else {
            throw ExportImportError.invalidPayload
        }
        return payload
    }
}
#endif
