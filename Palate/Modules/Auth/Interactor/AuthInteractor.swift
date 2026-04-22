//
//  AuthInteractor.swift
//  Palate
//

import Foundation

protocol AuthInteractorProtocol {
    func register(email: String, password: String, confirmPassword: String, displayName: String) async throws -> AppUser
    func login(email: String, password: String) async throws -> AppUser
    func signOut() throws
    func isAuthenticated() async -> Bool
    func getCurrentUser() async -> AppUser?
}

final class AuthInteractor: AuthInteractorProtocol {
    private let authService = AuthService.shared
    
    func register(email: String, password: String, confirmPassword: String, displayName: String) async throws -> AppUser {
        return try await authService.register(email: email, password: password, confirmPassword: confirmPassword, displayName: displayName)
    }
    
    func login(email: String, password: String) async throws -> AppUser {
        return try await authService.login(email: email, password: password)
    }
    
    func signOut() throws {
        try authService.signOut()
    }
    
    func isAuthenticated() async -> Bool {
        await authService.getIsAuthenticated()
    }
        
    func getCurrentUser() async -> AppUser? {
        await authService.getCurrentUser()
    }
}
