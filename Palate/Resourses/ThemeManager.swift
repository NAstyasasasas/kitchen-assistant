//
//  ThemeManager.swift
//  Palate

import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("isDarkTheme") var isDarkTheme: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }

    private init() {}
}
