//
//  MealPlanView.swift
//  Palate
//

import SwiftUI
import FirebaseAuth

struct MealPlanView: View {
    @StateObject var presenter: MealPlanPresenter
    
    init(presenter: MealPlanPresenter) {
            _presenter = StateObject(wrappedValue: presenter)
        }
    
    @State private var currentWeekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
    @State private var translatedNames: [String: String] = [:]
    @State private var translatedCategories: [String: String] = [:]
    
    private var dayNames = [L10n.monday, L10n.tuesday, L10n.wednesday, L10n.thursday, L10n.friday, L10n.saturday, L10n.sunday]
    private var mealTypes: [(MealPlanMealType, String, String)] = [
        (.breakfast, L10n.breakfast, "sunrise.fill"),
        (.lunch, L10n.lunch, "sun.max.fill"),
        (.dinner, L10n.dinner, "moon.fill"),
        (.snack, L10n.snack, "apple.whole")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(Array(presenter.weekDays.enumerated()), id: \.offset) { index, date in
                            DayPlanRow(
                                dayName: dayNames[index],
                                date: date,
                                isSelected: presenter.selectedDate == date,
                                presenter: presenter,
                                mealTypes: mealTypes,
                                translatedNames: $translatedNames,
                                translatedCategories: $translatedCategories
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                presenter.loadWeekPlans(startOfWeek: currentWeekStart)
            }
            .onChange(of: currentWeekStart) { newValue in
                presenter.loadWeekPlans(startOfWeek: newValue)
            }
            .sheet(isPresented: $presenter.showRecipePicker) {
                RecipeSelectionSheet(presenter: presenter)
            }
            .alert(L10n.ingredientsAlreadyInList, isPresented: $presenter.showConflictAlert) {
                Button(L10n.addAgain) {
                    presenter.confirmAddToShoppingList()
                }
                Button(L10n.cancel, role: .cancel) { }
            } message: {
                Text(L10n.ingredientsAlreadyInListMessage)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            Text(L10n.planTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack {
                Button {
                    currentWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Spacer()
                
                Text(weekRangeString)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    currentWeekStart = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            .padding(.horizontal, 24)
            
            Button {
                Task { await presenter.collectShoppingList() }
            } label: {
                HStack {
                    Image(systemName: "cart.badge.plus")
                    Text(L10n.collectShoppingList)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentGreen)
                .foregroundColor(.white)
                .cornerRadius(30)
                .padding(.horizontal, 12)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    private var weekRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        let start = formatter.string(from: currentWeekStart)
        let end = formatter.string(from: Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart)!)
        return "\(start)–\(end)"
    }
}

struct DayPlanRow: View {
    let dayName: String
    let date: Date
    let isSelected: Bool
    @ObservedObject var presenter: MealPlanPresenter
    let mealTypes: [(MealPlanMealType, String, String)]
    @Binding var translatedNames: [String: String]
    @Binding var translatedCategories: [String: String]
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM"
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dayName.uppercased())
                    .font(.system(size: 14, weight: .bold))

                Spacer()

                Text(dateFormatter.string(from: date))
                    .font(.system(size: 13, weight: .bold))
            }
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(Color(.systemGray6))
            .cornerRadius(6)

            HStack(spacing: 8) {
                ForEach(mealTypes, id: \.0) { mealType, title, _ in
                    VStack(spacing: 6) {
                        Text(title.uppercased())
                            .font(.system(size: 12, weight: .bold))

                        MealSlotCard(
                            recipeId: presenter.recipeId(for: date, mealType: mealType),
                            onTap: { presenter.selectSlot(date: date, mealType: mealType) },
                            onRecipeTap: { presenter.openRecipe(recipeId: $0) },
                            onRemove: { presenter.removeRecipe(date: date, mealType: mealType) },
                            translatedNames: $translatedNames,
                            translatedCategories: $translatedCategories
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct MealSlotCard: View {
    let recipeId: String?
    let onTap: () -> Void
    let onRecipeTap: ((String) -> Void)?
    let onRemove: (() -> Void)?
    @Binding var translatedNames: [String: String]
    @Binding var translatedCategories: [String: String]
    
    @State private var recipe: Recipe?
    @State private var isLoading = false
    @State private var translatedRecipeName: String?
    @State private var translatedCategory: String?
    
    var body: some View {
        Button {
            if let recipeId = recipeId {
                onRecipeTap?(recipeId)
            } else {
                onTap()
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    if let recipe = recipe {
                        AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#EEE8F2"))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(Color(.secondaryLabel).opacity(0.35))
                                    )
                            }
                        }
                        .frame(height: 82)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(8)

                        Button {
                            onRemove?()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(5)
                                .background(Color(.systemBackground).opacity(0.85))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(4)

                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentPurple, style: StrokeStyle(lineWidth: 1.2, dash: [4]))
                            .frame(height: 82)
                            .overlay(
                                VStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .medium))
                                    Text(L10n.select)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.accentPurple)
                            )
                    }
                }

                if let recipe = recipe {
                    Text(translatedRecipeName ?? recipe.name)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)

                    Text(translatedCategory ?? (recipe.category ?? ""))
                        .font(.system(size: 11))
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
                } else {
                    Spacer(minLength: 0)
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity)
            .frame(height: 142)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.secondaryLabel).opacity(0.45), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .task(id: recipeId) {
            await loadRecipe()
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            translatedRecipeName = nil
            translatedCategory = nil

            if let recipe = recipe {
                Task {
                    await translateRecipe(recipe)
                }
            }
        }
    }
    
    private func loadRecipe() async {
        guard let recipeId = recipeId else {
            recipe = nil
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let isCustom = recipeId.count == 36 && recipeId.contains("-")
        
        if isCustom {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let custom = CoreDataManager.shared.fetchCustomRecipes(byUserId: userId)
                .first(where: { $0.id?.uuidString == recipeId })
            
            if let custom = custom {
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
                
                let fetchedRecipe = Recipe(
                    id: recipeId,
                    source: .custom,
                    name: custom.name ?? "",
                    category: custom.category,
                    cuisine: custom.cuisine,
                    imageUrl: custom.imageUrl,
                    ingredients: ingredients,
                    instructions: custom.instructions
                )
                
                await MainActor.run {
                    recipe = fetchedRecipe
                }
                
                await translateRecipe(fetchedRecipe)
            }
        } else {
            do {
                let fetched = try await APIService.shared.fetchRecipeDetail(id: recipeId)
                await MainActor.run {
                    recipe = fetched
                }
                await translateRecipe(fetched)
            } catch {
                print("❌ Failed to load API recipe \(recipeId): \(error)")
            }
        }
    }
    
    private func translateRecipe(_ recipe: Recipe) async {
        let lang = LanguageManager.shared.appLanguage.rawValue
        
        async let name = try? YandexTranslateService.shared.translate(
            text: recipe.name,
            to: lang
        )
        
        async let category = try? YandexTranslateService.shared.translate(
            text: recipe.category ?? "",
            to: lang
        )
        
        let (translatedName, translatedCat) = await (name, category)
        
        await MainActor.run {
            translatedRecipeName = translatedName ?? recipe.name
            translatedCategory = translatedCat ?? recipe.category
        }
    }
}
