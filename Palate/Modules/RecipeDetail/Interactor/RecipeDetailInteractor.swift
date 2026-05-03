//
//  RecipeDetailInteractor.swift
//  Palate
//

import Foundation
import CoreData
import FirebaseAuth

protocol RecipeDetailInteractorProtocol {
    func fetchRecipeDetail(id: String, source: RecipeSource) async throws -> Recipe
    func addToWantToCook(recipeId: String) async throws
    func markAsCooked(recipeId: String) async throws
    func checkRecipeStatus(recipeId: String) async throws -> (wantToCook: Bool, cooked: Bool)
    func saveNotes(recipeId: String, notes: String) async throws
    func saveRating(recipeId: String, rating: Int) async throws
    
    
}

final class RecipeDetailInteractor: RecipeDetailInteractorProtocol {
    private let apiService = APIService.shared
    private let userService = UserService.shared
    private let authService = AuthService.shared
    private let coreData = CoreDataManager.shared
    
    func fetchRecipeDetail(id: String, source: RecipeSource = .mealDB) async throws -> Recipe {
        print("🔍 fetchRecipeDetail called with source: \(source), id: \(id)")
        if source == .custom {
            print("🔍 source: \(source), recipeId: \(id)")
            return try await fetchCustomRecipeDetail(recipeId: id)
        } else {
            print("⚠️ Using API path (mealDB)")
            return try await apiService.fetchRecipeDetail(id: id)
        }
    }
    
    func addToWantToCook(recipeId: String) async throws {
        guard let userId = await authService.getCurrentUser()?.id else {
            throw AuthError.networkError
        }
        
        let userRecipe = UserRecipe(context: coreData.viewContext)
        userRecipe.id = UUID()
        userRecipe.userId = userId
        userRecipe.recipeId = recipeId
        userRecipe.recipeSource = "mealDB"
        userRecipe.status = "wantToCook"
        userRecipe.dateAdded = Date()
        userRecipe.synced = false
        coreData.saveUserRecipe(userRecipe)
        
        do {
            try await userService.saveUserRecipe(userRecipe, userId: userId)
            userRecipe.synced = true
            coreData.saveContext()
        } catch {
            print("⚠️ Firebase save failed, will retry later: \(error)")
        }
    }
    
    func markAsCooked(recipeId: String) async throws {
        guard let userId = await authService.getCurrentUser()?.id else { return }
        
        coreData.updateUserRecipeStatus(recipeId: recipeId, status: "cooked", dateCooked: Date())
        
        do {
            try await userService.updateUserRecipeStatus(recipeId: recipeId, status: "cooked", dateCooked: Date())
        } catch {
            print("⚠️ Firebase update failed: \(error)")
        }
    }
    
    func checkRecipeStatus(recipeId: String) async throws -> (wantToCook: Bool, cooked: Bool) {
        guard let userId = await authService.getCurrentUser()?.id else {
            return (false, false)
        }
        
        let userRecipes = coreData.fetchUserRecipes(byUserId: userId)
        let wantToCook = userRecipes.contains { $0.recipeId == recipeId && $0.status == "wantToCook" }
        let cooked = userRecipes.contains { $0.recipeId == recipeId && $0.status == "cooked" }
        
        return (wantToCook, cooked)
    }
    
    func saveNotes(recipeId: String, notes: String) async throws {
        guard let userId = await authService.getCurrentUser()?.id else { return }
        
        let userRecipes = coreData.fetchUserRecipes(byUserId: userId)
        if let existing = userRecipes.first(where: { $0.recipeId == recipeId }) {
            existing.notes = notes
            coreData.saveContext()
        }
        
        do {
            try await userService.updateUserRecipeNotes(recipeId: recipeId, notes: notes)
        } catch {
            print("⚠️ Firebase notes update failed: \(error)")
        }
    }
    
    func saveRating(recipeId: String, rating: Int) async throws {
        guard let userId = await authService.getCurrentUser()?.id else { return }
        
        let userRecipes = coreData.fetchUserRecipes(byUserId: userId)
        if let existing = userRecipes.first(where: { $0.recipeId == recipeId }) {
            existing.rating = Int64(rating)
            coreData.saveContext()
        }
        
        do {
            try await userService.updateUserRecipeRating(recipeId: recipeId, rating: rating)
        } catch {
            print("⚠️ Firebase rating update failed: \(error)")
        }
    }
    
    func fetchCustomRecipeDetail(recipeId: String) async throws -> Recipe {
        guard let userId = await AuthService.shared.getCurrentUser()?.id else {
            throw AuthError.networkError
        }
        
        let customRecipes = CoreDataManager.shared.fetchCustomRecipes(byUserId: userId)
        guard let custom = customRecipes.first(where: { $0.id?.uuidString == recipeId }) else {
            throw APIError.noData
        }
        
        var ingredients: [Ingredient] = []
        if let customIngredients = custom.ingredients?.allObjects as? [CustomIngredient] {
            for ing in customIngredients {
                ingredients.append(Ingredient(
                    name: ing.name ?? "",
                    amount: ing.amount ?? "",
                    unit: ing.unit ?? ""
                ))
            }
        }
        
        return Recipe(
            id: custom.id?.uuidString ?? recipeId,
            source: .custom,
            name: custom.name ?? "",
            category: custom.category,
            cuisine: custom.cuisine,
            imageUrl: custom.imageUrl,
            ingredients: ingredients,
            instructions: custom.instructions
        )
    }
}
