//
//  RecipeDetailPresenter.swift
//  Palate
//

import SwiftUI
import Combine

@MainActor
final class RecipeDetailPresenter: ObservableObject {
    @Published var recipe: Recipe?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isInWantToCook = false
    @Published var isInCooked = false
    
    private let recipeId: String
    private let interactor: RecipeDetailInteractorProtocol
    private weak var coordinator: MainCoordinator?
    private let shoppingListPresenter: ShoppingListPresenter?
    
    init(recipeId: String,
         interactor: RecipeDetailInteractorProtocol = RecipeDetailInteractor(),
         coordinator: MainCoordinator?, shoppingListPresenter: ShoppingListPresenter) {
        self.recipeId = recipeId
        self.interactor = interactor
        self.coordinator = coordinator
        self.shoppingListPresenter = shoppingListPresenter
    }
    
    func loadRecipe() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            recipe = try await interactor.fetchRecipeDetail(id: recipeId)
            let status = try await interactor.checkRecipeStatus(recipeId: recipeId)
            isInWantToCook = status.wantToCook
            isInCooked = status.cooked
        } catch {
            errorMessage = L10n.loadRecipeError
        }
    }
    
    func addToWantToCook() async {
        do {
            try await interactor.addToWantToCook(recipeId: recipeId)
            isInWantToCook = true
        } catch {
            errorMessage = L10n.addToCartError
        }
    }
    
    func markAsCooked() async {
        do {
            try await interactor.markAsCooked(recipeId: recipeId)
            isInCooked = true
            isInWantToCook = false
        } catch {
            errorMessage = L10n.markAsCookedError
        }
    }
}
