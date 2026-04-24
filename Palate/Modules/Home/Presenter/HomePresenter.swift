//
//  HomePresenter.swift
//  Palate
//

import SwiftUI
import Combine

protocol HomePresenterProtocol: AnyObject {
    func didSelectRecipe(_ recipeId: String)
}

final class HomePresenter: ObservableObject {
    @Published var filteredRecipes: [Recipe] = []
    @Published var searchResults: [Recipe] = []
    @Published var selectedCuisine: CuisineType? = nil
    @Published var selectedMealType: MealType? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let interactor: HomeInteractorProtocol
    private weak var coordinator: MainCoordinator?
    private var currentTask: Task<Void, Never>?
    
    init(interactor: HomeInteractorProtocol = HomeInteractor(),
         coordinator: MainCoordinator?) {
        self.interactor = interactor
        self.coordinator = coordinator
    }
    
    func loadRecipes() async {
        currentTask?.cancel()
        
        let task = Task {
            await performLoadRecipes()
        }
        currentTask = task
        await task.value
    }
    
    func searchRecipes(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                searchResults = []
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let results = try await interactor.searchRecipes(query: query)
            if Task.isCancelled { return }
            await MainActor.run {
                if results.isEmpty {
                    errorMessage = "no_results".localized + " '\(query)'"
                }
                searchResults = results
            }
        } catch {
            if Task.isCancelled { return }
            await MainActor.run {
                errorMessage = "search_error".localized
                searchResults = []
            }
        }
    }
    
    func resetFilters() {
        selectedCuisine = nil
        selectedMealType = nil
        errorMessage = nil
        Task {
            await loadRecipes()
        }
    }
    
    func didSelectRecipe(_ recipeId: String) {
        coordinator?.showRecipeDetail(recipeId: recipeId)
    }
    
    private func performLoadRecipes() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let recipes = try await fetchRecipesWithFilters()
            
            if Task.isCancelled { return }
            
            if recipes.isEmpty {
                await handleEmptyRecipes()
                return
            }
            
            if Task.isCancelled { return }
            
            await MainActor.run {
                filteredRecipes = Array(recipes.shuffled().prefix(30))
                errorMessage = nil
            }
            
        } catch {
            if Task.isCancelled { return }
            await MainActor.run {
                errorMessage = "error_loading_recipes".localized
                filteredRecipes = []
            }
        }
    }
    
    private func fetchRecipesWithFilters() async throws -> [Recipe] {
        if let cuisine = selectedCuisine, let mealType = selectedMealType {
            async let areaRecipes = interactor.fetchRecipesByArea(cuisine.apiArea)
            let ingredientKeyword = mealType.searchKeywords.first ?? mealType.apiCategory.lowercased()
            async let ingredientRecipes = interactor.fetchRecipesByIngredient(ingredientKeyword)
            
            let area = try await areaRecipes
            let ingredient = try await ingredientRecipes
            
            let areaIds = Set(area.map { $0.id })
            let ingredientIds = Set(ingredient.map { $0.id })
            let commonIds = areaIds.intersection(ingredientIds)
            
            return area.filter { commonIds.contains($0.id) }
            
        } else if let cuisine = selectedCuisine {
            return try await interactor.fetchRecipesByArea(cuisine.apiArea)
            
        } else if let mealType = selectedMealType {
            let ingredientKeyword = mealType.searchKeywords.first ?? mealType.apiCategory.lowercased()
            return try await interactor.fetchRecipesByIngredient(ingredientKeyword)
            
        } else {
            let randomQueries = ["Chicken", "Pasta", "Rice", "Beef", "Fish"]
            let randomQuery = randomQueries.randomElement() ?? "Chicken"
            return try await interactor.searchRecipes(query: randomQuery)
        }
    }
    
    private func handleEmptyRecipes() async {
        await MainActor.run {
            if let cuisine = selectedCuisine, let mealType = selectedMealType {
                errorMessage = "no_recipes_with_filters".localized + " '\(mealType.localizedName)' " + "in_cuisine".localized + " '\(cuisine.localizedName)'"
            } else if let cuisine = selectedCuisine {
                errorMessage = "no_recipes_with_filters".localized + " '\(cuisine.localizedName)'"
            } else if let mealType = selectedMealType {
                errorMessage = "no_recipes_with_filters".localized + " '\(mealType.localizedName)'"
            } else {
                errorMessage = "no_recipes".localized
            }
            filteredRecipes = []
        }
    }
}

extension HomePresenter: HomePresenterProtocol {}
