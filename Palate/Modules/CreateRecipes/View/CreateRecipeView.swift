//
//  CreateRecipeView.swift
//  Palate
//

import SwiftUI
import PhotosUI


struct CreateRecipeView: View {
    @StateObject var presenter: CreateRecipePresenter
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingCategoryPicker = false
    
    let categories = MealType.allCases.map { $0.localizedName }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let image = presenter.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            Label(L10n.addPhoto, systemImage: "camera")
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                presenter.selectedImage = uiImage
                            }
                            selectedItem = nil
                        }
                    }
                }
                
                Section(L10n.basicInfo) {
                    TextField(L10n.recipeName, text: $presenter.name)
                    TextField(L10n.cuisine, text: $presenter.cuisine)
                    
                    Button {
                        showingCategoryPicker = true
                    } label: {
                        HStack {
                            Text(L10n.category)
                            Spacer()
                            Text(presenter.category.isEmpty ? L10n.select : presenter.category)
                                .foregroundColor(presenter.category.isEmpty ? .gray : .primary)
                        }
                    }
                }
                
                Section(L10n.ingredients) {
                    ForEach(presenter.ingredientInputs.indices, id: \.self) { index in
                        HStack {
                            TextField(L10n.ingredientName, text: $presenter.ingredientInputs[index].name)
                                .autocapitalization(.words)
                            TextField(L10n.amount, text: $presenter.ingredientInputs[index].amount)
                                .keyboardType(.default)
                            TextField(L10n.unit, text: $presenter.ingredientInputs[index].unit)
                                .autocapitalization(.none)
                            
                            Button {
                                presenter.removeIngredient(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    Button(action: { presenter.addIngredient() }) {
                        Label(L10n.addIngredient, systemImage: "plus")
                    }
                }
                
                Section(L10n.instructions) {
                    TextEditor(text: $presenter.instructions)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle(presenter.mode == .create ? L10n.createRecipe : L10n.editRecipe)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) {
                        Task {
                            await presenter.saveRecipe()
                            if presenter.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $presenter.category, categories: categories)
            }
            .alert(L10n.error, isPresented: Binding(
                get: { presenter.errorMessage != nil },
                set: { if !$0 { presenter.errorMessage = nil } }
            )) {
                Button(L10n.ok, role: .cancel) {}
            } message: {
                Text(presenter.errorMessage ?? "")
            }
            .overlay {
                if presenter.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
}

struct CategoryPickerView: View {
    @Binding var selectedCategory: String
    let categories: [String]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(categories, id: \.self) { category in
                Button {
                    selectedCategory = category
                    dismiss()
                } label: {
                    HStack {
                        Text(category)
                        Spacer()
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentPurple)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle(L10n.selectCategory)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
            }
        }
    }
}
