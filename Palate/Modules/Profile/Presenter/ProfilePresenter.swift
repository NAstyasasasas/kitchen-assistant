//
//  ProfilePresenter.swift
//  Palate
//

import SwiftUI
import Combine

final class ProfilePresenter: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var cookedCount = 0
    @Published var wantToCookCount = 0
    @Published var customRecipesCount = 0
    @Published var isLoading = false
    
    private let interactor: ProfileInteractorProtocol
    private weak var coordinator: MainCoordinator?
    
    init(interactor: ProfileInteractorProtocol = ProfileInteractor(),
         coordinator: MainCoordinator?) {
        self.interactor = interactor
        self.coordinator = coordinator
        self.currentUser = interactor.currentUser
    }
    
    func loadStats() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let stats = try await interactor.getUserStats()
            cookedCount = stats.cooked
            wantToCookCount = stats.wantToCook
            customRecipesCount = stats.custom
        } catch {
            print("Ошибка загрузки статистики: \(error)")
        }
    }
    
    func signOut() {
        do {
            try interactor.signOut()
            NotificationCenter.default.post(name: NSNotification.Name("userDidSignOut"), object: nil)
        } catch {
            print("Ошибка выхода: \(error)")
        }
    }
}
