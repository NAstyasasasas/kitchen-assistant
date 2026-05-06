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
    @Published var selectedApiCategory: String = "All"
    @Published var selectedApiCuisine: String = "All"
    
    private let interactor: HomeInteractorProtocol
    private weak var coordinator: MainCoordinator?
    private var currentTask: Task<Void, Never>?
    
    let apiCategories = [
        "All", "Beef", "Chicken", "Dessert", "Lamb",
        "Miscellaneous", "Pasta", "Pork", "Seafood",
        "Side", "Starter", "Vegan", "Vegetarian",
        "Breakfast", "Goat"
    ]

    let apiCuisines = [
        "All", "Algerian", "American", "Argentinian",
        "Australian", "British", "Canadian", "Chinese",
        "Croatian", "Dutch", "Egyptian", "Filipino",
        "French", "Greek", "Indian", "Irish", "Italian",
        "Jamaican", "Japanese", "Kenyan", "Malaysian",
        "Mexican", "Moroccan", "Norwegian", "Polish",
        "Portuguese", "Russian", "Saudi Arabian",
        "Slovakian", "Spanish", "Syrian", "Thai",
        "Tunisian", "Turkish", "Ukrainian", "Uruguayan",
        "Venezuelan", "Vietnamese"
    ]
    
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
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            await MainActor.run {
                searchResults = []
            }
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let searchQuery: String

            if LanguageManager.shared.isRussian {
                searchQuery = try await YandexTranslateService.shared.translate(
                    text: trimmed,
                    from: "ru",
                    to: "en"
                )
            } else {
                searchQuery = trimmed
            }

            let results = try await interactor.searchRecipes(query: searchQuery)

            await MainActor.run {
                searchResults = results
                isLoading = false
            }
        } catch {
            await MainActor.run {
                searchResults = []
                errorMessage = L10n.noRecipes
                isLoading = false
            }
            print("❌ Search error:", error)
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
    
    func toggleWantToCook(recipe: Recipe) async {
        let interactor = MyRecipesInteractor()
        let existing = await interactor.fetchRecipes(status: "wantToCook")

        if existing.contains(where: { $0.recipeId == recipe.id }) {
            try? await interactor.deleteRecipe(recipeId: recipe.id)
        } else {
            try? await interactor.saveRecipeStatus(
                recipeId: recipe.id,
                status: "wantToCook",
                recipeSource: recipe.source.rawValue
            )
        }

        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("userRecipeDeleted"),
                object: nil
            )
        }
    }
    
    func applyApiFilters() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let category = selectedApiCategory
            let cuisine = selectedApiCuisine

            var result: [Recipe] = []

            if category == "All" && cuisine == "All" {
                await loadRecipes()
                await MainActor.run {
                    isLoading = false
                }
                return
            }

            if category != "All" && cuisine == "All" {
                result = try await interactor.fetchRecipesByCategory(category)
            }

            else if category == "All" && cuisine != "All" {
                result = try await interactor.fetchRecipesByArea(cuisine)
            }

            else {
                let categoryRecipes = try await interactor.fetchRecipesByCategory(category)
                let cuisineRecipes = try await interactor.fetchRecipesByArea(cuisine)

                let cuisineNames = Set(
                    cuisineRecipes.map {
                        $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                )

                result = categoryRecipes.filter { recipe in
                    cuisineNames.contains(
                        recipe.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
            }

            await MainActor.run {
                filteredRecipes = result
                isLoading = false

                if result.isEmpty {
                    errorMessage = L10n.noRecipes
                }
            }

        } catch {
            await MainActor.run {
                filteredRecipes = []
                errorMessage = L10n.noRecipes
                isLoading = false
            }

            print("❌ Filter error:", error)
        }
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
                errorMessage = L10n.errorLoadingRecipes
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
                errorMessage = L10n.noRecipesWithFilters + " '\(L10n.mealType)' " + L10n.inCuisine + " '\(L10n.cuisine)'"
            } else if let cuisine = selectedCuisine {
                errorMessage = L10n.noRecipesWithFilters + " '\(L10n.cuisine)'"
            } else if let mealType = selectedMealType {
                errorMessage = L10n.noRecipesWithFilters + " '\(L10n.mealType)'"
            } else {
                errorMessage = L10n.noRecipes
            }
            filteredRecipes = []
        }
    }
}

extension HomePresenter: HomePresenterProtocol {}
