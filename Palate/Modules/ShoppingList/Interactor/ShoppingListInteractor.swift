//
//  ShoppingListInteractor.swift
//  Palate
//

import Foundation
import CoreData
import FirebaseAuth
import FirebaseFirestore

protocol ShoppingListInteractorProtocol {
    func fetchItems() -> [ShoppingItem]
    func addItem(name: String, quantity: Double, unit: String)
    func updateItem(_ item: ShoppingItem)
    func deleteItem(_ item: ShoppingItem)
    func deleteAllItems()
    func toggleBought(_ item: ShoppingItem)
    func syncWithFirebase() async
    
    func recipeHasConflicts(_ recipe: Recipe) async -> Bool
    func addWholeRecipe(_ recipe: Recipe) async
}

protocol ShoppingListInteractorDelegate: AnyObject {
    func didDetectDuplicate()
}

final class ShoppingListInteractor: ShoppingListInteractorProtocol {
    private let context = CoreDataManager.shared.viewContext
    private let db = Firestore.firestore()
    
    private var userId: String? { Auth.auth().currentUser?.uid }
    weak var delegate: ShoppingListInteractorDelegate?
    
    func fetchItems() -> [ShoppingItem] {
        let request: NSFetchRequest<ShoppingItem> = ShoppingItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "isBought", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch: \(error)")
            return []
        }
    }
    
    func addItem(name: String, quantity: Double, unit: String) {
        let existingItems = fetchItems()

        if existingItems.contains(where: {
            normalize($0.name) == normalize(name) && !$0.isBought
        }) {
            delegate?.didDetectDuplicate()
            return
        }

        let item = ShoppingItem(context: context)
        item.id = UUID()
        item.name = name
        item.quantity = quantity
        item.unit = unit
        item.isBought = false
        item.createdAt = Date()

        saveContext()

        Task {
            await syncToFirestore(item: item)
        }
    }
    
    func updateItem(_ item: ShoppingItem) {
        saveContext()
        Task { await syncToFirestore(item: item) }
    }
    
    func deleteItem(_ item: ShoppingItem) {
        Task { await deleteFromFirestore(item: item) }
        context.delete(item)
        saveContext()
    }
    
    func deleteAllItems() {
        let items = fetchItems()
        for item in items {
            Task { await deleteFromFirestore(item: item) }
            context.delete(item)
        }
        saveContext()
    }
    
    func toggleBought(_ item: ShoppingItem) {
        item.isBought.toggle()
        saveContext()
        Task { await syncToFirestore(item: item) }
    }
    
    private func displayNameForShoppingList(_ name: String) async -> String {
        if LanguageManager.shared.isRussian {
            return await YandexTranslateService.shared.translateIfNeeded(name)
        } else {
            return name
        }
    }
    
    func recipeHasConflicts(_ recipe: Recipe) async -> Bool {
        let existingItems = fetchItems()

        for ingredient in recipe.ingredients {
            let finalName = await displayNameForShoppingList(ingredient.name)
            let (_, unit, isNumeric) = parseIngredient(ingredient)

            let name = normalize(finalName)
            let normalizedUnit = normalize(LanguageManager.shared.isRussian ? translateUnit(unit) : unit)

            if isNumeric {
                let exists = existingItems.contains { item in
                    normalize(item.name) == name &&
                    normalize(item.unit) == normalizedUnit &&
                    !item.isBought
                }
                if exists { return true }
            } else {
                let exists = existingItems.contains { item in
                    normalize(item.name) == name &&
                    !item.isBought
                }
                if exists { return true }
            }
        }

        return false
    }
    
    private func normalize(_ text: String?) -> String {
        text?
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""
    }
    
    func addWholeRecipe(_ recipe: Recipe) async {
        var existingItems = fetchItems()
        let shouldTranslate = LanguageManager.shared.isRussian
        

        for ingredient in recipe.ingredients {
            var finalName = ingredient.name
            var finalUnit = ""
            
            if shouldTranslate {
                do {
                    finalName = try await YandexTranslateService.shared.translate(text: ingredient.name, to: "ru")
                } catch {
                    print("Ошибка перевода: \(error)")
                }
            }
            
            let (quantity, unit, isNumeric) = parseIngredient(ingredient)
            let normalizedName = finalName.lowercased().trimmingCharacters(in: .whitespaces)
            
            if isNumeric && !unit.isEmpty && shouldTranslate {
                finalUnit = translateUnit(unit)
                print("📏 \(unit) → \(finalUnit)")
            } else {
                finalUnit = unit
            }
            let normalizedUnit = finalUnit.lowercased().trimmingCharacters(in: .whitespaces)

            if isNumeric && quantity > 0 {
                if let existing = existingItems.first(where: {
                    normalize($0.name) == normalizedName &&
                    normalize($0.unit) == normalizedUnit &&
                    !$0.isBought
                }) {
                    existing.quantity += quantity
                    updateItem(existing)
                } else {
                    addItem(name: finalName, quantity: quantity, unit: finalUnit)
                    existingItems.append(fetchItems().last!)
                }
            } else {
                let amountTrimmed = ingredient.amount.trimmingCharacters(in: .whitespaces)
                if let doubleQuantity = Double(amountTrimmed), doubleQuantity > 0 {
                    if let existing = existingItems.first(where: {
                        normalize($0.name) == normalizedName &&
                        normalize($0.unit) == normalizedUnit &&
                        !$0.isBought
                    }) {
                        existing.quantity += doubleQuantity
                        updateItem(existing)
                    } else {
                        addItem(name: finalName, quantity: doubleQuantity, unit: finalUnit)
                        existingItems.append(fetchItems().last!)
                    }
                } else {
                    if existingItems.contains(where: { normalize($0.name) == normalizedName && !$0.isBought }) {
                    } else {
                        addItem(name: finalName, quantity: 0, unit: finalUnit)
                        existingItems.append(fetchItems().last!)
                    }
                }
            }
        }
    }
    
    private func parseIngredient(_ ingredient: Ingredient) -> (quantity: Double, unit: String, isNumeric: Bool) {
        let amount = ingredient.amount.trimmingCharacters(in: .whitespaces)
        let pattern = "^(\\d+(?:\\.\\d+)?(?:\\/\\d+)?)\\s*([a-zA-Zа-яА-Я/\\.]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: amount, range: NSRange(amount.startIndex..., in: amount)) else {
            return (0, "", false)
        }
        
        if let quantityRange = Range(match.range(at: 1), in: amount),
           let unitRange = Range(match.range(at: 2), in: amount) {
            let quantityString = String(amount[quantityRange])
            let rawUnit = String(amount[unitRange])
            let normalizedUnit = rawUnit.lowercased().trimmingCharacters(in: .whitespaces)
            
            let quantity: Double
            if quantityString.contains("/") {
                let parts = quantityString.split(separator: "/")
                if parts.count == 2,
                   let numerator = Double(parts[0]),
                   let denominator = Double(parts[1]), denominator != 0 {
                    quantity = numerator / denominator
                } else {
                    quantity = 0
                }
            } else {
                quantity = Double(quantityString) ?? 0
            }
            return (quantity, normalizedUnit, true)
        }
        return (0, "", false)
    }
    
    private func saveContext() {
        CoreDataManager.shared.save()
    }
    
    private func collectionRef() throws -> CollectionReference {
        guard let userId = userId else { throw AuthError.networkError }
        return db.collection("users").document(userId).collection("shoppingList")
    }
    
    private func syncToFirestore(item: ShoppingItem) async {
        guard let id = item.id?.uuidString else { return }
        do {
            try await collectionRef().document(id).setData([
                "name": item.name ?? "",
                "quantity": item.quantity,
                "unit": item.unit ?? "",
                "isBought": item.isBought,
                "createdAt": Timestamp(date: item.createdAt ?? Date())
            ])
        } catch {
            print("❌ Firestore sync error: \(error)")
        }
    }
    
    private func deleteFromFirestore(item: ShoppingItem) async {
        guard let id = item.id?.uuidString else { return }
        do {
            try await collectionRef().document(id).delete()
        } catch {
            print("❌ Firestore delete error: \(error)")
        }
    }
    
    func syncWithFirebase() async {
        guard userId != nil else { return }
        do {
            let snapshot = try await collectionRef().getDocuments()
            let localItems = fetchItems()
            let localIds = Set(localItems.compactMap { $0.id?.uuidString })
            let remoteIds = Set(snapshot.documents.map { $0.documentID })
            
            for item in localItems {
                if let id = item.id?.uuidString, !remoteIds.contains(id) {
                    context.delete(item)
                }
            }
            
            for doc in snapshot.documents {
                let data = doc.data()
                let name = data["name"] as? String ?? ""
                let quantity = data["quantity"] as? Double ?? 0
                let unit = data["unit"] as? String ?? ""
                let isBought = data["isBought"] as? Bool ?? false
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                
                if let localItem = localItems.first(where: { $0.id?.uuidString == doc.documentID }) {
                    if localItem.isBought != isBought {
                        localItem.isBought = isBought
                    }
                } else {
                    let newItem = ShoppingItem(context: context)
                    newItem.id = UUID(uuidString: doc.documentID)
                    newItem.name = name
                    newItem.quantity = quantity
                    newItem.unit = unit
                    newItem.isBought = isBought
                    newItem.createdAt = createdAt
                }
            }
            saveContext()
        } catch {
            print("❌ Firestore sync error: \(error)")
        }
    }
    
    private let unitTranslations: [String: String] = [
        "cup": "чашка", "cups": "чашки",
        "tbsp": "ст.л.", "tablespoon": "столовая ложка", "tablespoons": "столовые ложки",
        "tsp": "ч.л.", "teaspoon": "чайная ложка", "teaspoons": "чайные ложки",
        "ml": "мл", "milliliter": "миллилитр", "milliliters": "миллилитры",
        "l": "л", "liter": "литр", "liters": "литры",
        "g": "г", "gram": "грамм", "grams": "граммов",
        "kg": "кг", "kilogram": "килограмм", "kilograms": "килограммов",
        "oz": "унция", "ounce": "унция", "ounces": "унций",
        "lb": "фунт", "pound": "фунт", "pounds": "фунтов",
        "piece": "шт", "pieces": "шт", "pc": "шт", "pcs": "шт",
        "pinch": "щепотка", "pinches": "щепотки",
        "slice": "ломтик", "slices": "ломтика",
        "to taste": "по вкусу", "dash": "капля"
    ]

    private func translateUnit(_ unit: String) -> String {
        let unitLower = unit.lowercased()
        return unitTranslations[unitLower] ?? unit
    }
}
