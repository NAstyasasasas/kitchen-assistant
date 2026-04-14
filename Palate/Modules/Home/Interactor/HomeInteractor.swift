//
//  HomeInteractor.swift
//  Palate
//

import Foundation

protocol HomeInteractorProtocol {
    func fetchCategories() async throws -> [Category]
    func fetchRecipesByCategory(_ category: String) async throws -> [Recipe]
    func fetchRecipesByArea(_ area: String) async throws -> [Recipe]
    func searchRecipes(query: String) async throws -> [Recipe]
    func filterRecipesByIngredients(recipes: [Recipe], ingredients: Set<IngredientFilter>) -> [Recipe]
    func fetchRecipesByIngredient(_ ingredient: String) async throws -> [Recipe]
}

final class HomeInteractor: HomeInteractorProtocol {
    private let apiService = APIService.shared
    
    func fetchCategories() async throws -> [Category] {
        return try await apiService.fetchCategories()
    }
    func fetchRecipesByIngredient(_ ingredient: String) async throws -> [Recipe] {
        return try await apiService.fetchRecipesByIngredient(ingredient)
    }
    
    func fetchRecipesByCategory(_ category: String) async throws -> [Recipe] {
        return try await apiService.fetchRecipesByCategory(category)
    }
    
    func fetchRecipesByArea(_ area: String) async throws -> [Recipe] {
        return try await apiService.fetchRecipesByArea(area)
    }
    
    func searchRecipes(query: String) async throws -> [Recipe] {
        return try await apiService.searchRecipes(query: query)
    }
    
    func filterRecipesByIngredients(recipes: [Recipe], ingredients: Set<IngredientFilter>) -> [Recipe] {
        guard !ingredients.isEmpty else { return recipes }
        
        return recipes.filter { recipe in
            let recipeIngredientNames = recipe.ingredients.map { $0.name.lowercased() }
            return ingredients.contains { ingredient in
                recipeIngredientNames.contains { $0.contains(ingredient.apiQuery.lowercased()) }
            }
        }
    }
}
