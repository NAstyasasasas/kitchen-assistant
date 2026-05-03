//
//  MyRecipesView.swift
//  Palate
//

import SwiftUI

struct MyRecipesView: View {
    @StateObject var presenter: MyRecipesPresenter
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text(L10n.myCollection)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Picker("", selection: $selectedTab) {
                    Text(L10n.wantToCook).tag(0)
                    Text(L10n.cooked).tag(1)
                    Text(L10n.myRecipes).tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
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
                LazyVStack(spacing: 4) {
                    ForEach(presenter.wantToCookRecipes, id: \.id) { recipe in
                        WantToCookCard(
                            recipe: recipe,
                            onCook: { presenter.markAsCooked(recipeId: recipe.id) },
                            onDelete: { presenter.deleteRecipe(recipeId: recipe.id, from: "wantToCook") },
                            onTap: { presenter.didSelectRecipe(recipe.id) }
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 2)
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
                LazyVStack(spacing: 4) {
                    ForEach(Array(zip(presenter.cookedRecipes, presenter.cookedUserRecipes)), id: \.0.id) { recipe, userRecipe in
                        CookedCard(
                            recipe: recipe,
                            rating: Int(userRecipe.rating),
                            dateCooked: userRecipe.dateCooked,
                            onNotes: { /* показать заметки */ },
                            onDelete: { presenter.deleteRecipe(recipeId: recipe.id, from: "cooked") },
                            onTap: { presenter.didSelectRecipe(recipe.id) },
                            onRatingChanged: { newRating in
                                presenter.updateRating(recipeId: recipe.id, rating: newRating)
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    @ViewBuilder
    private var myRecipesTab: some View {
        if presenter.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if presenter.myRecipes.isEmpty {
            VStack {
                emptyStateView(text: L10n.noRecipesCustom)
                Button(L10n.createRecipe) {
                    // TODO: переход на CreateRecipeView
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(presenter.myRecipes, id: \.id) { recipe in
                        MyRecipeCard(
                            recipe: recipe,
                            onEdit: { /* TODO: редактировать */ },
                            onDelete: { presenter.deleteRecipe(recipeId: recipe.id, from: "myRecipes") },
                            onTap: { presenter.didSelectRecipe(recipe.id) }
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 2)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    @ViewBuilder
    private func emptyStateView(text: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text(text)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct WantToCookCard: View {
    let recipe: Recipe
    let onCook: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 70)
                    }
                }
                .frame(width: 70, height: 70)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(recipe.category ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onCook) {
                    Text(L10n.cooked)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CookedCard: View {
    let recipe: Recipe
    let rating: Int
    let dateCooked: Date?
    let onNotes: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    let onRatingChanged: (Int) -> Void
    @State private var localRating: Int

    init(recipe: Recipe, rating: Int, dateCooked: Date?, onNotes: @escaping () -> Void, onDelete: @escaping () -> Void, onTap: @escaping () -> Void, onRatingChanged: @escaping (Int) -> Void) {
        self.recipe = recipe
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
            HStack(alignment: .center, spacing: 12) {
                AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 70)
                    }
                }
                .frame(width: 70, height: 70)

                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(recipe.category ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)

                    HStack(spacing: 2) {
                        ForEach(1..<6) { star in
                            Image(systemName: star <= localRating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    localRating = star
                                    onRatingChanged(star)
                                }
                        }
                    }

                    if let date = dateCooked {
                        Text("\(L10n.cookedOn): \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Button(action: onNotes) {
                    Image(systemName: "note.text")
                        .font(.title3)
                        .foregroundColor(.accentPurple)
                }
                .buttonStyle(BorderlessButtonStyle())

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(10)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            localRating = rating
        }
    }
}

struct MyRecipeCard: View {
    let recipe: Recipe
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 70)
                    }
                }
                .frame(width: 70, height: 70)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(recipe.category ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
