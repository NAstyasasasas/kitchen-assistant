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
    
    func recipeHasConflicts(_ recipe: Recipe) -> Bool
    func addWholeRecipe(_ recipe: Recipe) async
}

final class ShoppingListInteractor: ShoppingListInteractorProtocol {
    private let context = CoreDataManager.shared.viewContext
    private let db = Firestore.firestore()
    
    private var userId: String? { Auth.auth().currentUser?.uid }
    
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
        let newItem = ShoppingItem(context: context)
        newItem.id = UUID()
        newItem.name = name
        newItem.quantity = quantity
        newItem.unit = unit
        newItem.isBought = false
        newItem.createdAt = Date()
        saveContext()
        Task { await syncToFirestore(item: newItem) }
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
    
    func recipeHasConflicts(_ recipe: Recipe) -> Bool {
        let existingItems = fetchItems()
        for ingredient in recipe.ingredients {
            let (quantity, unit, isNumeric) = parseIngredient(ingredient)
            if isNumeric {
                let exists = existingItems.contains { item in
                    item.name?.lowercased() == ingredient.name.lowercased() &&
                    item.unit?.lowercased() == unit.lowercased() &&
                    item.isBought == false
                }
                if exists { return true }
            }
        }
        return false
    }
    
    func addWholeRecipe(_ recipe: Recipe) async {
        for ingredient in recipe.ingredients {
            let (quantity, unit, isNumeric) = parseIngredient(ingredient)
            if isNumeric {
                if let existing = fetchItems().first(where: {
                    $0.name?.lowercased() == ingredient.name.lowercased() &&
                    $0.unit?.lowercased() == unit.lowercased() &&
                    $0.isBought == false
                }) {
                    existing.quantity += quantity
                    updateItem(existing)
                } else {
                    addItem(name: ingredient.name, quantity: quantity, unit: unit)
                }
            } else {
                addItem(name: ingredient.name, quantity: 0, unit: "")
            }
        }
    }
    
    private func parseIngredient(_ ingredient: Ingredient) -> (quantity: Double, unit: String, isNumeric: Bool) {
        let amount = ingredient.amount.trimmingCharacters(in: .whitespaces)
        let pattern = "^(\\d+(?:\\.\\d+)?(?:\\/\\d+)?)\\s*([a-zA-Z/\\.]+)"
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
}
