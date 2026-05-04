//
//  ShoppingListPresenter.swift
//  Palate
//

import SwiftUI
import Combine

final class ShoppingListPresenter: ObservableObject {
    private let interactor: ShoppingListInteractorProtocol
    private let coordinator: MainCoordinator?
    private let shoppingInteractor = ShoppingListInteractor()
    
    @Published var items: [ShoppingItem] = []
    @Published var newItemName = ""
    @Published var errorMessage: String?
    @Published var selectedItems: Set<ShoppingItem> = []
    
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
            let hasConflicts = await Task { () -> Bool in
                return self.interactor.recipeHasConflicts(recipe)
            }.value
            await MainActor.run {
                if hasConflicts {
                    self.pendingRecipe = recipe
                    self.showRecipeConfirmation = true
                } else {
                    Task {
                        await self.interactor.addWholeRecipe(recipe)
                        await MainActor.run {
                            self.loadData()
                        }
                    }
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
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }

    func isSelected(_ item: ShoppingItem) -> Bool {
        selectedItems.contains(item)
    }

    func deleteSelectedItems() {
        for item in selectedItems {
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
