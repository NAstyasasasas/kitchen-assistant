//
//  LoginView.swift
//  Palate
//

import Foundation
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
                Text(L10n.welcomeTitle)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.accentPurple)
                    .padding(.bottom, 10)
                
                TextField(L10n.email, text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField(L10n.password, text: $password)
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
                        Text(L10n.login.uppercased())
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(presenter.isLoading ? Color.gray : Color.accentPurple)
                .foregroundColor(.white)
                .cornerRadius(14)
                .disabled(presenter.isLoading)
                
                Button(L10n.noAccount) {
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
        .alert(L10n.errorGeneral, isPresented: .constant(presenter.errorMessage != nil)) {
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
