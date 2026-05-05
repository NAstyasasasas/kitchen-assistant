//
//  HomeView.swift
//  Palate
//

import Foundation
import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(isSelected ? Color.accentPurple : Color.lightCategoryBg)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(26)
        }
    }
}

struct RecipeCardGrid: View {
    let recipes: [Recipe]
    let onTap: (String) -> Void
    @State private var translatedNames: [String: String] = [:]
    @State private var translatedCategories: [String: String] = [:]
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(recipes) { recipe in
                Button {
                    onTap(recipe.id)
                } label: {
                    RecipeCard(
                        recipe: recipe,
                        translatedName: translatedNames[recipe.id],
                        translatedCategory: translatedCategories[recipe.category ?? ""]
                    )
                }
                .buttonStyle(.plain)
                .onAppear {
                    Task {
                        await translateRecipeIfNeeded(recipe)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
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
}

struct HomeEmptyState: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(Color(.secondaryLabel))
            Text(message)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
            Text(L10n.tryChangeFilters)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        }
        .padding(.top, 100)
    }
}

struct HomeView: View {
    @StateObject var presenter: HomePresenter
    @State private var searchText = ""
    @State private var showFilterSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    SearchBar(text: $searchText) {
                        Task {
                            await presenter.searchRecipes(query: searchText)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: L10n.all,
                                isSelected: presenter.selectedCuisine == nil && presenter.selectedMealType == nil
                            ) {
                                presenter.resetFilters()
                            }
                            
                            ForEach(CuisineType.allCases.prefix(6)) { cuisine in
                                FilterChip(
                                    title: cuisine.localizedName,
                                    isSelected: presenter.selectedCuisine == cuisine
                                ) {
                                    if presenter.selectedCuisine == cuisine {
                                        presenter.selectedCuisine = nil
                                    } else {
                                        presenter.selectedCuisine = cuisine
                                        presenter.selectedMealType = nil
                                    }
                                    Task {
                                        await presenter.loadRecipes()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if presenter.isLoading {
                        ProgressView()
                            .padding(.top, 50)
                    } else if !presenter.searchResults.isEmpty && !searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(L10n.searchResults)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            RecipeCardGrid(recipes: presenter.searchResults) { recipeId in
                                presenter.didSelectRecipe(recipeId)
                            }
                        }
                    } else if presenter.filteredRecipes.isEmpty {
                        HomeEmptyState(message: presenter.errorMessage ?? L10n.noRecipes)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                if let cuisine = presenter.selectedCuisine {
                                    Text(cuisine.localizedName)
                                        .font(.system(size: 22, weight: .bold))
                                } else if let mealType = presenter.selectedMealType {
                                    Text(mealType.localizedName)
                                        .font(.system(size: 22, weight: .bold))
                                } else {
                                    Text(L10n.recommendations)
                                        .font(.system(size: 22, weight: .bold))
                                }
                                
                                Spacer()
                                
                                Button {
                                    showFilterSheet = true
                                } label: {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.title3)
                                        .foregroundColor(.accentPurple)
                                }
                            }
                            .padding(.horizontal)
                            
                            RecipeCardGrid(recipes: presenter.filteredRecipes) { recipeId in
                                presenter.didSelectRecipe(recipeId)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemBackground))
            .task {
                await presenter.loadRecipes()
            }
            .refreshable {
                await presenter.loadRecipes()
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(presenter: presenter)
            }
        }
    }
}

struct FilterSheetView: View {
    @ObservedObject var presenter: HomePresenter
    @Environment(\.dismiss) var dismiss
    
    @State private var tempCuisine: CuisineType? = nil
    @State private var tempMealType: MealType? = nil
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        tempCuisine = nil
                    } label: {
                        HStack {
                            Text(L10n.anyCuisine)
                                .fontWeight(.medium)
                            Spacer()
                            if tempCuisine == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentPurple)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    ForEach(CuisineType.allCases) { cuisine in
                        Button {
                            tempCuisine = cuisine
                        } label: {
                            HStack {
                                Text(cuisine.localizedName)
                                Spacer()
                                if tempCuisine == cuisine {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentPurple)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    HStack {
                        Image(systemName: "fork.knife")
                        Text(L10n.cuisine)
                    }
                }
                
                Section {
                    Button {
                        tempMealType = nil
                    } label: {
                        HStack {
                            Text(L10n.anyType)
                                .fontWeight(.medium)
                            Spacer()
                            if tempMealType == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentPurple)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    ForEach(MealType.allCases) { mealType in
                        Button {
                            tempMealType = mealType
                        } label: {
                            HStack {
                                Text(mealType.localizedName)
                                Spacer()
                                if tempMealType == mealType {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentPurple)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    HStack {
                        Image(systemName: "carrot")
                        Text(L10n.mealType)
                    }
                }
                
                if tempCuisine != nil || tempMealType != nil {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let cuisine = tempCuisine {
                                    Text(cuisine.localizedName)
                                        .font(.caption)
                                        .foregroundColor(.accentPurple)
                                }
                                if let mealType = tempMealType {
                                    Text(mealType.localizedName)
                                        .font(.caption)
                                        .foregroundColor(.accentPurple)
                                }
                            }
                            Spacer()
                            Text(L10n.active)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section {
                    Button {
                        tempCuisine = nil
                        tempMealType = nil
                    } label: {
                        HStack {
                            Spacer()
                            Text(L10n.resetFilters)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(L10n.filters)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                tempCuisine = presenter.selectedCuisine
                tempMealType = presenter.selectedMealType
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.apply) {
                        presenter.selectedCuisine = tempCuisine
                        presenter.selectedMealType = tempMealType
                        Task {
                            await presenter.loadRecipes()
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
