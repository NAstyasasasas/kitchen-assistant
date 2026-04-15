//
//  APIService.swift
//  Palate
//

import Foundation

struct APIConstants {
    static let baseURL = "https://www.themealdb.com/api/json/v1/1"
}

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
}

class APIService {
    static let shared = APIService()
    private let baseURL = APIConstants.baseURL
    
    private init() {}
    
    func fetchCategories() async throws -> [Category] {
        guard let url = URL(string: "\(baseURL)/categories.php") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(CategoriesResponse.self, from: data)
        return response.categories
    }
    
    func fetchRecipesByCategory(_ category: String) async throws -> [Recipe] {
        let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
        guard let url = URL(string: "\(baseURL)/filter.php?c=\(encodedCategory)") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RecipesResponse.self, from: data)
        return response.meals ?? []
    }
    
    func fetchRecipesByArea(_ area: String) async throws -> [Recipe] {
        let encodedArea = area.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? area
        guard let url = URL(string: "\(baseURL)/filter.php?a=\(encodedArea)") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RecipesResponse.self, from: data)
        return response.meals ?? []
    }
    
    func searchRecipes(query: String) async throws -> [Recipe] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/search.php?s=\(encodedQuery)") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RecipesResponse.self, from: data)
        return response.meals ?? []
    }
    
    func fetchRecipeDetail(id: String) async throws -> Recipe {
        guard let url = URL(string: "\(baseURL)/lookup.php?i=\(id)") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RecipesResponse.self, from: data)
        
        guard let recipe = response.meals?.first else {
            throw APIError.noData
        }
        
        return recipe
    }
    
    func fetchRecipesByIngredient(_ ingredient: String) async throws -> [Recipe] {
        let encodedIngredient = ingredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ingredient
        guard let url = URL(string: "\(baseURL)/filter.php?i=\(encodedIngredient)") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RecipesResponse.self, from: data)
        return response.meals ?? []
    }
}
