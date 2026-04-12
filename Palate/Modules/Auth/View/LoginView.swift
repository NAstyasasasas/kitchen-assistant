//
//  LoginView.swift
//  Palate
//

import SwiftUI

struct LoginView: View {
    @StateObject var presenter: AuthPresenter
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: 300)
            
            VStack(spacing: 16) {
                Text("Palate")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.accentPurple)
                    .padding(.bottom, 10)
                
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Пароль", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                Button {
                    Task {
                        await presenter.login(email: email, password: password)
                        if presenter.isAuthenticated {
                            dismiss()
                        }
                    }
                } label: {
                    if presenter.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("ВОЙТИ")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(presenter.isLoading ? Color.gray : Color.accentPurple)
                .foregroundColor(.white)
                .cornerRadius(14)
                .disabled(presenter.isLoading)
                
                Button("Нет аккаунта? Зарегистрироваться") {
                    presenter.showRegister()
                }
                .font(.caption)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(30)
            .shadow(color: .black.opacity(0.1), radius: 10)
            .padding()
            
            Spacer()
        }
        .background(Color(.systemGray6))
        .alert("Ошибка входа", isPresented: .constant(presenter.errorMessage != nil)) {
            Button("OK") {
                presenter.errorMessage = nil
            }
        } message: {
            Text(presenter.errorMessage ?? "")
        }
    }
    
    var header: some View {
        ZStack(alignment: .bottom) {
            Image("food_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 620)
                .clipped()
            
            LinearGradient(
                colors: [.clear, .white],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
