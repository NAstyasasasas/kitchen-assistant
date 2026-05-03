//
//  CreateRecipeInteractorProtocol.swift
//  Palate
//

import Foundation
import UIKit
import CoreData

protocol CreateRecipeInteractorProtocol {
    func saveRecipe(recipe: CustomRecipe, image: UIImage?) async throws
    func addIngredient(name: String, amount: String, unit: String) -> CustomIngredient
    func deleteIngredient(_ ingredient: CustomIngredient)
}

final class CreateRecipeInteractor: CreateRecipeInteractorProtocol {
    private let coreData = CoreDataManager.shared
    private let storageService = SupabaseStorageService()
    private let customRecipeService = CustomRecipeService.shared
    
    func saveRecipe(recipe: CustomRecipe, image: UIImage?) async throws {
        guard let userId = await AuthService.shared.getCurrentUser()?.id else {
            throw AuthError.networkError
        }
        
        if let image = image, let recipeId = recipe.id?.uuidString {
            do {
                let imageUrl = try await storageService.uploadRecipeImage(recipeId: recipeId, image: image)
                recipe.imageUrl = imageUrl
            } catch {
                print("❌ Failed to upload image: \(error)")
            }
        }
        
        coreData.saveContext()
        
        do {
            try await customRecipeService.saveCustomRecipe(recipe, userId: userId)
            recipe.synced = true
            coreData.saveContext()
        } catch {
            throw error
        }
    }
    
    func addIngredient(name: String, amount: String, unit: String) -> CustomIngredient {
        let ingredient = CustomIngredient(context: coreData.viewContext)
        ingredient.id = UUID()
        ingredient.name = name
        ingredient.amount = amount
        ingredient.unit = unit
        return ingredient
    }
    
    func deleteIngredient(_ ingredient: CustomIngredient) {
        coreData.viewContext.delete(ingredient)
        coreData.saveContext()
    }
}
