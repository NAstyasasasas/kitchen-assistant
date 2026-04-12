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
                
                Section("Статистика") {
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Приготовлено",
                            value: "\(presenter.cookedCount)",
                            color: .accentGreen
                        )
                        
                        StatCard(
                            title: "В планах",
                            value: "\(presenter.wantToCookCount)",
                            color: .accentPurple
                        )
                        
                        StatCard(
                            title: "Своих",
                            value: "\(presenter.customRecipesCount)",
                            color: .gray
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Настройки") {
                    Toggle("Темная тема", isOn: .constant(false))
                }
                
                Section {
                    Button(action: {
                        presenter.signOut()
                    }) {
                        HStack {
                            Spacer()
                            Text("Выйти")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Профиль")
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
