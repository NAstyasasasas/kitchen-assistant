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
    
    private func fieldTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16))
            .foregroundColor(Color(.label))
    }

    private func customTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 16))
            .padding(.horizontal, 14)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
            )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let image = presenter.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 42))
                                    .foregroundColor(Color(.secondaryLabel).opacity(0.65))

                                Text(L10n.addPhoto)
                                    .font(.system(size: 17))
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.secondaryLabel).opacity(0.55),
                                            style: StrokeStyle(lineWidth: 1, dash: [3]))
                            )
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
                    
                    fieldTitle(L10n.recipeName)
                    customTextField(placeholder: L10n.examplePasta, text: $presenter.name)
                    
                    fieldTitle(L10n.cuisine)
                    customTextField(placeholder: L10n.exampleItalia, text: $presenter.cuisine)
                    
                    fieldTitle(L10n.category)
                    Button {
                        showingCategoryPicker = true
                    } label: {
                        HStack {
                            Text(presenter.category.isEmpty ? L10n.selectCategory : presenter.category)
                                .font(.system(size: 16))
                                .foregroundColor(presenter.category.isEmpty ? Color(.secondaryLabel) : Color(.label))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(Color(.label))
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.secondaryLabel).opacity(0.45), lineWidth: 1)
                        )
                    }
                    
                    SectionHeaderBar(title: L10n.ingredients)
                    
                    ForEach(presenter.ingredientInputs.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            TextField(L10n.ingredientName, text: $presenter.ingredientInputs[index].name)
                                .font(.system(size: 15))
                                .padding(.horizontal, 12)
                                .frame(height: 46)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
                                )
                            
                            TextField(L10n.amount, text: $presenter.ingredientInputs[index].amount)
                                .font(.system(size: 15))
                                .padding(.horizontal, 12)
                                .frame(width: 92, height: 46)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
                                )
                            
                            TextField(L10n.unit, text: $presenter.ingredientInputs[index].unit)
                                .font(.system(size: 15))
                                .padding(.horizontal, 12)
                                .frame(width: 76, height: 46)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
                                )
                            
                            Button {
                                presenter.removeIngredient(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Button {
                        presenter.addIngredient()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(Color.accentGreen)
                            .cornerRadius(10)
                    }
                    
                    SectionHeaderBar(title: L10n.instructions)
                    
                    ZStack(alignment: .topLeading) {
                        if presenter.instructions.isEmpty {
                            Text(L10n.inputInstruction)
                                .font(.system(size: 16))
                                .foregroundColor(Color(.secondaryLabel).opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.top, 14)
                        }
                        
                        TextEditor(text: $presenter.instructions)
                            .font(.system(size: 16))
                            .padding(8)
                            .frame(minHeight: 180)
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .navigationTitle(presenter.mode == .create ? L10n.createRecipe : L10n.editRecipe)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(.secondaryLabel))
                    }
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
                    .foregroundColor(.accentGreen)
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
                        .background(Color(.label).opacity(0.2))
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
