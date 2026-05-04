//
//  MealPlanView.swift
//  Palate
//

import SwiftUI
import FirebaseAuth

struct MealPlanView: View {
    @StateObject var presenter: MealPlanPresenter
    @State private var currentWeekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
    
    private let dayNames = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
    private let mealTypes: [(MealPlanMealType, String, String)] = [
        (.breakfast, "Завтрак", "sunrise.fill"),
        (.lunch, "Обед", "sun.max.fill"),
        (.dinner, "Ужин", "moon.fill"),
        (.snack, "Перекус", "apple.whole")
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
                                mealTypes: mealTypes
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
            .alert("Продукты уже есть в списке", isPresented: $presenter.showConflictAlert) {
                Button("Добавить ещё раз") {
                    presenter.confirmAddToShoppingList()
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Ингредиенты уже были добавлены в список покупок. Добавить ещё раз?")
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            Text("План питания")
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
                    .font(.subheadline)
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
                    Text("Собрать список")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentGreen)
                .foregroundColor(.white)
                .cornerRadius(30)
                .padding(.horizontal, 24)
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
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM"
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(dateFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mealTypes, id: \.0) { mealType, title, iconName in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            
                            MealSlotCard(
                                recipeId: presenter.recipeId(for: date, mealType: mealType),
                                onTap: { presenter.selectSlot(date: date, mealType: mealType) },
                                onRecipeTap: { presenter.openRecipe(recipeId: $0) },
                                onRemove: { presenter.removeRecipe(date: date, mealType: mealType) }
                            )
                            .frame(width: 130)
                        }
                        .frame(width: 140)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.accentPurple : Color.clear, lineWidth: 2)
        )
    }
}

struct MealSlotCard: View {
    let recipeId: String?
    let onTap: () -> Void
    let onRecipeTap: ((String) -> Void)?
    let onRemove: (() -> Void)?
    
    @State private var recipe: Recipe?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let recipe = recipe {
                HStack {
                    Spacer()
                    Button {
                        onRemove?()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                    }
                    .padding(4)
                }
                .frame(height: 20)
                .padding(.top, 4)
                .padding(.trailing, 4)
            }
            
            Button {
                if let recipeId = recipeId {
                    onRecipeTap?(recipeId)
                } else {
                    onTap()
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        if let recipe = recipe {
                            AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                }
                            }
                            .frame(height: 90)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(12)
                        } else if isLoading {
                            ProgressView()
                                .frame(height: 90)
                                .frame(maxWidth: .infinity)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentPurple, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                .frame(height: 90)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundColor(.accentPurple)
                                        Text("Выбрать")
                                            .font(.caption)
                                            .foregroundColor(.accentPurple)
                                    }
                                )
                        }
                    }
                    .frame(height: 90)
                    
                    Group {
                        if isLoading {
                            ProgressView()
                                .frame(height: 55)
                        } else if let recipe = recipe {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                if let category = recipe.category {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            .frame(height: 55, alignment: .top)
                        } else {
                            Spacer()
                                .frame(height: 55)
                        }
                    }
                    .frame(height: 55)
                }
                .frame(width: 110, height: 170)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .task(id: recipeId) {
            await loadRecipe()
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
                
                await MainActor.run {
                    recipe = Recipe(
                        id: recipeId,
                        source: .custom,
                        name: custom.name ?? "",
                        category: custom.category,
                        cuisine: custom.cuisine,
                        imageUrl: custom.imageUrl,
                        ingredients: ingredients,
                        instructions: custom.instructions
                    )
                }
            }
        } else {
            do {
                let fetched = try await APIService.shared.fetchRecipeDetail(id: recipeId)
                await MainActor.run {
                    recipe = fetched
                }
            } catch {
                print("❌ Failed to load API recipe \(recipeId): \(error)")
            }
        }
    }
}
