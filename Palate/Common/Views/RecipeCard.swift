//
//  RecipeCard.swift
//  Palate
//

import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    let translatedName: String?
    let translatedCategory: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(height: 120)
            .clipped()
            .cornerRadius(12)
            
            Text(translatedName ?? recipe.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            if let category = recipe.category {
                Text(translatedCategory ?? category)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
