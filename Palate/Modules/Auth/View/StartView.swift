//
//  StartView.swift
//  Palate
//

import SwiftUI

struct StartView: View {
    @StateObject var presenter: AuthPresenter
    
    var body: some View {
        ZStack {
            Image("food_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [.black.opacity(0.4), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer(minLength: 380)
                
                VStack(spacing: 16) {
                    Text("Palate")
                        .font(.custom("Condiment-Regular", size: 40))
                        .foregroundColor(.white)
                    
                    Text("Уютное приложение для тех,\nкто любит готовить, экспериментировать\nс рецептами и сохранять кулинарные впечатления")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Spacer()
                    
                    Button {
                        presenter.showRegister()
                    } label: {
                        Text("Регистрация")
                            .fontWeight(.semibold)
                            .frame(maxWidth: 150)
                            .padding()
                            .background(Color.accentPurple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        presenter.showLogin()
                    } label: {
                        Text("Войти")
                            .fontWeight(.semibold)
                            .frame(maxWidth: 150)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.accentPurple)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.accentGreen.opacity(0.95))
                .cornerRadius(40)
                .shadow(color: .black.opacity(0.2), radius: 10)
                .padding(.horizontal)
            }
        }
    }
}
