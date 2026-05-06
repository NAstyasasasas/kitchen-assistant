//
//  ShoppingListView.swift
//  Palate
//

import SwiftUI

struct ShoppingListView: View {
    @StateObject var presenter: ShoppingListPresenter
    
    @State private var newItemName = ""
    @State private var newItemQuantity = ""
    @State private var newItemUnit = ""
    
    @State private var editItem: ShoppingItem?
    @State private var editQuantity = ""
    @State private var editUnit = ""
    
    @State private var showDeleteAllAlert = false
    @State private var itemToDelete: ShoppingItem?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.shoppingList)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                HStack(spacing: 8) {
                    TextField(L10n.addItemName, text: $newItemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField(L10n.addItemQuantity, text: $newItemQuantity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 70)
                    
                    TextField(L10n.addItemUnit, text: $newItemUnit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    
                    Button {
                        let quantity = Double(newItemQuantity) ?? 0
                        presenter.addItem(name: newItemName, quantity: quantity, unit: newItemUnit)
                        newItemName = ""
                        newItemQuantity = ""
                        newItemUnit = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(newItemName.isEmpty ? .gray : .accentPurple)
                    }
                    .disabled(newItemName.isEmpty)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                if presenter.items.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(L10n.shoppingListEmpty)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                    Spacer()
                } else {
                    List {
                        ForEach(presenter.items, id: \.self) { item in
                            HStack(spacing: 12) {
                                Button {
                                    presenter.toggleBought(item)
                                } label: {
                                    Image(systemName: item.isBought ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isBought ? .green : .gray)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "")
                                        .strikethrough(item.isBought)
                                        .foregroundColor(item.isBought ? .gray : .primary)
                                        .font(.body)
                                    
                                    if item.quantity > 0 || !(item.unit?.isEmpty ?? true) {
                                        Text("\(item.quantity, specifier: "%.2f") \(item.unit ?? "")")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    editItem = item
                                    editQuantity = String(item.quantity)
                                    editUnit = item.unit ?? ""
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.accentPurple)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    itemToDelete = item
                                    showDeleteAlert = true
                                } label: {
                                    Label(L10n.delete, systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showDeleteAllAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert(L10n.deleteAllConfirm, isPresented: $showDeleteAllAlert) {
                Button(L10n.delete, role: .destructive) {
                    presenter.deleteAllItems()
                }
                Button(L10n.cancel, role: .cancel) { }
            } message: {
                Text(L10n.deleteAllMessage)
            }
            .alert(L10n.deleteItemConfirm, isPresented: $showDeleteAlert) {
                Button(L10n.delete, role: .destructive) {
                    if let item = itemToDelete {
                        presenter.deleteItem(item)
                        itemToDelete = nil
                    }
                }
                Button(L10n.cancel, role: .cancel) {
                    itemToDelete = nil
                }
            } message: {
                Text(L10n.deleteItemMessage)
            }
            .sheet(item: $editItem) { item in
                editProductSheet(item: item)
            }
        }
        .onAppear {
            presenter.loadData()
        }
    }
    
    @ViewBuilder
    private func editProductSheet(item: ShoppingItem) -> some View {
        NavigationView {
            Form {
                TextField(L10n.editQuantity, text: $editQuantity)
                    .keyboardType(.decimalPad)
                TextField(L10n.editUnit, text: $editUnit)
            }
            .navigationTitle(L10n.editItem)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        editItem = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) {
                        let quantity = Double(editQuantity) ?? item.quantity
                        presenter.updateItem(item, quantity: quantity, unit: editUnit)
                        editItem = nil
                    }
                }
            }
        }
    }
}
