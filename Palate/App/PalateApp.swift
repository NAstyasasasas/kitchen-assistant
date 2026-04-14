//
//  PalateApp.swift
//  Palate
//

import SwiftUI
import Firebase

@main
struct PalateApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var isAuthenticated = false
    
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                MainTabViewContainer()
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("userDidSignOut"))) { _ in
                        isAuthenticated = false
                    }
            } else {
                AuthContainerView(onAuthSuccess: {
                    isAuthenticated = true
                })
            }
        }
    }
}

struct AuthContainerView: View {
    let onAuthSuccess: () -> Void
    
    var body: some View {
        AuthCoordinatorView(onAuthSuccess: onAuthSuccess)
    }
}

struct AuthCoordinatorView: UIViewControllerRepresentable {
    let onAuthSuccess: () -> Void
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()
        let coordinator = AuthCoordinator(navigationController: navigationController)
        coordinator.onAuthSuccess = onAuthSuccess
        coordinator.start()
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

struct MainTabViewContainer: View {
    var body: some View {
        MainCoordinatorView()
    }
}

struct MainCoordinatorView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let coordinator = MainCoordinator()
        coordinator.start()
        return coordinator.rootViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
