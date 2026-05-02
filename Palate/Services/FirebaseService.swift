//
//  FirebaseService.swift
//  Palate
//

import Foundation
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    /*
    func saveUserRecipe(_ userRecipe: UserRecipe) async throws {
        guard let userId = await AuthService.shared.getCurrentUser()?.id else {
            throw AuthError.networkError
        }
        let data: [String: Any] = [
            "userId": userId,
            "recipeId": userRecipe.recipeId,
            "recipeSource": userRecipe.recipeSource.rawValue,
            "status": userRecipe.status.rawValue,
            "rating": userRecipe.rating as Any,
            "notes": userRecipe.notes as Any,
            "dateAdded": Timestamp(date: userRecipe.dateAdded),
            "dateCooked": userRecipe.dateCooked != nil ? Timestamp(date: userRecipe.dateCooked!) as Any : NSNull()
        ]
        
        try await db.collection("users")
            .document(userId)
            .collection("userRecipes")
            .document(userRecipe.recipeId)
            .setData(data)
    }
    
    func getUserRecipes(status: RecipeStatus?) async throws -> [UserRecipe] {
        guard let userId = await AuthService.shared.getCurrentUser()?.id else {
            return []
        }
        
        var query: Query = db.collection("users")
            .document(userId)
            .collection("userRecipes")
        
        if let status = status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let recipeSourceRaw = data["recipeSource"] as? String,
                  let recipeSource = RecipeSource(rawValue: recipeSourceRaw),
                  let statusRaw = data["status"] as? String,
                  let status = RecipeStatus(rawValue: statusRaw),
                  let dateAdded = (data["dateAdded"] as? Timestamp)?.dateValue()
            else {
                return nil
            }
            
            return UserRecipe(
                userId: userId,
                recipeId: document.documentID,
                recipeSource: recipeSource,
                status: status,
                rating: data["rating"] as? Int,
                notes: data["notes"] as? String
            )
        }
    }
    
    func updateRecipeStatus(recipeId: String, newStatus: RecipeStatus, notes: String? = nil, rating: Int? = nil) async throws {
        guard let userId = await AuthService.shared.getCurrentUser()?.id else { return }
        
        var updates: [String: Any] = [
            "status": newStatus.rawValue,
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let notes = notes {
            updates["notes"] = notes
        }
        
        if let rating = rating {
            updates["rating"] = rating
        }
        
        if newStatus == .cooked {
            updates["dateCooked"] = Timestamp(date: Date())
        }
        
        try await db.collection("users")
            .document(userId)
            .collection("userRecipes")
            .document(recipeId)
            .updateData(updates)
    }

    func deleteUserRecipe(recipeId: String) async throws {
        guard let userId = await AuthService.shared.getCurrentUser()?.id else { return }
        
        try await db.collection("users")
            .document(userId)
            .collection("userRecipes")
            .document(recipeId)
            .delete()
    }
     */
}
