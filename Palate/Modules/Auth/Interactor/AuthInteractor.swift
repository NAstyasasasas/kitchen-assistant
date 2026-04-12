//
//  AuthInteractor.swift
//  Palate
//

import Foundation

protocol AuthInteractorProtocol {
    func register(email: String, password: String, confirmPassword: String, displayName: String) async throws -> AppUser
    func login(email: String, password: String) async throws -> AppUser
    func signOut() throws
    var isAuthenticated: Bool { get }
    var currentUser: AppUser? { get }
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
    
    var isAuthenticated: Bool {
        authService.isAuthenticated
    }
    
    var currentUser: AppUser? {
        authService.currentUser
    }
}
