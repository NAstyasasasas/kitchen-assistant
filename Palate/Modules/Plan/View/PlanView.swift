//
//  PlanView.swift
//  Palate
//


import SwiftUI

struct PlanView: View {
    var body: some View {
        NavigationView {
            Text(L10n.planTitle)
            .navigationTitle(L10n.plan)
        }
    }
}
