import Foundation
import Combine

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case russian = "ru"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        }
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    let objectWillChange = ObservableObjectPublisher()

    private var bundle: Bundle?

    var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
            bundle = Self.createBundle(for: currentLanguage)
            objectWillChange.send()
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage")
        let system = Locale.preferredLanguages.first ?? "en"
        currentLanguage = saved ?? system
        bundle = Self.createBundle(for: currentLanguage)
    }

    static func createBundle(for language: String) -> Bundle? {
        let code = language.hasPrefix("ru") ? "ru" : "en"

        guard let path = Bundle.main.path(forResource: code, ofType: "lproj") else {
            return nil
        }

        return Bundle(path: path)
    }

    func localized(_ key: String) -> String {
        bundle?.localizedString(forKey: key, value: nil, table: nil)
        ?? NSLocalizedString(key, comment: "")
    }

    var appLanguage: AppLanguage {
        get {
            currentLanguage.hasPrefix("ru") ? .russian : .english
        }
        set {
            currentLanguage = newValue.rawValue
        }
    }

    var isRussian: Bool {
        appLanguage == .russian
    }
    func lookupTranslation(
        forKey key: String,
        inTable table: String,
        fallbackValue: String
    ) -> String {
        bundle?.localizedString(forKey: key, value: fallbackValue, table: table)
        ?? Bundle.main.localizedString(forKey: key, value: fallbackValue, table: table)
    }
}
