//
//  Recipe.swift
//  Palate
//

import Foundation

enum RecipeSource: String, Codable {
    case mealDB = "MEAL_DB"
    case custom = "CUSTOM"
}

enum RecipeStatus: String, Codable {
    case wantToCook = "WANT_TO_COOK"
    case cooked = "COOKED"
}

struct Ingredient: Codable, Identifiable {
    var id = UUID()
    let name: String
    let amount: String
    let unit: String
    
    init(name: String, amount: String, unit: String) {
        self.name = name
        self.amount = amount
        self.unit = unit
    }
}

struct Recipe: Identifiable, Codable {
    let id: String
    let source: RecipeSource
    let name: String
    let category: String?
    let cuisine: String?
    let imageUrl: String?
    let ingredients: [Ingredient]
    let instructions: String?
    let createdAt: Date
    let updatedAt: Date

    init(id: String = UUID().uuidString,
         source: RecipeSource = .mealDB,
         name: String,
         category: String? = nil,
         cuisine: String? = nil,
         imageUrl: String? = nil,
         ingredients: [Ingredient],
         instructions: String? = nil) {
        self.id = id
        self.source = source
        self.name = name
        self.category = category
        self.cuisine = cuisine
        self.imageUrl = imageUrl
        self.ingredients = ingredients
        self.instructions = instructions
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        cuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        
        var tempIngredients: [Ingredient] = []
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKeys.self)
        
        for i in 1...20 {
            let ingredientKey = DynamicCodingKeys(stringValue: "strIngredient\(i)")!
            let measureKey = DynamicCodingKeys(stringValue: "strMeasure\(i)")!
            
            if let ingredient = try dynamicContainer.decodeIfPresent(String.self, forKey: ingredientKey),
               let measure = try dynamicContainer.decodeIfPresent(String.self, forKey: measureKey),
               !ingredient.isEmpty, !measure.isEmpty {
                tempIngredients.append(Ingredient(name: ingredient, amount: measure, unit: ""))
            }
        }
        
        ingredients = tempIngredients
        source = .mealDB
        createdAt = Date()
        updatedAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "idMeal"
        case name = "strMeal"
        case category = "strCategory"
        case cuisine = "strArea"
        case imageUrl = "strMealThumb"
        case instructions = "strInstructions"
        case source, ingredients, createdAt, updatedAt
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

struct CategoriesResponse: Codable {
    let categories: [Category]
}

struct Category: Codable, Identifiable {
    let idCategory: String
    let strCategory: String
    let strCategoryThumb: String
    let strCategoryDescription: String
    
    var id: String { idCategory }
}

struct RecipesResponse: Codable {
    let meals: [Recipe]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let mealsArray = try? container.decode([Recipe].self, forKey: .meals) {
            meals = mealsArray
        } else {
            meals = []
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case meals
    }
}
