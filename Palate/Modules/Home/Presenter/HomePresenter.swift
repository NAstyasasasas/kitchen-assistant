//
//  HomePresenter.swift
//  Palate
//

import SwiftUI
import Combine

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
            var recipes: [Recipe] = []
            
            if let cuisine = selectedCuisine, let mealType = selectedMealType {
                
                let areaRecipes = try await interactor.fetchRecipesByArea(cuisine.apiArea)
                
                let ingredientKeyword = mealType.searchKeywords.first ?? mealType.apiCategory.lowercased()
                let ingredientRecipes = try await interactor.fetchRecipesByIngredient(ingredientKeyword)
                
                let areaIds = Set(areaRecipes.map { $0.id })
                let ingredientIds = Set(ingredientRecipes.map { $0.id })
                let commonIds = areaIds.intersection(ingredientIds)
                
                recipes = areaRecipes.filter { commonIds.contains($0.id) }
                
                
            } else if let cuisine = selectedCuisine {
                recipes = try await interactor.fetchRecipesByArea(cuisine.apiArea)
                
            } else if let mealType = selectedMealType {
                let ingredientKeyword = mealType.searchKeywords.first ?? mealType.apiCategory.lowercased()
                recipes = try await interactor.fetchRecipesByIngredient(ingredientKeyword)
                
            } else {
                let randomQueries = ["Chicken", "Pasta", "Rice", "Beef", "Fish"]
                let randomQuery = randomQueries.randomElement() ?? "Chicken"
                recipes = try await interactor.searchRecipes(query: randomQuery)
            }
            
            if Task.isCancelled { return }
            
            if recipes.isEmpty {
                await MainActor.run {
                    if let cuisine = selectedCuisine, let mealType = selectedMealType {
                        errorMessage = "Нет рецептов с '\(mealType.rawValue)' в '\(cuisine.rawValue)' кухне"
                    } else if let cuisine = selectedCuisine {
                        errorMessage = "Нет рецептов для кухни '\(cuisine.rawValue)'"
                    } else if let mealType = selectedMealType {
                        errorMessage = "Нет рецептов с '\(mealType.rawValue)'"
                    } else {
                        errorMessage = "Нет рецептов. Попробуйте другие фильтры"
                    }
                    filteredRecipes = []
                }
                return
            }
            
            if Task.isCancelled { return }
            
            await MainActor.run {
                filteredRecipes = Array(recipes.shuffled().prefix(30))
                print("✅ Загружено рецептов: \(filteredRecipes.count)")
                errorMessage = nil
            }
            
        } catch {
            if Task.isCancelled { return }
            await MainActor.run {
                errorMessage = "Ошибка загрузки. Проверьте подключение к интернету"
                filteredRecipes = []
            }
        }
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
                    errorMessage = "Ничего не найдено по запросу '\(query)'"
                }
                searchResults = results
            }
        } catch {
            if Task.isCancelled { return }
            await MainActor.run {
                errorMessage = "Ошибка поиска. Проверьте подключение"
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
}
