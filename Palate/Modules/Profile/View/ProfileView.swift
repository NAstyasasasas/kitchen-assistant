//
//  ProfileView.swift
//  Palate
//

import SwiftUI

struct ProfileView: View {
    @StateObject var presenter: ProfilePresenter
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading) {
                            Text(presenter.currentUser?.displayName ?? "Пользователь")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(presenter.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("statistics".localized) {
                    HStack(spacing: 16) {
                        StatCard(
                            title: "cooked".localized,
                            value: "\(presenter.cookedCount)",
                            color: .accentGreen
                        )
                        
                        StatCard(
                            title: "in_plan".localized,
                            value: "\(presenter.wantToCookCount)",
                            color: .accentPurple
                        )
                        
                        StatCard(
                            title: "custom".localized,
                            value: "\(presenter.customRecipesCount)",
                            color: .gray
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                Section("settings".localized) {
                    Toggle("dark_theme".localized, isOn: .constant(false))
                }
                
                Section {
                    Button(action: {
                        presenter.signOut()
                    }) {
                        HStack {
                            Spacer()
                            Text("sign_out".localized)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("profile".localized)
            .task {
                await presenter.loadStats()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .foregroundColor(.accentPurple)
        }
    }
}
