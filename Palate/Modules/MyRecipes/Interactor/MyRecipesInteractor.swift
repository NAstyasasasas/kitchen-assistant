//
//  MyRecipesInteractor.swift
//  Palate
//

import Foundation
import FirebaseAuth
import CoreData

protocol MyRecipesInteractorProtocol {
    func fetchRecipes(status: String?) async -> [UserRecipe]
    func saveRecipeStatus(recipeId: String, status: String, recipeSource: String) async throws
    func updateRecipeStatus(recipeId: String, newStatus: String) async throws
    func deleteRecipe(recipeId: String) async throws
    func fetchRecipeDetail(recipeId: String) async throws -> Recipe
    func updateRating(recipeId: String, rating: Int) async throws
}

final class MyRecipesInteractor: MyRecipesInteractorProtocol {
    private let coreData = CoreDataManager.shared
    private let userService = UserService.shared
    
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private func fetchLocalUserRecipe(recipeId: String, userId: String) -> UserRecipe? {
        let recipes = coreData.fetchUserRecipes(byUserId: userId)
        return recipes.first(where: { $0.recipeId == recipeId })
    }
    
    func fetchRecipes(status: String?) async -> [UserRecipe] {
        guard let userId = userId else { return [] }
        do {
            let remoteRecipes = try await userService.fetchUserRecipes(userId: userId, status: status)
            let context = coreData.viewContext
            let localRecipes = coreData.fetchUserRecipes(byUserId: userId, status: status)
            
            for local in localRecipes {
                if let recipeId = local.recipeId, !remoteRecipes.contains(where: { $0.recipeId == recipeId }) {
                    context.delete(local)
                }
            }
            
            for remote in remoteRecipes {
                if let existing = localRecipes.first(where: { $0.recipeId == remote.recipeId }) {
                    existing.status = remote.status
                    existing.rating = remote.rating
                    existing.notes = remote.notes
                    existing.dateCooked = remote.dateCooked
                    existing.synced = true
                } else {
                    context.insert(remote)
                }
            }
            try? context.save()
        } catch {
            print("❌ Failed to sync from Firebase: \(error)")
        }
        
        let all = coreData.fetchUserRecipes(byUserId: userId, status: status)
        let unique = Dictionary(grouping: all, by: { $0.recipeId }).compactMap { $0.value.first }
        return unique
    }
    
    func fetchRecipeDetail(recipeId: String) async throws -> Recipe {
        return try await APIService.shared.fetchRecipeDetail(id: recipeId)
    }
    
    func saveRecipeStatus(recipeId: String, status: String, recipeSource: String) async throws {
        guard let userId = userId else { throw AuthError.networkError }
        
        let existing = coreData.fetchUserRecipes(byUserId: userId).first(where: { $0.recipeId == recipeId })
        let userRecipe: UserRecipe
        if let existing = existing {
            userRecipe = existing
            userRecipe.status = status
            userRecipe.dateAdded = Date()
            userRecipe.synced = false
        } else {
            userRecipe = UserRecipe(context: coreData.viewContext)
            userRecipe.id = UUID()
            userRecipe.userId = userId
            userRecipe.recipeId = recipeId
            userRecipe.recipeSource = recipeSource
            userRecipe.status = status
            userRecipe.dateAdded = Date()
            userRecipe.synced = false
        }
        
        coreData.saveUserRecipe(userRecipe)
        
        do {
            try await userService.saveUserRecipe(userRecipe, userId: userId)
            userRecipe.synced = true
            coreData.saveContext()
        } catch {
            print("⚠️ Firebase save failed, will retry later: \(error)")
        }
    }
    
    func updateRecipeStatus(recipeId: String, newStatus: String) async throws {
        guard let userId = userId else { throw AuthError.networkError }
        
        coreData.updateUserRecipeStatus(recipeId: recipeId, status: newStatus, dateCooked: newStatus == "cooked" ? Date() : nil)
        
        let exists = try await userService.doesUserRecipeExist(recipeId: recipeId, userId: userId)
        if exists {
            try await userService.updateUserRecipeStatus(recipeId: recipeId, status: newStatus, dateCooked: newStatus == "cooked" ? Date() : nil)
        } else {
            let dummy = UserRecipe(context: coreData.viewContext)
            dummy.id = UUID()
            dummy.userId = userId
            dummy.recipeId = recipeId
            dummy.status = newStatus
            dummy.dateAdded = Date()
            dummy.synced = true
            try await userService.saveUserRecipe(dummy, userId: userId)
        }
    }
    
    func updateRating(recipeId: String, rating: Int) async throws {
        guard let userId = userId else { throw AuthError.networkError }
        coreData.updateRating(recipeId: recipeId, rating: rating)
        try await userService.updateUserRecipeRating(recipeId: recipeId, rating: rating)
    }
    
    func deleteRecipe(recipeId: String) async throws {
        guard let userId = userId else { throw AuthError.networkError }
        
        let localRecipes = coreData.fetchUserRecipes(byUserId: userId)
        if let toDelete = localRecipes.first(where: { $0.recipeId == recipeId }) {
            coreData.viewContext.delete(toDelete)
            coreData.saveContext()
        }
        
        do {
            try await userService.deleteUserRecipe(recipeId: recipeId, userId: userId)
        } catch {
            print("⚠️ Firebase delete failed: \(error)")
        }
    }
}
