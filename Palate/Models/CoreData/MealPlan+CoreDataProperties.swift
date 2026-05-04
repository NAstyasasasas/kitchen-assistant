//
//  MealPlan+CoreDataProperties.swift
//  Palate
//
//  Created by Анастасия on 04.05.2026.
//
//

public import Foundation
public import CoreData


public typealias MealPlanCoreDataPropertiesSet = NSSet

extension MealPlan {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MealPlan> {
        return NSFetchRequest<MealPlan>(entityName: "MealPlan")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var breakfastRecipeId: String?
    @NSManaged public var lunchRecipeId: String?
    @NSManaged public var dinnerRecipeId: String?
    @NSManaged public var synced: Bool
    @NSManaged public var snackRecipeId: String?

}

extension MealPlan : Identifiable {

}
