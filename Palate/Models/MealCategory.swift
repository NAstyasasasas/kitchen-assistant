//
//  MealCategory.swift
//  Palate
//

import Foundation

enum CuisineType: String, CaseIterable, Identifiable {
    case italian = "Итальянская"
    case chinese = "Китайская"
    case mexican = "Мексиканская"
    case japanese = "Японская"
    case french = "Французская"
    case american = "Американская"
    case thai = "Тайская"
    case indian = "Индийская"
    
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
}

enum MealType: String, CaseIterable, Identifiable {
    case beef = "Говядина"
    case chicken = "Курица"
    case pork = "Свинина"
    case lamb = "Баранина"
    case seafood = "Морепродукты"
    case vegetarian = "Вегетарианское"
    case pasta = "Паста"
    case dessert = "Десерты"
    case breakfast = "Завтраки"
    
    var id: String { rawValue }
    
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
        case .beef:
            return ["beef", "steak", "meat", "ground beef", "mince", "brisket", "ribeye", "sirloin"]
            
        case .chicken:
            return ["chicken", "hen", "poultry", "chicken breast", "thigh", "drumstick", "wing"]
            
        case .pork:
            return ["pork", "bacon", "ham", "sausage", "pancetta", "chorizo", "pork chop", "pork belly"]
            
        case .lamb:
            return ["lamb", "mutton", "lamb chop", "lamb leg"]
            
        case .seafood:
            return [
                "seafood", "fish", "salmon", "tuna", "cod", "trout", "mackerel", "sardine",
                "shrimp", "prawn", "crab", "lobster", "mussel", "oyster", "clam", "scallop",
                "calamari", "squid", "octopus", "crayfish", "caviar", "ikra",
                "sea bass", "halibut", "haddock", "pollock", "catfish", "tilapia",
                "anchovy", "eel", "unagi", "sashimi", "sushi"
            ]
            
        case .vegetarian:
            return [
                "vegetarian", "vegan", "tofu", "mushroom", "vegetable", "plant-based",
                "lentil", "bean", "chickpea", "broccoli", "spinach", "zucchini",
                "eggplant", "cauliflower", "carrot", "potato", "avocado"
            ]
            
        case .pasta:
            return [
                "pasta", "spaghetti", "noodle", "macaroni", "fettuccine", "lasagna",
                "penne", "rigatoni", "ramen", "udon", "soba", "vermicelli"
            ]
            
        case .dessert:
            return [
                "dessert", "cake", "chocolate", "sweet", "pie", "cookie", "biscuit",
                "ice cream", "pudding", "custard", "brownie", "muffin", "cupcake",
                "donut", "pastry", "croissant", "cinnamon", "vanilla", "caramel",
                "honey", "sugar", "cream", "cheesecake", "tiramisu", "mousse",
                "souffle", "crepe", "waffle", "pancake", "gelato", "sorbet",
                "milkshake", "smoothie", "fruit", "berry", "strawberry", "chocolate chip"
            ]
            
        case .breakfast:
            return [
                "breakfast", "pancake", "omelette", "scrambled", "french toast",
                "cereal", "oatmeal", "porridge", "granola", "toast", "muffin",
                "bagel", "croissant", "yogurt", "smoothie", "eggs", "bacon",
                "sausage", "hash brown", "waffle", "crepe"
            ]
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
    
    var displayName: String {
        switch self {
        case .beef: return "Говядина"
        case .chicken: return "Курица"
        case .dessert: return "Десерты"
        case .lamb: return "Баранина"
        case .miscellaneous: return "Разное"
        case .pasta: return "Паста"
        case .pork: return "Свинина"
        case .seafood: return "Морепродукты"
        case .side: return "Гарниры"
        case .starter: return "Закуски"
        case .vegan: return "Веганское"
        case .vegetarian: return "Вегетарианское"
        case .breakfast: return "Завтраки"
        case .goat: return "Козлятина"
        }
    }
}

enum IngredientFilter: String, CaseIterable, Identifiable {
    case chicken = "Курица"
    case beef = "Говядина"
    case pork = "Свинина"
    case fish = "Рыба"
    case shrimp = "Креветки"
    case egg = "Яйца"
    case cheese = "Сыр"
    case tomato = "Помидоры"
    case potato = "Картофель"
    case rice = "Рис"
    case pasta = "Паста"
    case salmon = "Лосось"
    case caviar = "Икра"
    
    var id: String { rawValue }
    
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
