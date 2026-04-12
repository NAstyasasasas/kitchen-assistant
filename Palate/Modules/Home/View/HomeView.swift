//
//  HomeView.swift
//  Palate
//

import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.accentPurple : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct RecipeCardGrid: View {
    let recipes: [Recipe]
    let onTap: (String) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(recipes) { recipe in
                Button {
                    onTap(recipe.id)
                } label: {
                    RecipeCard(recipe: recipe)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}

struct HomeEmptyState: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text(message)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Text("Попробуйте изменить фильтры")
                .font(.caption)
                .foregroundColor(.gray)
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
                                title: "Все",
                                isSelected: presenter.selectedCuisine == nil && presenter.selectedMealType == nil
                            ) {
                                presenter.resetFilters()
                            }
                            
                            ForEach(CuisineType.allCases.prefix(6)) { cuisine in
                                FilterChip(
                                    title: cuisine.rawValue,
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
                            Text("Результаты поиска")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            RecipeCardGrid(recipes: presenter.searchResults) { recipeId in
                                presenter.didSelectRecipe(recipeId)
                            }
                        }
                    } else if presenter.filteredRecipes.isEmpty {
                        HomeEmptyState(message: presenter.errorMessage ?? "Нет рецептов")
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                if let cuisine = presenter.selectedCuisine {
                                    Text(cuisine.rawValue)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                } else if let mealType = presenter.selectedMealType {
                                    Text(mealType.rawValue)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                } else {
                                    Text("Рекомендации")
                                        .font(.title3)
                                        .fontWeight(.bold)
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
            .background(Color(.systemGray6))
            .navigationTitle("Palate")
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
                            Text("Любая кухня")
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
                                Text(cuisine.rawValue)
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
                        Text("Кухня")
                    }
                }
                
                Section {
                    Button {
                        tempMealType = nil
                    } label: {
                        HStack {
                            Text("Любой тип")
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
                                Text(mealType.rawValue)
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
                        Text("Тип блюда")
                    }
                }
                
                if tempCuisine != nil || tempMealType != nil {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let cuisine = tempCuisine {
                                    Text("Кухня: \(cuisine.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.accentPurple)
                                }
                                if let mealType = tempMealType {
                                    Text("Тип: \(mealType.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.accentPurple)
                                }
                            }
                            Spacer()
                            Text("Активны")
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
                            Text("Сбросить все фильтры")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                tempCuisine = presenter.selectedCuisine
                tempMealType = presenter.selectedMealType
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Применить") {
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
