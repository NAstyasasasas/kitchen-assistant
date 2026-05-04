//
//  MainCoordinator.swift
//  Palate
//

import SwiftUI

final class MainCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private(set) var rootViewController: UIViewController!
    
    func start() {
        let homePresenter = HomePresenter(coordinator: self)
        let homeView = HomeView(presenter: homePresenter)
        
        let profilePresenter = ProfilePresenter(coordinator: self)
        let profileView = ProfileView(presenter: profilePresenter)
        
        let myRecipesPresenter = MyRecipesPresenter(coordinator: self)
        let myRecipesView = MyRecipesView(presenter: myRecipesPresenter)
        
        let shoppingListPresenter = ShoppingListPresenter(coordinator: self)
        let shoppingListView = ShoppingListView(presenter: shoppingListPresenter)
        
        let mealPlanPresenter = MealPlanPresenter(coordinator: self)
        let mealPlanView = MealPlanView(presenter: mealPlanPresenter)
        
        let tabView = TabView {
            mealPlanView
                .tabItem {
                    Label(L10n.plan, systemImage: "calendar")
                }
            
            myRecipesView
                .tabItem {
                    Label(L10n.my, systemImage: "book.fill")
                }
            
            homeView
                .tabItem {
                    Label(L10n.home, systemImage: "magnifyingglass")
                }
                    
            shoppingListView
                .tabItem {
                    Label(L10n.shoppingList, systemImage: "cart.fill")
                }
                    
            profileView
                .tabItem {
                    Label(L10n.profile, systemImage: "person.fill")
                }
        }
        .accentColor(.accentPurple)
        
        let hostingController = UIHostingController(rootView: tabView)
        rootViewController = hostingController
    }
    
    func showRecipeDetail(recipeId: String, source: RecipeSource = .mealDB) {
        let shoppingListPresenter = ShoppingListPresenter(coordinator: self)
        let myRecipesInteractor = MyRecipesInteractor()
        let presenter = RecipeDetailPresenter(
            recipeId: recipeId,
            source: source,
            coordinator: self,
            shoppingListPresenter: shoppingListPresenter,
            myRecipesInteractor: myRecipesInteractor
        )
        let detailView = RecipeDetailView(presenter: presenter, shoppingListPresenter: shoppingListPresenter)
        let hostingController = UIHostingController(rootView: detailView)
        rootViewController?.present(hostingController, animated: true)
    }
    
    func showCreateRecipe() {
        let presenter = CreateRecipePresenter()
        let view = CreateRecipeView(presenter: presenter)
        let hostingController = UIHostingController(rootView: view)
        rootViewController?.present(hostingController, animated: true)
    }
    func showEditRecipe(recipeId: String) {
        let presenter = CreateRecipePresenter(mode: .edit(recipeId: recipeId))
        let view = CreateRecipeView(presenter: presenter)
        let hostingController = UIHostingController(rootView: view)
        rootViewController?.present(hostingController, animated: true)
    }
}
