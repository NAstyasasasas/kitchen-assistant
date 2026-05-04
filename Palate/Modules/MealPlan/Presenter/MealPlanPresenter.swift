//
//  MealPlanPresenter.swift
//  Palate
//

import SwiftUI
import Combine

final class MealPlanPresenter: ObservableObject {
    @Published var weekPlans: [Date: MealPlan] = [:]
    @Published var weekDays: [Date] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var showRecipePicker = false
    @Published var selectedDate: Date?
    @Published var selectedMealType: MealPlanMealType?
    
    @Published var showConflictAlert = false
    @Published var pendingConfirmationRecipe: Recipe?
    
    private let interactor: MealPlanInteractorProtocol
    private let apiService = APIService.shared
    private weak var coordinator: MainCoordinator?
    private let shoppingInteractor = ShoppingListInteractor()
    
    init(interactor: MealPlanInteractorProtocol = MealPlanInteractor(),
         coordinator: MainCoordinator?) {
        self.interactor = interactor
        self.coordinator = coordinator
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        loadWeekPlans(startOfWeek: startOfWeek)
    }
    
    func normalizeDate(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
        
    func recipeId(for date: Date, mealType: MealPlanMealType) -> String? {
        let normalizedDate = normalizeDate(date)
        guard let plan = weekPlans[normalizedDate] else { return nil }
        switch mealType {
        case .breakfast: return plan.breakfastRecipeId
        case .lunch: return plan.lunchRecipeId
        case .dinner: return plan.dinnerRecipeId
        case .snack: return plan.snackRecipeId
        }
    }
    
    func assignRecipe(_ recipe: Recipe) {
        guard let date = selectedDate, let mealType = selectedMealType else { return }
        
        interactor.updatePlan(date: date, mealType: mealType, recipeId: recipe.id)
        let startOfWeek = weekDays.first ?? Date()
        loadWeekPlans(startOfWeek: startOfWeek)
        showRecipePicker = false
        selectedDate = nil
        selectedMealType = nil
    }
    
    func removeRecipe(date: Date, mealType: MealPlanMealType) {
        interactor.updatePlan(date: date, mealType: mealType, recipeId: nil)
        let startOfWeek = weekDays.first ?? Date()
        loadWeekPlans(startOfWeek: startOfWeek)
    }
    
    func selectSlot(date: Date, mealType: MealPlanMealType) {
        selectedDate = date
        selectedMealType = mealType
        showRecipePicker = true
    }
    
    private func getCurrentWeekDates(startOfWeek: Date) -> [Date] {
        return (0...6).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    func collectShoppingList() async {
        var allRecipes: [Recipe] = []
        
        for (_, plan) in weekPlans {
            let recipeIds = [plan.breakfastRecipeId, plan.lunchRecipeId, plan.dinnerRecipeId, plan.snackRecipeId]
            
            for recipeId in recipeIds {
                guard let recipeId = recipeId else { continue }
                do {
                    let recipe = try await loadRecipeById(recipeId)
                    allRecipes.append(recipe)
                } catch {
                    print("❌ Failed to fetch recipe \(recipeId): \(error)")
                }
            }
        }
        
        for recipe in allRecipes {
            if shoppingInteractor.recipeHasConflicts(recipe) {
                await MainActor.run {
                    pendingConfirmationRecipe = recipe
                    showConflictAlert = true
                }
                return
            }
        }
        
        await addAllToShoppingList(recipes: allRecipes)
    }
    
    private func loadRecipeById(_ id: String) async throws -> Recipe {
        let isCustom = id.count == 36 && id.contains("-")
        
        if isCustom {
            guard let userId = await AuthService.shared.getCurrentUser()?.id else {
                throw AuthError.networkError
            }
            let customRecipes = CoreDataManager.shared.fetchCustomRecipes(byUserId: userId)
            guard let custom = customRecipes.first(where: { $0.id?.uuidString == id }) else {
                throw APIError.noData
            }
            
            var ingredients: [Ingredient] = []
            if let customIngredients = custom.ingredients?.allObjects as? [CustomIngredient] {
                for ing in customIngredients {
                    ingredients.append(Ingredient(
                        name: ing.name ?? "",
                        amount: ing.amount ?? "",
                        unit: ing.unit ?? ""
                    ))
                }
            }
            
            return Recipe(
                id: id,
                source: .custom,
                name: custom.name ?? "",
                category: custom.category,
                cuisine: custom.cuisine,
                imageUrl: custom.imageUrl,
                ingredients: ingredients,
                instructions: custom.instructions
            )
        } else {
            return try await APIService.shared.fetchRecipeDetail(id: id)
        }
    }
    
    private func addAllToShoppingList(recipes: [Recipe]) async {
        for recipe in recipes {
            await shoppingInteractor.addWholeRecipe(recipe)
        }
    }
    
    func confirmAddToShoppingList() {
        Task {
            guard let recipe = pendingConfirmationRecipe else { return }
            
            await shoppingInteractor.addWholeRecipe(recipe)
            
            await MainActor.run {
                pendingConfirmationRecipe = nil
                showConflictAlert = false
            }
            
            var remainingRecipes: [Recipe] = []
            for (_, plan) in weekPlans {
                let recipeIds = [plan.breakfastRecipeId, plan.lunchRecipeId, plan.dinnerRecipeId, plan.snackRecipeId]
                for recipeId in recipeIds {
                    guard let recipeId = recipeId else { continue }
                    if recipeId != recipe.id {
                        do {
                            let r = try await loadRecipeById(recipeId)
                            remainingRecipes.append(r)
                        } catch {
                            print("❌ Failed to fetch recipe \(recipeId): \(error)")
                        }
                    }
                }
            }
            await addAllToShoppingList(recipes: remainingRecipes)
        }
    }
    
    func openRecipe(recipeId: String) {
        let isCustom = recipeId.count == 36 && recipeId.contains("-")
        let source: RecipeSource = isCustom ? .custom : .mealDB
        coordinator?.showRecipeDetail(recipeId: recipeId, source: source)
    }
    
    func loadWeekPlans(startOfWeek: Date) {
        Task {
            await interactor.syncWithFirebase()
            await MainActor.run {
                weekDays = getCurrentWeekDates(startOfWeek: startOfWeek)
                let plans = interactor.fetchWeekPlans(startOfWeek: startOfWeek)
                
                let uniquePlans = Dictionary(grouping: plans, by: { Calendar.current.startOfDay(for: $0.date ?? Date()) })
                    .compactMap { $0.value.first }
                
                weekPlans = Dictionary(uniqueKeysWithValues: uniquePlans.compactMap { plan in
                    guard let date = plan.date else { return nil }
                    return (Calendar.current.startOfDay(for: date), plan)
                })
            }
        }
    }
}
