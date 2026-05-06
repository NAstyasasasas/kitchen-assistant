//
//  MyRecipesView.swift
//  Palate
//

import SwiftUI

struct MyRecipesView: View {
    @StateObject var presenter: MyRecipesPresenter
    @State private var selectedTab = 0
    @State private var translatedNames: [String: String] = [:]
    @State private var translatedCategories: [String: String] = [:]
    @State private var recipeToDelete: (id: String, from: String)?
    @State private var showDeleteAlert = false
    @State private var notesRecipe: UserRecipe?
    @State private var showNotesSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text(L10n.myCollection)
                    .font(.system(size: 28, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                HStack(spacing: 16) {
                    UnderlineTab(title: L10n.wantToCook, isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }

                    UnderlineTab(title: L10n.cooked, isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }

                    UnderlineTab(title: L10n.myRecipes, isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                }
                .padding(.horizontal, 16)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(.secondaryLabel).opacity(0.25))
                        .frame(height: 1)
                }
                .padding(.bottom, 8)
                
                TabView(selection: $selectedTab) {
                    wantToCookTab.tag(0)
                    cookedTab.tag(1)
                    myRecipesTab.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .onAppear {
                presenter.loadData()
            }
            .alert(L10n.delete, isPresented: $showDeleteAlert) {
                Button(L10n.delete, role: .destructive) {
                    if let item = recipeToDelete {
                        presenter.deleteRecipe(recipeId: item.id, from: item.from)
                        recipeToDelete = nil
                    }
                }

                Button(L10n.cancel, role: .cancel) {
                    recipeToDelete = nil
                }
            } message: {
                Text(L10n.deleteRecipeIn)
            }
            .sheet(isPresented: $showNotesSheet) {
                if let notesRecipe = notesRecipe {
                    NavigationView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.myNotes)
                                .font(.system(size: 22, weight: .bold))

                            Text(notesRecipe.notes ?? "")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding()
                        .navigationTitle(L10n.myNotes)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(L10n.ok) {
                                    showNotesSheet = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func cookedRecipeRow(recipe: Recipe, userRecipe: UserRecipe) -> some View {
        CookedCard(
            recipe: recipe,
            translatedName: translatedNames[recipe.id],
            translatedCategory: translatedCategories[recipe.category ?? ""],
            rating: Int(userRecipe.rating),
            dateCooked: userRecipe.dateCooked,
            onNotes: {
                presenter.didSelectRecipe(recipe)
            },
            onDelete: {
                recipeToDelete = (recipe.id, "cooked")
                showDeleteAlert = true
            },
            onTap: {
                presenter.didSelectRecipe(recipe)
            },
            onRatingChanged: { newRating in
                presenter.updateRating(recipeId: recipe.id, rating: newRating)
            }
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
        .onAppear {
            Task {
                await translateIfNeeded(
                    recipe: recipe,
                    nameKey: recipe.id,
                    categoryKey: recipe.category ?? ""
                )
            }
        }
    }
    
    private func translateIfNeeded(recipe: Recipe, nameKey: String, categoryKey: String) async {
        
        if translatedNames[nameKey] == nil {
            let translatedName = await YandexTranslateService.shared.translateIfNeeded(recipe.name)
            await MainActor.run {
                translatedNames[nameKey] = translatedName
            }
        }
        
        if let category = recipe.category, translatedCategories[categoryKey] == nil {
            let translatedCategory = await YandexTranslateService.shared.translateIfNeeded(category)
            await MainActor.run {
                translatedCategories[categoryKey] = translatedCategory
            }
        }
    }
    
    @ViewBuilder
    private var wantToCookTab: some View {
        if presenter.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if presenter.wantToCookRecipes.isEmpty {
            emptyStateView(text: L10n.noRecipesWant)
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(presenter.wantToCookRecipes, id: \.id) { recipe in
                        WantToCookCard(
                            recipe: recipe,
                            translatedName: translatedNames[recipe.id],
                            translatedCategory: translatedCategories[recipe.category ?? ""],
                            onCook: { presenter.markAsCooked(recipeId: recipe.id) },
                            onDelete: {
                                recipeToDelete = (recipe.id, "wantToCook")
                                showDeleteAlert = true },
                            onTap: { presenter.didSelectRecipe(recipe) }
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .onAppear {
                            Task {
                                await translateIfNeeded(recipe: recipe, nameKey: recipe.id, categoryKey: recipe.category ?? "")
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    @ViewBuilder
    private var cookedTab: some View {
        if presenter.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if presenter.cookedRecipes.isEmpty {
            emptyStateView(text: L10n.noRecipesCooked)
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(zip(presenter.cookedRecipes, presenter.cookedUserRecipes)), id: \.0.id) { recipe, userRecipe in
                        cookedRecipeRow(recipe: recipe, userRecipe: userRecipe)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    @ViewBuilder
    private var myRecipesTab: some View {
        ZStack {
            if presenter.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if presenter.myRecipes.isEmpty {
                emptyStateView(text: L10n.noRecipesCustom)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(presenter.myRecipes, id: \.id) { recipe in
                            MyRecipeCard(
                                recipe: recipe,
                                translatedName: translatedNames[recipe.id],
                                translatedCategory: translatedCategories[recipe.category ?? ""],
                                onEdit: { presenter.editRecipe(recipe) },
                                onDelete: { presenter.deleteCustomRecipe(recipeId: recipe.id) },
                                onTap: { presenter.didSelectRecipe(recipe) }
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 2)
                            .onAppear {
                                Task {
                                    await translateIfNeeded(recipe: recipe, nameKey: recipe.id, categoryKey: recipe.category ?? "")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { presenter.createRecipe() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.accentGreen)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    private func emptyStateView(text: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(Color(.secondaryLabel))
            Text(text)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct WantToCookCard: View {
    let recipe: Recipe
    let translatedName: String?
    let translatedCategory: String?
    let onCook: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                recipeImage

                VStack(alignment: .leading, spacing: 3) {
                    Text(translatedName ?? recipe.name)
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(1)

                    Text(translatedCategory ?? (recipe.category ?? ""))
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel).opacity(0.8))
                        .lineLimit(1)

                    Button(action: onCook) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                            Text(L10n.cooked)
                        }
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.accentGreen)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .frame(height: 120)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentGreen.opacity(0.7), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var recipeImage: some View {
        AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondaryLabel).opacity(0.2))
            }
        }
        .frame(width: 92, height: 92)
        .clipped()
        .cornerRadius(8)
    }
}

struct CookedCard: View {
    let recipe: Recipe
    let translatedName: String?
    let translatedCategory: String?
    let rating: Int
    let dateCooked: Date?
    let onNotes: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    let onRatingChanged: (Int) -> Void

    @State private var localRating: Int

    init(recipe: Recipe, translatedName: String?, translatedCategory: String?, rating: Int, dateCooked: Date?, onNotes: @escaping () -> Void, onDelete: @escaping () -> Void, onTap: @escaping () -> Void, onRatingChanged: @escaping (Int) -> Void) {
        self.recipe = recipe
        self.translatedName = translatedName
        self.translatedCategory = translatedCategory
        self.rating = rating
        self.dateCooked = dateCooked
        self.onNotes = onNotes
        self.onDelete = onDelete
        self.onTap = onTap
        self.onRatingChanged = onRatingChanged
        _localRating = State(initialValue: rating)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                recipeImage

                VStack(alignment: .leading, spacing: 3) {
                    Text(translatedName ?? recipe.name)
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(1)

                    Text(translatedCategory ?? (recipe.category ?? ""))
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel).opacity(0.8))
                        .lineLimit(1)

                    HStack(spacing: 1) {
                        ForEach(1..<6) { star in
                            Image(systemName: star <= localRating ? "star.fill" : "star")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    localRating = star
                                    onRatingChanged(star)
                                }
                        }
                    }

                    if let date = dateCooked {
                        Text("\(L10n.cookedOn): \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryLabel))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button(action: onNotes) {
                    Image(systemName: "note.text")
                        .font(.system(size: 17))
                        .foregroundColor(.accentPurple)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .frame(height: 120)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentGreen.opacity(0.7), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .onAppear {
            localRating = rating
        }
    }

    private var recipeImage: some View {
        AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondaryLabel).opacity(0.2))
            }
        }
        .frame(width: 92, height: 92)
        .clipped()
        .cornerRadius(8)
    }
}

struct MyRecipeCard: View {
    let recipe: Recipe
    let translatedName: String?
    let translatedCategory: String?
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                recipeImage

                VStack(alignment: .leading, spacing: 3) {
                    Text(translatedName ?? recipe.name)
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(1)

                    Text(translatedCategory ?? (recipe.category ?? ""))
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel).opacity(0.8))
                        .lineLimit(1)

                    Button(action: onEdit) {
                        HStack(spacing: 5) {
                            Image(systemName: "pencil")
                            Text(L10n.editRecipe)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.accentGreen)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .frame(height: 120)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var recipeImage: some View {
        AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondaryLabel).opacity(0.2))
            }
        }
        .frame(width: 92, height: 92)
        .clipped()
        .cornerRadius(8)
    }
}
struct UnderlineTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? .accentPurple : Color(.label).opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Rectangle()
                    .fill(isSelected ? Color.accentPurple : Color.clear)
                    .frame(height: 4)
                    .cornerRadius(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.plain)
    }
}

