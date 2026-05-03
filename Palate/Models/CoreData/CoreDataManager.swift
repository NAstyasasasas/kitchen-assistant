//
//  CoreDataManager.swift
//  Palate
//
//  Created by Анастасия on 01.05.2026.
//

import CoreData

final class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Palate")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func save() {
        if viewContext.hasChanges {
            try? viewContext.save()
        }
    }
    
    func saveContext() {
        save()
    }
    
    func saveUserRecipe(_ userRecipe: UserRecipe) {
        saveContext()
    }

    func fetchUserRecipes(byUserId userId: String, status: String? = nil) -> [UserRecipe] {
        let request: NSFetchRequest<UserRecipe> = UserRecipe.fetchRequest()
        var predicates: [NSPredicate] = [NSPredicate(format: "userId == %@", userId)]
        if let status = status {
            predicates.append(NSPredicate(format: "status == %@", status))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ Failed to fetch user recipes: \(error)")
            return []
        }
    }

    func updateUserRecipeStatus(recipeId: String, status: String, dateCooked: Date? = nil) {
        let request: NSFetchRequest<UserRecipe> = UserRecipe.fetchRequest()
        request.predicate = NSPredicate(format: "recipeId == %@", recipeId)
        do {
            let results = try viewContext.fetch(request)
            if let existing = results.first {
                existing.status = status
                if let dateCooked = dateCooked {
                    existing.dateCooked = dateCooked
                }
            } else {
                print("⚠️ UserRecipe not found for update")
            }
            saveContext()
        } catch {
            print("❌ Failed to update user recipe status: \(error)")
        }
    }
    
    func updateRating(recipeId: String, rating: Int) {
        let request: NSFetchRequest<UserRecipe> = UserRecipe.fetchRequest()
        request.predicate = NSPredicate(format: "recipeId == %@", recipeId)
        do {
            let results = try viewContext.fetch(request)
            if let existing = results.first {
                existing.rating = Int64(rating)
                saveContext()
            }
        } catch {
            print("❌ Failed to update rating: \(error)")
        }
    }
}
