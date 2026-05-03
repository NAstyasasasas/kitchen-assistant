//
//  CreateRecipePresenter.swift
//  Palate
//

import SwiftUI
import UIKit
import Combine
import CoreData

enum RecipeMode: Equatable {
    case create
    case edit(recipeId: String)
    
    static func == (lhs: RecipeMode, rhs: RecipeMode) -> Bool {
        switch (lhs, rhs) {
        case (.create, .create):
            return true
        case (.edit(let id1), .edit(let id2)):
            return id1 == id2
        default:
            return false
        }
    }
}

struct IngredientInput {
    var name: String = ""
    var amount: String = ""
    var unit: String = ""
}

final class CreateRecipePresenter: ObservableObject {
    @Published var name = ""
    @Published var cuisine = ""
    @Published var category = ""
    @Published var instructions = ""
    @Published var ingredientInputs: [IngredientInput] = []
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private(set) var mode: RecipeMode
    private let interactor: CreateRecipeInteractorProtocol
    private let coreData = CoreDataManager.shared
    
    init(mode: RecipeMode = .create,
         interactor: CreateRecipeInteractorProtocol = CreateRecipeInteractor()) {
        self.mode = mode
        self.interactor = interactor
        
        if case .edit(let recipeId) = mode {
            loadRecipeForEditing(recipeId: recipeId)
        }
    }
    
    private func loadRecipeForEditing(recipeId: String) {
        Task {
            guard let userId = await AuthService.shared.getCurrentUser()?.id else { return }
            let recipes = coreData.fetchCustomRecipes(byUserId: userId)
            
            await MainActor.run {
                guard let recipe = recipes.first(where: { $0.id?.uuidString == recipeId }) else { return }
                
                name = recipe.name ?? ""
                cuisine = recipe.cuisine ?? ""
                category = recipe.category ?? ""
                instructions = recipe.instructions ?? ""
                
                if let customIngredients = recipe.ingredients?.allObjects as? [CustomIngredient] {
                    ingredientInputs = customIngredients.map { ing in
                        IngredientInput(
                            name: ing.name ?? "",
                            amount: ing.amount ?? "",
                            unit: ing.unit ?? ""
                        )
                    }
                }
                
                if let imageUrl = recipe.imageUrl, let url = URL(string: imageUrl) {
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.selectedImage = image
                            }
                        }
                    }.resume()
                }
            }
        }
    }
    
    func addIngredient() {
        ingredientInputs.append(IngredientInput())
    }
    
    func removeIngredient(at index: Int) {
        ingredientInputs.remove(at: index)
    }

    func saveRecipe() async {
        errorMessage = nil
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCuisine = cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            errorMessage = "Введите название рецепта"
            return
        }
        if trimmedCuisine.isEmpty {
            errorMessage = "Введите кухню"
            return
        }
        if trimmedCategory.isEmpty {
            errorMessage = "Выберите категорию"
            return
        }
        if trimmedInstructions.isEmpty {
            errorMessage = "Введите инструкцию приготовления"
            return
        }
        
        let validIngredients = ingredientInputs.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        if validIngredients.isEmpty {
            errorMessage = "Добавьте хотя бы один ингредиент"
            return
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        guard let userId = await AuthService.shared.getCurrentUser()?.id else {
            errorMessage = "Пользователь не авторизован"
            return
        }
        
        let recipe: CustomRecipe
        
        if case .edit(let recipeId) = mode {
            let recipes = coreData.fetchCustomRecipes(byUserId: userId)
            
            guard let existing = recipes.first(where: { $0.id?.uuidString == recipeId }) else {
                errorMessage = "Рецепт не найден"
                return
            }
            
            recipe = existing
            recipe.name = trimmedName
            recipe.cuisine = trimmedCuisine
            recipe.category = trimmedCategory
            recipe.instructions = trimmedInstructions
            recipe.updatedAt = Date()
            recipe.synced = false
            
            if let oldIngredients = recipe.ingredients?.allObjects as? [CustomIngredient] {
                for ing in oldIngredients {
                    coreData.viewContext.delete(ing)
                }
            }
            
            for input in validIngredients {
                let ing = CustomIngredient(context: coreData.viewContext)
                ing.id = UUID()
                ing.name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
                ing.amount = input.amount.trimmingCharacters(in: .whitespacesAndNewlines)
                ing.unit = input.unit.trimmingCharacters(in: .whitespacesAndNewlines)
                ing.recipe = recipe
            }
            
        } else {
            recipe = CustomRecipe(context: coreData.viewContext)
            recipe.id = UUID()
            recipe.userId = userId
            recipe.name = trimmedName
            recipe.cuisine = trimmedCuisine
            recipe.category = trimmedCategory
            recipe.instructions = trimmedInstructions
            recipe.createdAt = Date()
            recipe.updatedAt = Date()
            recipe.synced = false
            
            for input in validIngredients {
                let ing = CustomIngredient(context: coreData.viewContext)
                ing.id = UUID()
                ing.name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
                ing.amount = input.amount.trimmingCharacters(in: .whitespacesAndNewlines)
                ing.unit = input.unit.trimmingCharacters(in: .whitespacesAndNewlines)
                ing.recipe = recipe
            }
        }
        
        coreData.saveContext()
        
        do {
            try await interactor.saveRecipe(recipe: recipe, image: selectedImage)
            
            await MainActor.run {
                NotificationCenter.default.post(
                    name: NSNotification.Name("recipeDidSave"),
                    object: nil
                )
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Ошибка сохранения рецепта"
            }
        }
    }
}
