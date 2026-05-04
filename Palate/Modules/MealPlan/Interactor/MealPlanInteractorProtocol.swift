//
//  MealPlanInteractor.swift
//  Palate
//

import Foundation
import CoreData
import FirebaseAuth

protocol MealPlanInteractorProtocol {
    func fetchPlan(for date: Date) -> MealPlan?
    func fetchWeekPlans(startOfWeek: Date) -> [MealPlan]
    func savePlan(_ plan: MealPlan)
    func updatePlan(date: Date, mealType: MealPlanMealType, recipeId: String?)
    func deletePlan(for date: Date)
    func syncWithFirebase() async
}

enum MealPlanMealType: String, CaseIterable {
    case breakfast, lunch, dinner, snack
}

final class MealPlanInteractor: MealPlanInteractorProtocol {
    private let coreData = CoreDataManager.shared
    private let mealPlanService = MealPlanService.shared
    
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func fetchPlan(for date: Date) -> MealPlan? {
        return coreData.fetchMealPlan(for: date)
    }
    
    func fetchWeekPlans(startOfWeek: Date) -> [MealPlan] {
        return coreData.fetchWeekMealPlans(startOfWeek: startOfWeek)
    }
    
    func savePlan(_ plan: MealPlan) {
        coreData.saveMealPlan(plan)
        
        Task {
            guard let userId = userId else { return }
            try? await mealPlanService.saveMealPlan(plan, userId: userId)
            await MainActor.run {
                plan.synced = true
                coreData.saveContext()
            }
        }
    }
    
    func updatePlan(date: Date, mealType: MealPlanMealType, recipeId: String?) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let existing = fetchPlan(for: normalizedDate)
        let plan: MealPlan
        
        if let existing = existing {
            plan = existing
        } else {
            plan = MealPlan(context: coreData.viewContext)
            plan.id = UUID()
            plan.date = normalizedDate
            plan.synced = false
        }
        
        switch mealType {
        case .breakfast:
            plan.breakfastRecipeId = recipeId
        case .lunch:
            plan.lunchRecipeId = recipeId
        case .dinner:
            plan.dinnerRecipeId = recipeId
        case .snack:
            plan.snackRecipeId = recipeId
        }
        
        savePlan(plan)
    }
    
    func deletePlan(for date: Date) {
        if let plan = fetchPlan(for: date) {
            coreData.viewContext.delete(plan)
            coreData.saveContext()
            
            Task {
                guard let userId = userId, let planId = plan.id?.uuidString else { return }
                try? await mealPlanService.deleteMealPlan(planId: planId, userId: userId)
            }
        }
    }
    
    func syncWithFirebase() async {
        guard let userId = userId else { return }
        
        do {
            let remotePlans = try await mealPlanService.fetchMealPlans(userId: userId)
            let localPlans = coreData.fetchWeekMealPlans(startOfWeek: Date.distantPast)
            
            let localIds = Set(localPlans.compactMap { $0.id?.uuidString })
            let remoteIds = Set(remotePlans.compactMap { $0.id?.uuidString })
            
            for plan in localPlans {
                if let id = plan.id?.uuidString, !remoteIds.contains(id) {
                    coreData.viewContext.delete(plan)
                }
            }
            
            for remote in remotePlans {
                if let existing = localPlans.first(where: { $0.id == remote.id }) {
                    existing.date = remote.date
                    existing.breakfastRecipeId = remote.breakfastRecipeId
                    existing.lunchRecipeId = remote.lunchRecipeId
                    existing.dinnerRecipeId = remote.dinnerRecipeId
                    existing.snackRecipeId = remote.snackRecipeId
                    existing.synced = true
                } else {
                    coreData.viewContext.insert(remote)
                }
            }
            
            try? coreData.viewContext.save()
        } catch {
            print("❌ Failed to sync meal plans: \(error)")
        }
    }
}
