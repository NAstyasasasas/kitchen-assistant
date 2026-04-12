//
//  MyRecipesPresenter.swift
//  Palate
//

import SwiftUI
import Combine

final class MyRecipesPresenter: ObservableObject {
    private var coordinator: MainCoordinator?
    
    init(coordinator: MainCoordinator?) {
        self.coordinator = coordinator
    }
}
