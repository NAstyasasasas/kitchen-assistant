//
//  ShoppingListPresenter.swift
//  Palate
//

import SwiftUI
import Combine

final class ShoppingListPresenter: ObservableObject {
    private var coordinator: MainCoordinator?
    
    init(coordinator: MainCoordinator?) {
        self.coordinator = coordinator
    }
}
