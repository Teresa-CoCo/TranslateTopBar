#if os(macOS)
import Foundation
import Security

struct Settings: Codable {
    var defaultModel: String
    var languageDirection: TranslationDirection
    var autoCopyResult: Bool
    var lastUsedModel: String?
    var schemaVersion: Int = 1
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var settings: Settings
    @Published var apiKey: String

    private let defaults = UserDefaults.standard
    private let settingsKey = "TranslateTopBar.settings"
    private let apiKeyAccount = "TranslateTopBar.openrouter.apiKey"

    init() {
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(Settings.self, from: data) {
            settings = decoded
        } else {
            settings = Settings(defaultModel: "", languageDirection: .auto, autoCopyResult: false, lastUsedModel: nil)
        }
        apiKey = KeychainHelper.shared.read(service: apiKeyAccount) ?? ""
    }

    func update(_ block: (inout Settings) -> Void) {
        block(&settings)
        persist()
    }

    func persist() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
        if !apiKey.isEmpty {
            KeychainHelper.shared.save(apiKey, service: apiKeyAccount)
        }
    }

    func clearAPIKey() {
        apiKey = ""
        KeychainHelper.shared.delete(service: apiKeyAccount)
    }
}

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func save(_ value: String, service: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func read(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}
#endif
