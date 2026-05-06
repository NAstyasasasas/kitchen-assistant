//
//  ShoppingListPresenter.swift
//  Palate
//

import SwiftUI
import Combine
import CoreData

@MainActor
final class ShoppingListPresenter: ObservableObject {
    private let interactor: ShoppingListInteractorProtocol
    private weak var coordinator: MainCoordinator?
    
    @Published var items: [ShoppingItem] = []
    @Published var newItemName = ""
    @Published var errorMessage: String?
    @Published var selectedItems: Set<NSManagedObjectID> = []
    
    @Published var showRecipeConfirmation = false
    @Published var pendingRecipe: Recipe?
    
    @MainActor
    init(interactor: ShoppingListInteractorProtocol? = nil,
         coordinator: MainCoordinator?) {
        self.interactor = interactor ?? ShoppingListInteractor()
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
    
    func checkAndAddRecipe(_ recipe: Recipe) async {
        let hasConflicts = interactor.recipeHasConflicts(recipe)

        if hasConflicts {
            await MainActor.run {
                pendingRecipe = recipe
                showRecipeConfirmation = true
            }
        } else {
            await interactor.addWholeRecipe(recipe)
            await MainActor.run {
                loadData()
            }
        }
    }
    
    func confirmAddWholeRecipe() async {
        guard let recipe = pendingRecipe else { return }

        await interactor.addWholeRecipe(recipe)

        await MainActor.run {
            loadData()
            showRecipeConfirmation = false
            pendingRecipe = nil
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
        let idsToDelete = selectedItems

        let itemsToDelete = items.filter {
            idsToDelete.contains($0.objectID)
        }

        for item in itemsToDelete {
            interactor.deleteItem(item)
        }

        items.removeAll {
            idsToDelete.contains($0.objectID)
        }

        selectedItems.removeAll()
    }

    func updateItem(_ item: ShoppingItem, quantity: Double, unit: String) {
        item.quantity = quantity
        item.unit = unit
        interactor.updateItem(item)

        if let index = items.firstIndex(where: { $0.objectID == item.objectID }) {
            items[index] = item
        }
    }

    func toggleBought(_ item: ShoppingItem) {
        interactor.toggleBought(item)

        if let index = items.firstIndex(where: { $0.objectID == item.objectID }) {
            items[index] = item
        }
    }
    
    func deleteItem(_ item: ShoppingItem) {
        interactor.deleteItem(item)
        items.removeAll { $0.objectID == item.objectID }
        selectedItems.remove(item.objectID)
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
