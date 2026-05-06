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
    @State private var editName = ""
    
    @State private var showDeleteAllAlert = false
    @State private var itemToDelete: ShoppingItem?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Text(L10n.shoppingList)
                        .font(.system(size: 28, weight: .bold))

                    Spacer()

                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)

                HStack(spacing: 8) {
                    TextField(L10n.addItemName, text: $newItemName)
                        .font(.system(size: 14))
                        .padding(.horizontal, 12)
                        .frame(height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.secondaryLabel).opacity(0.45), lineWidth: 1.3)
                        )

                    TextField(L10n.addItemQuantity, text: $newItemQuantity)
                        .font(.system(size: 14))
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, 12)
                        .frame(width: 90, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.secondaryLabel).opacity(0.45), lineWidth: 1.3)
                        )

                    TextField(L10n.addItemUnit, text: $newItemUnit)
                        .font(.system(size: 14))
                        .padding(.horizontal, 12)
                        .frame(width: 80, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.secondaryLabel).opacity(0.45), lineWidth: 1.3)
                        )

                    Button {
                        let quantity = Double(newItemQuantity) ?? 0
                        presenter.addItem(name: newItemName, quantity: quantity, unit: newItemUnit)
                        newItemName = ""
                        newItemQuantity = ""
                        newItemUnit = ""
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(newItemName.isEmpty ? Color(.secondaryLabel) : Color.accentGreen)
                            .cornerRadius(10)
                    }
                    .disabled(newItemName.isEmpty)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)

                if presenter.items.isEmpty {
                    Spacer()

                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 40))
                            .foregroundColor(Color(.secondaryLabel))

                        Text(L10n.shoppingListEmpty)
                            .foregroundColor(Color(.secondaryLabel))
                    }

                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(presenter.items, id: \.self) { item in
                                ShoppingItemCard(
                                    item: item,
                                    isSelected: presenter.isSelected(item),
                                    onToggle: {
                                        presenter.toggleSelection(item)
                                    },
                                    onEdit: {
                                        editName = item.name ?? ""
                                        editItem = item
                                        editQuantity = String(item.quantity)
                                        editUnit = item.unit ?? ""
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 90)
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .alert(
                presenter.selectedItems.isEmpty
                ? L10n.deleteAllConfirm
                : L10n.deleteProduct,
                isPresented: $showDeleteAlert
            ) {
                Button(L10n.delete, role: .destructive) {
                    if presenter.selectedItems.isEmpty {
                        presenter.deleteAllItems()
                    } else {
                        presenter.deleteSelectedItems()
                    }
                }

                Button(L10n.cancel, role: .cancel) { }
            } message: {
                Text(
                    presenter.selectedItems.isEmpty
                    ? L10n.deleteAllMessage
                    : L10n.deleteProduct
                )
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
                TextField(L10n.addItemName, text: $editName)
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
                        item.name = editName
                        presenter.updateItem(item, quantity: quantity, unit: editUnit)
                        editItem = nil
                    }
                }
            }
        }
    }
}

struct ShoppingItemCard: View {
    let item: ShoppingItem
    let isSelected: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void

    private var quantityText: String {
        if item.quantity > 0 || !(item.unit?.isEmpty ?? true) {
            return "\(item.quantity.cleanString) \(item.unit ?? "")"
        }
        return ""
    }

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundColor(isSelected ? .accentGreen : Color.gray.opacity(0.45))
            }
            .buttonStyle(.plain)

            Text(displayText)
                .font(.system(size: 17))
                .foregroundColor(isSelected ? .gray : .primary)
                .strikethrough(isSelected)
                .lineLimit(1)

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 45)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.35), lineWidth: 1.3)
        )
    }

    private var displayText: String {
        let name = item.name ?? ""
        if quantityText.isEmpty {
            return name
        }
        return "\(name) - \(quantityText)"
    }
}

private extension Double {
    var cleanString: String {
        truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", self)
        : String(format: "%.2f", self)
    }
}
