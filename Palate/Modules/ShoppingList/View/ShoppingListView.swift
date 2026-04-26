//
//  ShoppingListView.swift
//  Palate
//

import SwiftUI

struct ShoppingListView: View {
    @StateObject var presenter: ShoppingListPresenter
    
    var body: some View {
        Text(L10n.shoppingList)
            .navigationTitle(L10n.shoppingList)
    }
}
