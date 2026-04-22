//
//  ShoppingListView.swift
//  Palate
//

import SwiftUI

struct ShoppingListView: View {
    @StateObject var presenter: ShoppingListPresenter
    
    var body: some View {
        Text("Список покупок")
            .navigationTitle("Список покупок")
    }
}
