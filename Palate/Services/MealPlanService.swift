//
//  MealPlanService.swift
//  Palate
//

import FirebaseFirestore
import FirebaseAuth
import CoreData

final class MealPlanService {
    static let shared = MealPlanService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    private func collectionRef(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("mealPlans")
    }
    
    func saveMealPlan(_ plan: MealPlan, userId: String) async throws {
        guard let id = plan.id?.uuidString else { return }
        
        let data: [String: Any] = [
            "date": Timestamp(date: plan.date ?? Date()),
            "breakfastRecipeId": plan.breakfastRecipeId ?? "",
            "lunchRecipeId": plan.lunchRecipeId ?? "",
            "dinnerRecipeId": plan.dinnerRecipeId ?? "",
            "snackRecipeId": plan.snackRecipeId ?? "",
            "synced": true
        ]
        
        try await collectionRef(userId: userId).document(id).setData(data)
    }
    
    func fetchMealPlans(userId: String) async throws -> [MealPlan] {
        let snapshot = try await collectionRef(userId: userId).getDocuments()
        let context = CoreDataManager.shared.viewContext
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            let plan = MealPlan(context: context)
            plan.id = UUID(uuidString: doc.documentID)
            plan.date = (data["date"] as? Timestamp)?.dateValue()
            plan.breakfastRecipeId = data["breakfastRecipeId"] as? String
            plan.lunchRecipeId = data["lunchRecipeId"] as? String
            plan.dinnerRecipeId = data["dinnerRecipeId"] as? String
            plan.snackRecipeId = data["snackRecipeId"] as? String
            plan.synced = true
            return plan
        }
    }
    
    func deleteMealPlan(planId: String, userId: String) async throws {
        try await collectionRef(userId: userId).document(planId).delete()
    }
}
