//
//  AuthCoordinator.swift
//  Palate
//

import SwiftUI

final class AuthCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private let navigationController: UINavigationController
    var onAuthSuccess: (() -> Void)?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        showStart()
    }
    
    func showStart() {
        let presenter = AuthPresenter(coordinator: self)
        let startView = StartView(presenter: presenter)
        let hostingController = UIHostingController(rootView: startView)
        navigationController.setViewControllers([hostingController], animated: false)
    }
    
    func showLogin() {
        let presenter = AuthPresenter(coordinator: self)
        let loginView = LoginView(presenter: presenter)
        let hostingController = UIHostingController(rootView: loginView)
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    func showRegister() {
        let presenter = AuthPresenter(coordinator: self)
        let registerView = RegisterView(presenter: presenter)
        let hostingController = UIHostingController(rootView: registerView)
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    func authSuccess() {
        onAuthSuccess?()
    }
}
