//
//  CustomIngredient+CoreDataProperties.swift
//  Palate
//
//  Created by Анастасия on 03.05.2026.
//
//

public import Foundation
public import CoreData

extension CustomIngredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomIngredient> {
        return NSFetchRequest<CustomIngredient>(entityName: "CustomIngredient")
    }

    @NSManaged public var amount: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var recipeId: UUID?
    @NSManaged public var unit: String?
    @NSManaged public var recipe: CustomRecipe?

}

extension CustomIngredient : Identifiable {

}
