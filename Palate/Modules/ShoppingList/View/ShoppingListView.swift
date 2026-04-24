//
//  ShoppingListView.swift
//  Palate
//

import SwiftUI

struct ShoppingListView: View {
    @StateObject var presenter: ShoppingListPresenter
    
    var body: some View {
        Text("shopping_list".localized)
        .navigationTitle("shopping_list".localized)
    }
}
