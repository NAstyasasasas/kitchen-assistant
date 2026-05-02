//
//  UserRecipe+CoreDataProperties.swift
//  Palate
//
//  Created by Анастасия on 02.05.2026.
//
//

public import Foundation
public import CoreData


public typealias UserRecipeCoreDataPropertiesSet = NSSet

extension UserRecipe {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserRecipe> {
        return NSFetchRequest<UserRecipe>(entityName: "UserRecipe")
    }

    @NSManaged public var dateAdded: Date?
    @NSManaged public var dateCooked: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var rating: Int64
    @NSManaged public var recipeId: String?
    @NSManaged public var recipeSource: String?
    @NSManaged public var status: String?
    @NSManaged public var synced: Bool
    @NSManaged public var userId: String?

}

extension UserRecipe : Identifiable {

}
