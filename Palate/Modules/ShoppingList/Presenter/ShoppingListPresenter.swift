//
//  ShoppingListPresenter.swift
//  Palate
//

import SwiftUI
import Combine
import CoreData

final class ShoppingListPresenter: ObservableObject {
    private let interactor: ShoppingListInteractorProtocol
    private let coordinator: MainCoordinator?
    private let shoppingInteractor = ShoppingListInteractor()
    
    @Published var items: [ShoppingItem] = []
    @Published var newItemName = ""
    @Published var errorMessage: String?
    @Published var selectedItems: Set<NSManagedObjectID> = []
    
    @Published var showRecipeConfirmation = false
    @Published var pendingRecipe: Recipe?
    
    init(interactor: ShoppingListInteractorProtocol = ShoppingListInteractor(),
         coordinator: MainCoordinator?) {
        self.interactor = interactor
        self.coordinator = coordinator
    }
    
    func loadData() {
        items = interactor.fetchItems()
    }
    
    func addItem(name: String, quantity: Double, unit: String) {
        interactor.addItem(name: name, quantity: quantity, unit: unit)
        loadData()
    }
    
    func addItemManually() {
        guard !newItemName.isEmpty else { return }
        interactor.addItem(name: newItemName, quantity: 0, unit: "")
        newItemName = ""
        loadData()
    }
    
    func checkAndAddRecipe(_ recipe: Recipe) {
        Task {
            let hasConflicts = await interactor.recipeHasConflicts(recipe)

            await MainActor.run {
                if hasConflicts {
                    self.pendingRecipe = recipe
                    self.showRecipeConfirmation = true
                }
            }

            if !hasConflicts {
                await interactor.addWholeRecipe(recipe)

                await MainActor.run {
                    self.loadData()
                }
            }
        }
    }
    
    func confirmAddWholeRecipe() {
        guard let recipe = pendingRecipe else { return }
        Task {
            await interactor.addWholeRecipe(recipe)
            await MainActor.run {
                self.loadData()
                self.showRecipeConfirmation = false
                self.pendingRecipe = nil
            }
        }
    }
    
    func toggleSelection(_ item: ShoppingItem) {
        if selectedItems.contains(item.objectID) {
            selectedItems.remove(item.objectID)
        } else {
            selectedItems.insert(item.objectID)
        }
    }

    func isSelected(_ item: ShoppingItem) -> Bool {
        selectedItems.contains(item.objectID)
    }

    func deleteSelectedItems() {
        let itemsToDelete = items.filter { selectedItems.contains($0.objectID) }

        for item in itemsToDelete {
            interactor.deleteItem(item)
        }

        selectedItems.removeAll()
        loadData()
    }

    func updateItem(_ item: ShoppingItem, quantity: Double, unit: String) {
        item.quantity = quantity
        item.unit = unit
        interactor.updateItem(item)
        loadData()
    }
    
    func toggleBought(_ item: ShoppingItem) {
        interactor.toggleBought(item)
        loadData()
    }
    
    func deleteItem(_ item: ShoppingItem) {
        interactor.deleteItem(item)
        loadData()
    }
    
    func deleteAllItems() {
        interactor.deleteAllItems()
        loadData()
    }
    
    func syncWithFirebase() {
        Task {
            await interactor.syncWithFirebase()
            await MainActor.run {
                loadData()
            }
        }
    }
}
