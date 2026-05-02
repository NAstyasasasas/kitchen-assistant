//
//  UserService.swift
//  Palate
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreData

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func updateAvatarUrl(userId: String, avatarUrl: String) async throws {
        try await db.collection("users").document(userId).setData(
            ["avatarUrl": avatarUrl],
            merge: true
        )
    }
    
    func getUserAvatarUrl(userId: String) async throws -> String? {
        let document = try await db.collection("users").document(userId).getDocument()
        return document.data()?["avatarUrl"] as? String
    }
    
    func saveUserRecipe(_ userRecipe: UserRecipe, userId: String) async throws {
        let data: [String: Any] = [
            "userId": userId,
            "recipeId": userRecipe.recipeId,
            "recipeSource": userRecipe.recipeSource,
            "status": userRecipe.status,
            "notes": userRecipe.notes ?? "",
            "rating": userRecipe.rating ?? 0,
            "dateAdded": Timestamp(date: userRecipe.dateAdded ?? Date()),
            "dateCooked": userRecipe.dateCooked != nil ? Timestamp(date: userRecipe.dateCooked!) : NSNull()
        ]
        guard let recipeId = userRecipe.recipeId else { return }
        try await db.collection("users").document(userId).collection("userRecipes").document(recipeId).setData(data)
    }

    func fetchUserRecipes(userId: String, status: String? = nil) async throws -> [UserRecipe] {
        var query: Query = db.collection("users").document(userId).collection("userRecipes")
        if let status = status {
            query = query.whereField("status", isEqualTo: status)
        }
        let snapshot = try await query.getDocuments()
        let context = CoreDataManager.shared.viewContext
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let recipeSourceRaw = data["recipeSource"] as? String,
                  let statusRaw = data["status"] as? String else { return nil }
            let userRecipe = UserRecipe(context: context)
            userRecipe.id = UUID()
            userRecipe.userId = userId
            userRecipe.recipeId = doc.documentID
            userRecipe.recipeSource = recipeSourceRaw
            userRecipe.status = statusRaw
            userRecipe.notes = data["notes"] as? String ?? ""
            if let ratingVal = data["rating"] as? Int {
                userRecipe.rating = Int64(ratingVal)
            } else {
                userRecipe.rating = 0
            }
            userRecipe.dateAdded = (data["dateAdded"] as? Timestamp)?.dateValue() ?? Date()
            userRecipe.dateCooked = (data["dateCooked"] as? Timestamp)?.dateValue()
            userRecipe.synced = true
            return userRecipe
        }
    }

    func updateUserRecipeStatus(recipeId: String, status: String, dateCooked: Date? = nil) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw AuthError.networkError }
        var data: [String: Any] = ["status": status]
        if let dateCooked = dateCooked {
            data["dateCooked"] = Timestamp(date: dateCooked)
        }
        try await db.collection("users").document(userId).collection("userRecipes").document(recipeId).updateData(data)
    }
    func deleteUserRecipe(recipeId: String, userId: String) async throws {
        try await db.collection("users").document(userId).collection("userRecipes").document(recipeId).delete()
    }
    func updateUserRecipeNotes(recipeId: String, notes: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw AuthError.networkError }
        let data: [String: Any] = ["notes": notes]
        try await db.collection("users").document(userId).collection("userRecipes").document(recipeId).updateData(data)
    }
    func doesUserRecipeExist(recipeId: String, userId: String) async throws -> Bool {
        let docRef = db.collection("users").document(userId).collection("userRecipes").document(recipeId)
        let snapshot = try await docRef.getDocument()
        return snapshot.exists
    }

    func updateUserRecipeRating(recipeId: String, rating: Int) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw AuthError.networkError }
        try await db.collection("users").document(userId).collection("userRecipes").document(recipeId).updateData(["rating": rating])
    }
}
