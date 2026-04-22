//
//  ProfileInteractor.swift
//  Palate
//

import Foundation

protocol ProfileInteractorProtocol {
    func getUserStats() async throws -> (cooked: Int, wantToCook: Int, custom: Int)
    func signOut() throws
    var currentUser: AppUser? { get }
}

final class ProfileInteractor: ProfileInteractorProtocol {
    private let firebaseService = FirebaseService.shared
    private let authService = AuthService.shared
    
    func getUserStats() async throws -> (cooked: Int, wantToCook: Int, custom: Int) {
        let userRecipes = try await firebaseService.getUserRecipes(status: nil)
        let cooked = userRecipes.filter { $0.status == .cooked }.count
        let wantToCook = userRecipes.filter { $0.status == .wantToCook }.count
        let custom = 0
        
        return (cooked, wantToCook, custom)
    }
    
    func signOut() throws {
        try authService.signOut()
    }
    
    var currentUser: AppUser? {
        authService.getCurrentUser()
    }
}
