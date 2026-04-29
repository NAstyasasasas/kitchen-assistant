//
//  MyRecipesView.swift
//  Palate
//

import SwiftUI

struct MyRecipesView: View {
    @StateObject var presenter: MyRecipesPresenter
    
    var body: some View {
        Text(L10n.myRecipes)
            .navigationTitle(L10n.myRecipes)
    }
}
