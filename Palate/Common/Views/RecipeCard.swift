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
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color(.secondaryLabel).opacity(0.2))
                    }
                }
                .frame(height: 115)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(12)
                
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color(.systemBackground).opacity(0.55))
                    .clipShape(Circle())
                    .padding(6)
            }
            
            Text(translatedName ?? recipe.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Text(translatedCategory ?? (recipe.category ?? ""))
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(1)
            
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(height: 230)
        .background(Color.card)
        .cornerRadius(16)
        .shadow(color: Color(.label).opacity(0.16), radius: 4, x: 0, y: 2)
    }
}

