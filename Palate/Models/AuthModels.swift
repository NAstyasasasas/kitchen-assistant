//
//  AuthModels.swift
//  Palate
//

import Foundation
import FirebaseAuth

struct AppUser: Codable {
    let id: String
    let email: String
    let displayName: String?
    var avatarUrl: String?
    let createdAt: Date
    
    init(from firebaseUser: User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName
        self.createdAt = Date()
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case weakPassword
    case passwordsDontMatch
    case emailAlreadyInUse
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверный email или пароль"
        case .weakPassword:
            return "Пароль должен быть не менее 6 символов"
        case .passwordsDontMatch:
            return "Пароли не совпадают"
        case .emailAlreadyInUse:
            return "Email уже зарегистрирован"
        case .networkError:
            return "Ошибка сети"
        }
    }
}
