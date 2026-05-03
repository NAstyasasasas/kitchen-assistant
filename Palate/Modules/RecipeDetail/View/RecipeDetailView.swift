//
//  RecipeDetailView.swift
//  Palate
//

import SwiftUI

struct RecipeDetailView: View {
    @StateObject var presenter: RecipeDetailPresenter
    @ObservedObject var shoppingListPresenter: ShoppingListPresenter
    
    var body: some View {
        ScrollView {
            if presenter.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if let recipe = presenter.recipe {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                        }
                        .frame(height: 300)
                        .clipped()
                        
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if let cuisine = recipe.cuisine {
                                Text(cuisine)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding()
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        if presenter.userRecipe?.status == "cooked" {
                            HStack {
                                ForEach(1..<6) { star in
                                    Image(systemName: star <= presenter.rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .onTapGesture {
                                            presenter.rating = star
                                            Task { await presenter.saveRating(star) }
                                        }
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        if presenter.userRecipe?.status != "cooked" {
                            HStack(spacing: 16) {
                                ActionButton(
                                    title: L10n.wantToCook,
                                    icon: "bookmark",
                                    color: .accentPurple,
                                    isActive: presenter.isInWantToCook
                                ) {
                                    Task {
                                        await presenter.addToWantToCook()
                                    }
                                }
                                
                                ActionButton(
                                    title: L10n.addToCart,
                                    icon: "cart.badge.plus",
                                    color: .accentGreen,
                                    isActive: false
                                ) {
                                    if let recipe = presenter.recipe {
                                        shoppingListPresenter.checkAndAddRecipe(recipe)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                        
                        if let dateCooked = presenter.userRecipe?.dateCooked,
                           presenter.userRecipe?.status == "cooked" {
                            Text("\(L10n.cookedOn): \(dateCooked.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.accentPurple)
                        }
                        
                        Text(L10n.ingredients)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        IngredientsView(ingredients: recipe.ingredients)
                        
                        Text(L10n.instructions)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        if let instructions = recipe.instructions, !instructions.isEmpty {
                            InstructionsView(instructions: instructions)
                        } else {
                            Text(L10n.noInstructions)
                                .foregroundColor(.gray)
                                .padding()
                        }
                        
                        if presenter.userRecipe?.status == "cooked" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.myNotes)
                                    .font(.headline)
                                TextEditor(text: $presenter.notes)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .onChange(of: presenter.notes) { _ in
                                        Task { await presenter.saveNotes(presenter.notes) }
                                    }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await presenter.loadRecipe()
            await presenter.loadUserRecipeStatus()
        }
        .alert(L10n.errorGeneral, isPresented: .constant(presenter.errorMessage != nil)) {
            Button("OK") {
                presenter.errorMessage = nil
            }
        } message: {
            Text(presenter.errorMessage ?? "")
        }
        .alert(L10n.recipeConfirmationTitle,
               isPresented: $shoppingListPresenter.showRecipeConfirmation) {
            Button(L10n.recipeConfirmationAddAgain) {
                shoppingListPresenter.confirmAddWholeRecipe()
            }
            Button(L10n.cancel, role: .cancel) { }
        } message: {
            Text(L10n.recipeConfirmationMessageSimple)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isActive ? "\(icon).fill" : icon)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isActive ? color.opacity(0.2) : color.opacity(0.15))
            .foregroundColor(isActive ? color : color)
            .cornerRadius(10)
        }
        .disabled(isActive)
    }
}

struct IngredientsView: View {
    let ingredients: [Ingredient]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(ingredients) { ingredient in
                HStack {
                    Text("•")
                        .foregroundColor(.accentPurple)
                    Text(ingredient.name)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(ingredient.amount) \(ingredient.unit)")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
                
                if ingredient.id != ingredients.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct InstructionsView: View {
    let instructions: String
    
    var body: some View {
        let steps = instructions.components(separatedBy: "\r\n")
            .filter { !$0.isEmpty }
        
        VStack(alignment: .leading, spacing: 16) {
            if steps.isEmpty {
                Text(instructions)
                    .font(.body)
            } else {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .frame(width: 30, height: 30)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Circle())
                        
                        Text(step)
                            .font(.body)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
