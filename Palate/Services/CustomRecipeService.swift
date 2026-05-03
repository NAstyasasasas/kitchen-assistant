//
//  CustomRecipeService.swift
//  Palate
//

import FirebaseFirestore
import FirebaseAuth
import CoreData

final class CustomRecipeService {
    static let shared = CustomRecipeService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    private func collectionRef(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("customRecipes")
    }
    
    func saveCustomRecipe(_ recipe: CustomRecipe, userId: String) async throws {
        guard let id = recipe.id?.uuidString else { return }
        let data: [String: Any] = [
            "name": recipe.name ?? "",
            "cuisine": recipe.cuisine ?? "",
            "category": recipe.category ?? "",
            "imageUrl": recipe.imageUrl ?? "",
            "instructions": recipe.instructions ?? "",
            "createdAt": Timestamp(date: recipe.createdAt ?? Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        try await collectionRef(userId: userId).document(id).setData(data)
        
        let ingredientsCollection = collectionRef(userId: userId).document(id).collection("ingredients")
        for ingredient in recipe.ingredients?.allObjects as? [CustomIngredient] ?? [] {
            let ingData: [String: Any] = [
                "name": ingredient.name ?? "",
                "amount": ingredient.amount ?? "",
                "unit": ingredient.unit ?? ""
            ]
            try await ingredientsCollection.document(ingredient.id?.uuidString ?? UUID().uuidString).setData(ingData)
        }
    }
    
    func fetchCustomRecipes(userId: String) async throws -> [CustomRecipe] {
        let snapshot = try await collectionRef(userId: userId).getDocuments()
        let context = CoreDataManager.shared.viewContext
        var recipes: [CustomRecipe] = []
        
        for doc in snapshot.documents {
            let data = doc.data()
            let recipe = CustomRecipe(context: context)
            recipe.id = UUID(uuidString: doc.documentID)
            recipe.userId = userId
            recipe.name = data["name"] as? String ?? ""
            recipe.cuisine = data["cuisine"] as? String ?? ""
            recipe.category = data["category"] as? String ?? ""
            recipe.imageUrl = data["imageUrl"] as? String
            recipe.instructions = data["instructions"] as? String ?? ""
            recipe.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            recipe.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
            
            let ingSnapshot = try await collectionRef(userId: userId).document(doc.documentID).collection("ingredients").getDocuments()
            for ingDoc in ingSnapshot.documents {
                let ingData = ingDoc.data()
                let ingredient = CustomIngredient(context: context)
                ingredient.id = UUID(uuidString: ingDoc.documentID)
                ingredient.recipeId = recipe.id
                ingredient.name = ingData["name"] as? String ?? ""
                ingredient.amount = ingData["amount"] as? String ?? ""
                ingredient.unit = ingData["unit"] as? String ?? ""
                recipe.addToIngredients(ingredient)
            }
            recipes.append(recipe)
        }
        CoreDataManager.shared.saveContext()
        return recipes
    }
    
    func deleteCustomRecipe(recipeId: String, userId: String) async throws {
        try await collectionRef(userId: userId).document(recipeId).delete()
    }
}
