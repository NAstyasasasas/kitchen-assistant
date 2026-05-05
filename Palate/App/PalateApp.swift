//
//  PalateApp.swift
//  Palate
//

import SwiftUI
import Firebase

@main
struct PalateApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var languageManager = LanguageManager.shared
    @State private var isAuthenticated = false
    @State private var refreshID = UUID()
    
    var body: some Scene {
        WindowGroup {
            Group {
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
            .environmentObject(languageManager)
            .id(refreshID)
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                refreshID = UUID()
            }
        }
    }
}

struct AuthContainerView: View {
    let onAuthSuccess: () -> Void
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        AuthCoordinatorView(onAuthSuccess: onAuthSuccess)
            .id(languageManager.currentLanguage)
    }
}

struct AuthCoordinatorView: UIViewControllerRepresentable {
    let onAuthSuccess: () -> Void
    @EnvironmentObject var languageManager: LanguageManager
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()
        let coordinator = AuthCoordinator(navigationController: navigationController)
        coordinator.onAuthSuccess = onAuthSuccess
        coordinator.start()
        
        context.coordinator.authCoordinator = coordinator
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
        
    class Coordinator: NSObject {
        var authCoordinator: AuthCoordinator?
    }
}

struct MainTabViewContainer: View {
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        MainCoordinatorView()
            .id(languageManager.currentLanguage)
    }
}

struct MainCoordinatorView: UIViewControllerRepresentable {
    @EnvironmentObject var languageManager: LanguageManager
    
    func makeUIViewController(context: Context) -> UIViewController {
        let coordinator = MainCoordinator()
        coordinator.start()
        
        context.coordinator.mainCoordinator = coordinator
        return coordinator.rootViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
        
    class Coordinator: NSObject {
        var mainCoordinator: MainCoordinator?
    }
}
