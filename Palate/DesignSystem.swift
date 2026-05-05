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

    static let accentPurple = Color(hex: "#B351F4")
    static let accentGreen = Color(hex: "#84CC16")

    static let lightCategoryBg = Color(hex: "#EAEAEA")
    static let searchBorder = Color(hex: "#B3B3B3")
    static let searchPlaceholder = Color(hex: "#D9D9D9")
}

extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
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
