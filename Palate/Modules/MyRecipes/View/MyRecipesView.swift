//
//  MyRecipesView.swift
//  Palate
//

import SwiftUI

struct MyRecipesView: View {
    @StateObject var presenter: MyRecipesPresenter
    
    var body: some View {
        Text("my_recipes".localized)
        .navigationTitle("my_recipes".localized)
    }
}
