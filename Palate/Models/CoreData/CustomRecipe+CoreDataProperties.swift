//
//  CustomRecipe+CoreDataProperties.swift
//  Palate
//

import Foundation
import CoreData

extension CustomRecipe {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomRecipe> {
        return NSFetchRequest<CustomRecipe>(entityName: "CustomRecipe")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var userId: String?
    @NSManaged public var name: String?
    @NSManaged public var cuisine: String?
    @NSManaged public var category: String?
    @NSManaged public var instructions: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var synced: Bool
    @NSManaged public var ingredients: NSSet?

    @objc(addIngredientsObject:)
    @NSManaged public func addToIngredients(_ value: CustomIngredient)

    @objc(removeIngredientsObject:)
    @NSManaged public func removeFromIngredients(_ value: CustomIngredient)

    @objc(addIngredients:)
    @NSManaged public func addToIngredients(_ values: NSSet)

    @objc(removeIngredients:)
    @NSManaged public func removeFromIngredients(_ values: NSSet)
}

extension CustomRecipe : Identifiable {

}
