//
//  UserRecipe.swift
//  Palate
//

import Foundation
import FirebaseFirestore

struct UserRecipe: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let recipeId: String
    let recipeSource: RecipeSource
    let status: RecipeStatus
    let rating: Int?
    let notes: String?
    let dateAdded: Date
    let dateCooked: Date?
    
    init(userId: String,
         recipeId: String,
         recipeSource: RecipeSource,
         status: RecipeStatus,
         rating: Int? = nil,
         notes: String? = nil) {
        self.userId = userId
        self.recipeId = recipeId
        self.recipeSource = recipeSource
        self.status = status
        self.rating = rating
        self.notes = notes
        self.dateAdded = Date()
        self.dateCooked = status == .cooked ? Date() : nil
    }
}
