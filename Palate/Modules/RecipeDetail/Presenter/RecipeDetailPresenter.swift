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
    @Published var userRecipe: UserRecipe?
    @Published var notes: String = ""
    @Published var rating: Int = 0
    
    private let recipeId: String
    private let interactor: RecipeDetailInteractorProtocol
    private weak var coordinator: MainCoordinator?
    private let shoppingListPresenter: ShoppingListPresenter?
    private let myRecipesInteractor: MyRecipesInteractorProtocol
    
    init(recipeId: String,
         interactor: RecipeDetailInteractorProtocol = RecipeDetailInteractor(),
         coordinator: MainCoordinator?,
         shoppingListPresenter: ShoppingListPresenter,
         myRecipesInteractor: MyRecipesInteractorProtocol = MyRecipesInteractor()) {
        self.recipeId = recipeId
        self.interactor = interactor
        self.coordinator = coordinator
        self.shoppingListPresenter = shoppingListPresenter
        self.myRecipesInteractor = myRecipesInteractor
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
    
    func loadUserRecipeStatus() async {
        guard let userId = await AuthService.shared.getCurrentUser()?.id else { return }
        let userRecipes = CoreDataManager.shared.fetchUserRecipes(byUserId: userId)
        let userRecipe = userRecipes.first(where: { $0.recipeId == recipeId })
        await MainActor.run {
            self.userRecipe = userRecipe
            self.notes = userRecipe?.notes ?? ""
            self.rating = Int(userRecipe?.rating ?? 0)
        }
    }
    
    func addToWantToCook() async {
        do {
            try await myRecipesInteractor.saveRecipeStatus(recipeId: recipeId, status: "wantToCook", recipeSource: "mealDB")
            isInWantToCook = true
        } catch {
            errorMessage = L10n.addToCartError
        }
    }
    
    func markAsCooked() async {
        do {
            try await myRecipesInteractor.updateRecipeStatus(recipeId: recipeId, newStatus: "cooked")
            isInCooked = true
            isInWantToCook = false
        } catch {
            errorMessage = L10n.markAsCookedError
        }
    }
    func saveNotes(_ notes: String) async {
        do {
            try await interactor.saveNotes(recipeId: recipeId, notes: notes)
            await loadUserRecipeStatus()
        } catch {
            errorMessage = "Не удалось сохранить заметки"
        }
    }

    func saveRating(_ rating: Int) async {
        do {
            try await interactor.saveRating(recipeId: recipeId, rating: rating)
            await loadUserRecipeStatus()
            NotificationCenter.default.post(name: .ratingDidChange, object: recipeId)
        } catch {
            errorMessage = "Не удалось сохранить оценку"
        }
    }
}
