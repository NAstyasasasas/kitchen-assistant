//
//  MyRecipesView.swift
//  Palate
//

import SwiftUI

struct MyRecipesView: View {
    @StateObject var presenter: MyRecipesPresenter
    
    var body: some View {
        Text("Мои рецепты")
            .navigationTitle("Мои рецепты")
    }
}
