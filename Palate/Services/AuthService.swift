//
//  AuthService.swift
//  Palate
//

import Foundation
import FirebaseAuth

class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    
    private init() {}
    
    func login(email: String, password: String) async throws -> AppUser {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            return AppUser(from: result.user)
        } catch {
            throw AuthError.invalidCredentials
        }
    }
    
    func register(email: String, password: String, confirmPassword: String, displayName: String) async throws -> AppUser {
        guard password == confirmPassword else {
            throw AuthError.passwordsDontMatch
        }
        
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            return AppUser(from: result.user)
        } catch let error as NSError {
            if error.code == 17007 {
                throw AuthError.emailAlreadyInUse
            }
            throw AuthError.networkError
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    var currentUser: AppUser? {
        guard let user = auth.currentUser else { return nil }
        return AppUser(from: user)
    }
    
    var isAuthenticated: Bool {
        return auth.currentUser != nil
    }
}
