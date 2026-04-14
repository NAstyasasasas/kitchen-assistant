//
//  RecipeDetailInteractor.swift
//  Palate
//

import Foundation

protocol RecipeDetailInteractorProtocol {
    func fetchRecipeDetail(id: String) async throws -> Recipe
    func addToWantToCook(recipeId: String) async throws
    func markAsCooked(recipeId: String) async throws
    func checkRecipeStatus(recipeId: String) async throws -> (wantToCook: Bool, cooked: Bool)
}

final class RecipeDetailInteractor: RecipeDetailInteractorProtocol {
    private let apiService = APIService.shared
    private let firebaseService = FirebaseService.shared
    private let authService = AuthService.shared
    
    func fetchRecipeDetail(id: String) async throws -> Recipe {
        return try await apiService.fetchRecipeDetail(id: id)
    }
    
    func addToWantToCook(recipeId: String) async throws {
        guard let userId = authService.currentUser?.id else {
            throw AuthError.networkError
        }
        
        let userRecipe = UserRecipe(
            userId: userId,
            recipeId: recipeId,
            recipeSource: .mealDB,
            status: .wantToCook
        )
        
        try await firebaseService.saveUserRecipe(userRecipe)
    }
    
    func markAsCooked(recipeId: String) async throws {
        try await firebaseService.updateRecipeStatus(recipeId: recipeId, newStatus: .cooked)
    }
    
    func checkRecipeStatus(recipeId: String) async throws -> (wantToCook: Bool, cooked: Bool) {
        guard let userId = authService.currentUser?.id else {
            return (false, false)
        }
        
        let userRecipes = try await firebaseService.getUserRecipes(status: nil)
        let wantToCook = userRecipes.contains { $0.recipeId == recipeId && $0.status == .wantToCook }
        let cooked = userRecipes.contains { $0.recipeId == recipeId && $0.status == .cooked }
        
        return (wantToCook, cooked)
    }
}
