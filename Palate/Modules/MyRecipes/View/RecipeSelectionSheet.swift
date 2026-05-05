//
//  RecipeSelectionSheet.swift
//  Palate
//

import SwiftUI

struct RecipeSelectionSheet: View {
    @ObservedObject var presenter: MealPlanPresenter
    @State private var searchText = ""
    @State private var apiResults: [Recipe] = []
    @State private var customRecipes: [Recipe] = []
    @State private var isLoading = false
    @State private var selectedTab = 0
    @State private var translatedNames: [String: String] = [:]
    @State private var translatedCategories: [String: String] = [:]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("", selection: $selectedTab) {
                    Text(L10n.myRecipes).tag(0)
                    Text(L10n.search).tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if selectedTab == 0 {
                    List(customRecipes, id: \.id) { recipe in
                        recipeButton(recipe)
                    }
                    .refreshable {
                        await loadCustomRecipes()
                    }
                } else {
                    List(apiResults, id: \.id) { recipe in
                        recipeButton(recipe)
                    }
                    .searchable(text: $searchText)
                    .onSubmit(of: .search) {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            apiResults = try await APIService.shared.searchRecipes(query: searchText)
                        }
                    }
                    .overlay {
                        if isLoading {
                            ProgressView()
                        }
                    }
                }
            }
            .navigationTitle(L10n.selectRecipe)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
            }
            .task {
                await loadCustomRecipes()
            }
        }
    }
    
    @ViewBuilder
    private func recipeButton(_ recipe: Recipe) -> some View {
        Button {
            presenter.assignRecipe(recipe)
            dismiss()
        } label: {
            HStack {
                AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                    }
                }
                VStack(alignment: .leading) {
                    Text(translatedNames[recipe.id] ?? recipe.name)
                        .font(.headline)
                    Text(translatedCategories[recipe.category ?? ""] ?? (recipe.category ?? ""))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .foregroundColor(.primary)
        .onAppear {
            Task {
                await translateRecipeIfNeeded(recipe)
            }
        }
    }
    
    private func translateRecipeIfNeeded(_ recipe: Recipe) async {
        
        if translatedNames[recipe.id] == nil {
            let translatedName = await YandexTranslateService.shared.translateIfNeeded(recipe.name)
            await MainActor.run {
                translatedNames[recipe.id] = translatedName
            }
        }
        
        if let category = recipe.category, translatedCategories[category] == nil {
            let translatedCategory = await YandexTranslateService.shared.translateIfNeeded(category)
            await MainActor.run {
                translatedCategories[category] = translatedCategory
            }
        }
    }
    
    private func loadCustomRecipes() async {
        guard let userId = await AuthService.shared.getCurrentUser()?.id else { return }
        let custom = CoreDataManager.shared.fetchCustomRecipes(byUserId: userId)
        var recipes: [Recipe] = []
        for c in custom {
            var ingredients: [Ingredient] = []
            if let customIngredients = c.ingredients?.allObjects as? [CustomIngredient] {
                for ing in customIngredients {
                    ingredients.append(Ingredient(
                        name: ing.name ?? "",
                        amount: ing.amount ?? "",
                        unit: ing.unit ?? ""
                    ))
                }
            }
            let recipe = Recipe(
                id: c.id?.uuidString ?? UUID().uuidString,
                source: .custom,
                name: c.name ?? "",
                category: c.category,
                cuisine: c.cuisine,
                imageUrl: c.imageUrl,
                ingredients: ingredients,
                instructions: c.instructions
            )
            recipes.append(recipe)
        }
        await MainActor.run {
            customRecipes = recipes
        }
    }
}
