//
//  ShoppingItem+CoreDataProperties.swift
//  Palate
//
//  Created by Анастасия on 29.04.2026.
//
//

public import Foundation
public import CoreData

extension ShoppingItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingItem> {
        return NSFetchRequest<ShoppingItem>(entityName: "ShoppingItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var quantity: Double
    @NSManaged public var unit: String?
    @NSManaged public var isBought: Bool
    @NSManaged public var createdAt: Date?

}

extension ShoppingItem : Identifiable {

}
