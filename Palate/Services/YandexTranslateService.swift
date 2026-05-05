//
//  YandexTranslateService.swift
//  Palate
//

import Foundation

actor YandexTranslateService {
    static let shared = YandexTranslateService()
    
    private let apiKey = ProcessInfo.processInfo.environment["YANDEX_API_KEY"] ?? ""
    
    private init() {}
    
    func translate(text: String, from sourceLang: String = "en", to targetLang: String) async throws -> String {
        guard !text.isEmpty else { return text }
        
        let url = URL(string: "https://translate.api.cloud.yandex.net/translate/v2/translate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Api-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "sourceLanguageCode": sourceLang,
            "targetLanguageCode": targetLang,
            "texts": [text]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(YandexTranslationResponse.self, from: data)
        return response.translations.first?.text ?? text
    }
    
    func translateIfNeeded(_ text: String, sourceLang: String = "en") async -> String {
        guard !text.isEmpty else { return text }

        let targetLang = LanguageManager.shared.appLanguage.rawValue

        guard targetLang != sourceLang else { return text }

        do {
            return try await translate(text: text, from: sourceLang, to: targetLang)
        } catch {
            print("❌ Translation error: \(error)")
            return text
        }
    }
}

struct YandexTranslationResponse: Decodable {
    let translations: [Translation]
    struct Translation: Decodable {
        let text: String
    }
}
