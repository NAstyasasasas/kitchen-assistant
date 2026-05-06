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
    let onBookmarkTap: (Recipe) -> Void
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
                        translatedCategory: translatedCategories[recipe.category ?? ""],
                        onBookmarkTap: {
                            onBookmarkTap(recipe)
                        }
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
    @State private var translatedApiTexts: [String: String] = [:]
    
    private func displayApiText(_ text: String) -> String {
        guard LanguageManager.shared.isRussian else { return text }
        return translatedApiTexts[text] ?? text
    }

    private func translateApiTextIfNeeded(_ text: String) {
        guard LanguageManager.shared.isRussian else { return }
        guard translatedApiTexts[text] == nil else { return }
        guard text != "All" else {
            translatedApiTexts[text] = L10n.all
            return
        }

        Task {
            let translated = await YandexTranslateService.shared.translateIfNeeded(text)
            await MainActor.run {
                translatedApiTexts[text] = translated
            }
        }
    }
    
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
                            ForEach(presenter.apiCategories.prefix(10), id: \.self) { category in
                                FilterChip(
                                    title: displayApiText(category),
                                    isSelected: presenter.selectedApiCategory == category
                                ) {
                                    presenter.selectedApiCategory = category
                                    presenter.selectedApiCuisine = "All"

                                    Task {
                                        await presenter.applyApiFilters()
                                    }
                                }
                                .onAppear {
                                    translateApiTextIfNeeded(category)
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
                            
                            RecipeCardGrid(
                                recipes: presenter.searchResults,
                                onTap: { recipeId in
                                    presenter.didSelectRecipe(recipeId)
                                },
                                onBookmarkTap: { recipe in
                                    Task {
                                        await presenter.toggleWantToCook(recipe: recipe)
                                    }
                                }
                            )
                        }
                    } else if presenter.filteredRecipes.isEmpty {
                        HomeEmptyState(message: presenter.errorMessage ?? L10n.noRecipes)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                if presenter.selectedApiCategory != "All" {
                                    Text(displayApiText(presenter.selectedApiCategory))
                                        .font(.system(size: 22, weight: .bold))
                                } else if presenter.selectedApiCuisine != "All" {
                                    Text(displayApiText(presenter.selectedApiCuisine))
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
                            
                            RecipeCardGrid(
                                recipes: presenter.filteredRecipes,
                                onTap: { recipeId in
                                    presenter.didSelectRecipe(recipeId)
                                },
                                onBookmarkTap: { recipe in
                                    Task {
                                        await presenter.toggleWantToCook(recipe: recipe)
                                    }
                                }
                            )
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
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                translatedApiTexts.removeAll()
            }
        }
    }
}

struct FilterSheetView: View {
    @ObservedObject var presenter: HomePresenter
    @Environment(\.dismiss) var dismiss

    @State private var tempCategory = "All"
    @State private var tempCuisine = "All"
    
    @State private var translatedApiTexts: [String: String] = [:]
    
    private func displayApiText(_ text: String) -> String {
        translatedApiTexts[text] ?? text
    }

    private func translateApiTextIfNeeded(_ text: String) {
        guard LanguageManager.shared.isRussian else { return }
        guard translatedApiTexts[text] == nil else { return }
        guard text != "All" else {
            translatedApiTexts[text] = L10n.all
            return
        }

        Task {
            let translated = await YandexTranslateService.shared.translateIfNeeded(text)
            await MainActor.run {
                translatedApiTexts[text] = translated
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(L10n.filters)
                        .font(.system(size: 28, weight: .regular))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.category)
                            .font(.system(size: 16, weight: .bold))
                        
                        FlowLayout(data: presenter.apiCategories, spacing: 10) { category in
                            filterChip(
                                title: category,
                                selected: tempCategory == category
                            ) {
                                tempCategory = category
                            }
                            .onAppear {
                                translateApiTextIfNeeded(category)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.cuisine)
                            .font(.system(size: 16, weight: .bold))
                        
                        FlowLayout(data: presenter.apiCuisines, spacing: 10) { cuisine in
                            filterChip(
                                title: cuisine,
                                selected: tempCuisine == cuisine
                            ) {
                                tempCuisine = cuisine
                            }
                            .onAppear {
                                translateApiTextIfNeeded(cuisine)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            tempCategory = "All"
                            tempCuisine = "All"
                        } label: {
                            Text(L10n.reset)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .foregroundColor(.primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.45), lineWidth: 1)
                                )
                        }
                        
                        Button {
                            presenter.selectedApiCategory = tempCategory
                            presenter.selectedApiCuisine = tempCuisine
                            
                            Task {
                                await presenter.applyApiFilters()
                                dismiss()
                            }
                        } label: {
                            Text(L10n.apply)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .foregroundColor(.white)
                                .background(Color.accentPurple)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .onAppear {
                tempCategory = presenter.selectedApiCategory
                tempCuisine = presenter.selectedApiCuisine
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                translatedApiTexts.removeAll()
            }
        }
    }

    private func filterChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(displayApiText(title))
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(selected ? Color.accentPurple : Color(.systemGray5))
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(17)
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height + spacing
                        }

                        let result = width
                        if item == data.last {
                            width = 0
                        } else {
                            width -= dimension.width + spacing
                        }

                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == data.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        totalHeight = geo.size.height
                    }
                    .onChange(of: geo.size.height) { newValue in
                        totalHeight = newValue
                    }
            }
        )
    }
}
