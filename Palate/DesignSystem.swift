//
//  DesignSystem.swift
//  Palate
//
//  Created by Анастасия on 08.04.2026.
//

import Foundation
import SwiftUI

extension Color {
    static let cardBackground = Color.white
    static let bg = Color(.systemGray6)
    static let card = Color.white
    
    static let accentPurple = Color(red: 0.62, green: 0.36, blue: 1.0)
    static let accentGreen = Color(red: 0.5, green: 0.9, blue: 0.4)
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.card)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
}
