//
//  UserService.swift
//  Palate
//

import Foundation
import FirebaseFirestore

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
}
