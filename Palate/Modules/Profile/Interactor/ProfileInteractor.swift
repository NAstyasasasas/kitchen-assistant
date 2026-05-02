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
    private let userService = UserService.shared
    private let authService = AuthService.shared
    
    func getUserStats() async throws -> (cooked: Int, wantToCook: Int, custom: Int) {
        guard let userId = await authService.getCurrentUser()?.id else {
            return (0, 0, 0)
        }
        
        let userRecipes = try await userService.fetchUserRecipes(userId: userId, status: nil)
        let cooked = userRecipes.filter { $0.status == "cooked" }.count
        let wantToCook = userRecipes.filter { $0.status == "wantToCook" }.count
        let custom = 0 // позже
        
        return (cooked, wantToCook, custom)
    }
    
    func signOut() throws {
        try authService.signOut()
    }
    
    var currentUser: AppUser? {
        authService.getCurrentUser()
    }
}
