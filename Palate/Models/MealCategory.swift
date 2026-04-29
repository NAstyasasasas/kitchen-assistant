//
//  MealCategory.swift
//  Palate
//

import Foundation

enum CuisineType: String, CaseIterable, Identifiable {
    case italian
    case chinese
    case mexican
    case japanese
    case french
    case american
    case thai
    case indian
    
    var id: String { rawValue }
    
    var apiArea: String {
        switch self {
        case .italian: return "Italian"
        case .chinese: return "Chinese"
        case .mexican: return "Mexican"
        case .japanese: return "Japanese"
        case .french: return "French"
        case .american: return "American"
        case .thai: return "Thai"
        case .indian: return "Indian"
        }
    }
    
    var localizedName: String {
        switch self {
        case .italian: return L10n.italian
        case .chinese: return L10n.chinese
        case .mexican: return L10n.mexican
        case .japanese: return L10n.japanese
        case .french: return L10n.french
        case .american: return L10n.american
        case .thai: return L10n.thai
        case .indian: return L10n.indian
        }
    }
}

enum MealType: String, CaseIterable, Identifiable {
    case beef
    case chicken
    case pork
    case lamb
    case seafood
    case vegetarian
    case pasta
    case dessert
    case breakfast
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .beef: return L10n.beef
        case .chicken: return L10n.chicken
        case .pork: return L10n.pork
        case .lamb: return L10n.lamb
        case .seafood: return L10n.seafood
        case .vegetarian: return L10n.vegetarian
        case .pasta: return L10n.pasta
        case .dessert: return L10n.dessert
        case .breakfast: return L10n.breakfast
        }
    }
    
    var apiCategory: String {
        switch self {
        case .beef: return "Beef"
        case .chicken: return "Chicken"
        case .pork: return "Pork"
        case .lamb: return "Lamb"
        case .seafood: return "Seafood"
        case .vegetarian: return "Vegetarian"
        case .pasta: return "Pasta"
        case .dessert: return "Dessert"
        case .breakfast: return "Breakfast"
        }
    }

    var searchKeywords: [String] {
        switch self {
        case .beef: return ["beef", "steak", "meat", "ground beef", "mince", "brisket", "ribeye", "sirloin"]
        case .chicken: return ["chicken", "hen", "poultry", "chicken breast", "thigh", "drumstick", "wing"]
        case .pork: return ["pork", "bacon", "ham", "sausage", "pancetta", "chorizo", "pork chop", "pork belly"]
        case .lamb: return ["lamb", "mutton", "lamb chop", "lamb leg"]
        case .seafood: return ["seafood", "fish", "salmon", "tuna", "cod", "trout", "mackerel", "sardine", "shrimp", "prawn", "crab", "lobster", "mussel", "oyster", "clam", "scallop", "calamari", "squid", "octopus", "crayfish", "caviar", "ikra", "sea bass", "halibut", "haddock", "pollock", "catfish", "tilapia", "anchovy", "eel", "unagi", "sashimi", "sushi"]
        case .vegetarian: return ["vegetarian", "vegan", "tofu", "mushroom", "vegetable", "plant-based", "lentil", "bean", "chickpea", "broccoli", "spinach", "zucchini", "eggplant", "cauliflower", "carrot", "potato", "avocado"]
        case .pasta: return ["pasta", "spaghetti", "noodle", "macaroni", "fettuccine", "lasagna", "penne", "rigatoni", "ramen", "udon", "soba", "vermicelli"]
        case .dessert: return ["dessert", "cake", "chocolate", "sweet", "pie", "cookie", "biscuit", "ice cream", "pudding", "custard", "brownie", "muffin", "cupcake", "donut", "pastry", "croissant", "cinnamon", "vanilla", "caramel", "honey", "sugar", "cream", "cheesecake", "tiramisu", "mousse", "souffle", "crepe", "waffle", "pancake", "gelato", "sorbet", "milkshake", "smoothie", "fruit", "berry", "strawberry", "chocolate chip"]
        case .breakfast: return ["breakfast", "pancake", "omelette", "scrambled", "french toast", "cereal", "oatmeal", "porridge", "granola", "toast", "muffin", "bagel", "croissant", "yogurt", "smoothie", "eggs", "bacon", "sausage", "hash brown", "waffle", "crepe"]
        }
    }
}

enum MealDBCategory: String, CaseIterable, Identifiable {
    case beef = "Beef"
    case chicken = "Chicken"
    case dessert = "Dessert"
    case lamb = "Lamb"
    case miscellaneous = "Miscellaneous"
    case pasta = "Pasta"
    case pork = "Pork"
    case seafood = "Seafood"
    case side = "Side"
    case starter = "Starter"
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case breakfast = "Breakfast"
    case goat = "Goat"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .beef: return L10n.beef
        case .chicken: return L10n.chicken
        case .dessert: return L10n.dessert
        case .lamb: return L10n.lamb
        case .miscellaneous: return L10n.miscellaneous
        case .pasta: return L10n.pasta
        case .pork: return L10n.pork
        case .seafood: return L10n.seafood
        case .side: return L10n.side
        case .starter: return L10n.starter
        case .vegan: return L10n.vegan
        case .vegetarian: return L10n.vegetarian
        case .breakfast: return L10n.breakfast
        case .goat: return L10n.goat
        }
    }
}

enum IngredientFilter: String, CaseIterable, Identifiable {
    case chicken
    case beef
    case pork
    case fish
    case shrimp
    case egg
    case cheese
    case tomato
    case potato
    case rice
    case pasta
    case salmon
    case caviar
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .chicken: return L10n.chicken
        case .beef: return L10n.beef
        case .pork: return L10n.pork
        case .fish: return L10n.fish
        case .shrimp: return L10n.shrimp
        case .egg: return L10n.egg
        case .cheese: return L10n.cheese
        case .tomato: return L10n.tomato
        case .potato: return L10n.potato
        case .rice: return L10n.rice
        case .pasta: return L10n.pasta
        case .salmon: return L10n.salmon
        case .caviar: return L10n.caviar
        }
    }
    
    var apiQuery: String {
        switch self {
        case .chicken: return "chicken"
        case .beef: return "beef"
        case .pork: return "pork"
        case .fish: return "fish"
        case .shrimp: return "shrimp"
        case .egg: return "egg"
        case .cheese: return "cheese"
        case .tomato: return "tomato"
        case .potato: return "potato"
        case .rice: return "rice"
        case .pasta: return "pasta"
        case .salmon: return "salmon"
        case .caviar: return "caviar"
        }
    }
}

struct RecipeFilters {
    var cuisine: CuisineType?
    var mealType: MealType?
    var mealDBCategory: MealDBCategory?
    var ingredients: Set<IngredientFilter> = []
    
    var hasActiveFilters: Bool {
        cuisine != nil || mealType != nil || mealDBCategory != nil || !ingredients.isEmpty
    }
    
    func reset() -> RecipeFilters {
        return RecipeFilters(cuisine: nil, mealType: nil, mealDBCategory: nil, ingredients: [])
    }
}
