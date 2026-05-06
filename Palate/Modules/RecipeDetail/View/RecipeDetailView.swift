//
//  RecipeDetailView.swift
//  Palate
//

import SwiftUI

struct RecipeDetailView: View {
    @StateObject var presenter: RecipeDetailPresenter
    @ObservedObject var shoppingListPresenter: ShoppingListPresenter
    @State private var translatedInstructions: String?
    @State private var isTranslating = false
    @State private var hasAttemptedAutoTranslate = false
    @State private var translatedIngredients: [Ingredient]?
    @State private var translatedRecipeName: String?
    @State private var translatedCuisine: String?
    
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
                                    .fill(Color(.secondaryLabel).opacity(0.3))
                            }
                        }
                        .frame(height: 310)
                        .clipped()
                        
                        LinearGradient(
                            colors: [.clear, Color(.label).opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(translatedRecipeName ?? recipe.name)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let cuisine = recipe.cuisine {
                                Text(translatedCuisine ?? cuisine)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
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
                            .padding(.horizontal, 24)
                            .padding(.top, 28)
                        }
                        
                        if presenter.userRecipe?.status != "cooked" {
                            HStack(spacing: 16) {
                                ActionButton(
                                    title: L10n.wantToCook,
                                    icon: "bookmark",
                                    color: .accentPurple,
                                    isActive: presenter.isWantToCook
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
                            .frame(maxWidth: .infinity)
                        }
                        
                        if let dateCooked = presenter.userRecipe?.dateCooked,
                           presenter.userRecipe?.status == "cooked" {

                            VStack(alignment: .leading, spacing: 6) {
                                Text(L10n.cookedOn)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(.secondaryLabel))

                                Text(formattedDate)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.accentPurple)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                        }
                        
                        SectionHeaderBar(title: L10n.ingredients)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        IngredientsView(ingredients: translatedIngredients ?? recipe.ingredients)
                        
                        SectionHeaderBar(title: L10n.instructions)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        
                        if let instructions = recipe.instructions, !instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                if isTranslating {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .font(.caption)
                                            .foregroundColor(Color(.secondaryLabel))
                                    }
                                    .padding(.leading, 4)
                                }
                                
                                InstructionsView(instructions: translatedInstructions ?? instructions)
                            }
                        } else {
                            Text(L10n.noInstructions)
                                .foregroundColor(Color(.secondaryLabel))
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
            await autoTranslateIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            hasAttemptedAutoTranslate = false
            translatedRecipeName = nil
            translatedCuisine = nil
            translatedInstructions = nil
            translatedIngredients = nil

            Task {
                await autoTranslateIfNeeded()
            }
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
    
    var formattedDate: String {
        guard let date = presenter.userRecipe?.dateCooked else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func autoTranslateIfNeeded() async {
        guard let recipe = presenter.recipe else { return }

        let targetLang = LanguageManager.shared.appLanguage.rawValue

        if targetLang == "en" {
            await MainActor.run {
                translatedRecipeName = nil
                translatedCuisine = nil
                translatedInstructions = nil
                translatedIngredients = nil
                isTranslating = false
            }
            return
        }

        await MainActor.run {
            isTranslating = true
        }

        async let name = YandexTranslateService.shared.translateIfNeeded(recipe.name)
        async let cuisine = YandexTranslateService.shared.translateIfNeeded(recipe.cuisine ?? "")
        async let instructions = YandexTranslateService.shared.translateIfNeeded(recipe.instructions ?? "")
        async let ingredients = translateIngredientsArray(recipe.ingredients)

        let result = await (name, cuisine, instructions, ingredients)

        await MainActor.run {
            translatedRecipeName = result.0
            translatedCuisine = result.1
            translatedInstructions = result.2
            translatedIngredients = result.3
            isTranslating = false
        }
    }
    
    private func translateIngredientsArray(_ ingredients: [Ingredient]) async -> [Ingredient] {
        var result: [Ingredient] = []

        for ingredient in ingredients {
            let translatedName = await YandexTranslateService.shared.translateIfNeeded(ingredient.name)

            result.append(
                Ingredient(
                    name: translatedName,
                    amount: ingredient.amount,
                    unit: ingredient.unit
                )
            )
        }

        return result
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
            HStack(spacing: 10) {
                Image(systemName: isActive ? "\(icon).fill" : icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct IngredientsView: View {
    let ingredients: [Ingredient]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            ForEach(ingredients) { ingredient in
                Text("•   \(ingredient.name) — \(ingredient.amount) \(ingredient.unit)")
                    .font(.system(size: 18))
                    .foregroundColor(Color(.label))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
    }
}

struct InstructionsView: View {
    let instructions: String

    var body: some View {
        let steps = instructions
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { step in
                step
                    .replacingOccurrences(of: #"(?i)^step\s*\d+\s*"#, with: "", options: .regularExpression)
            }

        VStack(alignment: .leading, spacing: 32) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(alignment: .leading, spacing: 18) {
                    Text("step \(index + 1)")
                        .font(.system(size: 18))
                        .foregroundColor(Color(.label))

                    Text(step)
                        .font(.system(size: 18))
                        .lineSpacing(8)
                        .foregroundColor(Color(.label))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 22)
    }
}

struct SectionHeaderBar: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(Color(.label))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 56)
            .padding(.horizontal, 24)
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}
