//
//  MyRecipesPresenter.swift
//  Palate
//

import SwiftUI
import Combine

final class MyRecipesPresenter: ObservableObject {
    @Published var wantToCookRecipes: [Recipe] = []
    @Published var cookedRecipes: [Recipe] = []
    @Published var myRecipes: [Recipe] = []
    @Published var cookedUserRecipes: [UserRecipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let interactor: MyRecipesInteractorProtocol
    private weak var coordinator: MainCoordinator?
    
    init(interactor: MyRecipesInteractorProtocol = MyRecipesInteractor(),
         coordinator: MainCoordinator?) {
        self.interactor = interactor
        self.coordinator = coordinator
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ratingDidChange),
            name: .ratingDidChange,
            object: nil
        )
    }
    
    @objc private func ratingDidChange() {
        loadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadData() {
        Task {
            await MainActor.run { isLoading = true }
            defer { Task { @MainActor in isLoading = false } }
            
            await MainActor.run {
                wantToCookRecipes = []
                cookedRecipes = []
                myRecipes = []
                cookedUserRecipes = []
            }
            
            let wantToCook = await interactor.fetchRecipes(status: "wantToCook")
            let cooked = await interactor.fetchRecipes(status: "cooked")
            
            await MainActor.run {
                self.cookedUserRecipes = cooked
            }
            
            await fetchRecipeDetails(for: wantToCook, type: .wantToCook)
            await fetchRecipeDetails(for: cooked, type: .cooked)
        }
    }
    
    func didSelectRecipe(_ recipeId: String) {
        coordinator?.showRecipeDetail(recipeId: recipeId)
    }
    
    func markAsCooked(recipeId: String) {
        Task {
            do {
                try await interactor.updateRecipeStatus(recipeId: recipeId, newStatus: "cooked")
                await loadData()
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
    
    func deleteRecipe(recipeId: String, from status: String) {
        Task {
            do {
                try await interactor.deleteRecipe(recipeId: recipeId)
                await loadData()
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
    
    func updateRating(recipeId: String, rating: Int) {
        Task {
            do {
                try await interactor.updateRating(recipeId: recipeId, rating: rating)
                await MainActor.run {
                    if let index = cookedUserRecipes.firstIndex(where: { $0.recipeId == recipeId }) {
                        cookedUserRecipes[index].rating = Int64(rating)
                    }
                    loadData()
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func fetchRecipeDetails(for userRecipes: [UserRecipe], type: RecipeListType) async {
        var recipes: [Recipe] = []
        for userRecipe in userRecipes {
            guard let recipeId = userRecipe.recipeId else { continue }
            do {
                let recipe = try await interactor.fetchRecipeDetail(recipeId: recipeId)
                recipes.append(recipe)
            } catch {
                print("❌ Failed to fetch recipe \(recipeId): \(error)")
                if error.localizedDescription.contains("dataCorrupted") {
                    try? await interactor.deleteRecipe(recipeId: recipeId)
                }
            }
        }
        await MainActor.run {
            switch type {
            case .wantToCook:
                wantToCookRecipes = recipes
            case .cooked:
                cookedRecipes = recipes
            case .myRecipes:
                myRecipes = recipes
            }
        }
    }
}

enum RecipeListType {
    case wantToCook, cooked, myRecipes
}
