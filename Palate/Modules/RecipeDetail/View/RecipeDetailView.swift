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
                    AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 300)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if let cuisine = recipe.cuisine {
                                Text(cuisine)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
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
                                Task{
                                    await shoppingListPresenter.checkAndAddRecipe(recipe)
                                }
                            }
                        }
                        .padding(.vertical)
                        
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
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await presenter.loadRecipe()
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
                Task {
                    await shoppingListPresenter.confirmAddWholeRecipe()
                }
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
