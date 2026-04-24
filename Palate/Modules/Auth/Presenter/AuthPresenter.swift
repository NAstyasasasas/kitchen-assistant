//
//  AuthPresenter.swift
//  Palate
//

import SwiftUI
import Combine

final class AuthPresenter: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    
    private let interactor: AuthInteractorProtocol
    private weak var coordinator: AuthCoordinator?
    
    init(interactor: AuthInteractorProtocol = AuthInteractor(),
         coordinator: AuthCoordinator?) {
        self.interactor = interactor
        self.coordinator = coordinator
        Task {
            self.isAuthenticated = await interactor.isAuthenticated()
            self.currentUser = await interactor.getCurrentUser()
        }
    }
    
    func register(email: String, password: String, confirmPassword: String, displayName: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await interactor.register(email: email, password: password, confirmPassword: confirmPassword, displayName: displayName)
            currentUser = user
            isAuthenticated = true
            coordinator?.authSuccess()
        } catch let authError as AuthError {
            errorMessage = authError.errorDescription
        } catch {
            errorMessage = "registration_error".localized
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await interactor.login(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            coordinator?.authSuccess()
        } catch let authError as AuthError {
            errorMessage = authError.errorDescription
        } catch {
            errorMessage = "login_error".localized
        }
    }
    
    func signOut() {
        do {
            try interactor.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = "sign_out_error".localized
        }
    }
    
    func showLogin() {
        coordinator?.showLogin()
    }
    
    func showRegister() {
        coordinator?.showRegister()
    }
}
