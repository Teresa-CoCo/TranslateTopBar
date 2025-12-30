#if os(macOS)
import Foundation

struct ModelDescriptor: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let contextLength: Int?
    let description: String?
}

struct TranslationResult: Codable {
    let translatedText: String
    let modelId: String
    let latency: TimeInterval?
}

enum TranslationDirection: String, Codable, CaseIterable, Identifiable {
    case auto
    case zhToEn
    case enToZh

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .zhToEn: return "ZH → EN"
        case .enToZh: return "EN → ZH"
        }
    }
}

final class OpenRouterClient: ObservableObject {
    private let baseURL = URL(string: "https://openrouter.ai/api/v1")!
    private let session: URLSession

    @Published var isTranslating = false
    @Published var lastError: String?

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration)
    }

    func translate(
        text: String,
        direction: TranslationDirection,
        model: String,
        apiKey: String
    ) async throws -> TranslationResult {
        lastError = nil
        isTranslating = true
        defer { isTranslating = false }

        var request = URLRequest(url: baseURL.appending(path: "chat/completions"))
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let languageInstruction: String
        switch direction {
        case .auto:
            languageInstruction = "Detect source language (Chinese or English) and translate to the other."
        case .zhToEn:
            languageInstruction = "Translate Chinese to English."
        case .enToZh:
            languageInstruction = "Translate English to Chinese."
        }

        let prompt = """
        \(languageInstruction)
        Return only the translated text. Preserve punctuation and formatting.
        Source: \(text)
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a precise translation engine."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let start = Date()
        let (data, response) = try await session.data(for: request)
        let latency = Date().timeIntervalSince(start)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            let apiError = String(data: data, encoding: .utf8) ?? "Unknown error"
            lastError = apiError
            throw NSError(domain: "OpenRouter", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: apiError])
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        let translated = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return TranslationResult(translatedText: translated, modelId: decoded.model, latency: latency)
    }

    func fetchModels(apiKey: String) async throws -> [ModelDescriptor] {
        lastError = nil
        var request = URLRequest(url: baseURL.appending(path: "models"))
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            let apiError = String(data: data, encoding: .utf8) ?? "Unknown error"
            lastError = apiError
            throw NSError(domain: "OpenRouter", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: apiError])
        }
        let decoded = try JSONDecoder().decode(OpenRouterModelsResponse.self, from: data)
        return decoded.data.map {
            ModelDescriptor(
                id: $0.id,
                name: $0.id,
                contextLength: $0.contextLength,
                description: $0.description
            )
        }
    }
}

private struct OpenRouterResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let index: Int
        let message: Message
        let finishReason: String?
    }

    let id: String
    let choices: [Choice]
    let model: String
}

private struct OpenRouterModelsResponse: Codable {
    struct Model: Codable {
        let id: String
        let description: String?
        let contextLength: Int?
    }

    let data: [Model]
}
#endif
