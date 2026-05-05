//
//  LoginView.swift
//  Palate
//

import SwiftUI
import Foundation

private var authHeader: some View {
    Image("food_bg")
        .resizable()
        .scaledToFill()
        .frame(height: 330)
        .clipped()
}

struct LoginView: View {
    @StateObject var presenter: AuthPresenter
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 0) {
            authHeader
            
            VStack(spacing: 14) {
                Text(L10n.welcomeTitle)
                    .font(.custom("Condiment-Regular", size: 42))
                    .foregroundColor(.accentGreen)
                    .padding(.bottom, 8)
                
                TextField(L10n.email, text: $email)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
                    )
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField(L10n.password, text: $password)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
                    )
                
                Button {
                    Task {
                        await presenter.login(email: email, password: password)
                        if presenter.isAuthenticated {
                            dismiss()
                        }
                    }
                } label: {
                    if presenter.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(L10n.login.uppercased())
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(presenter.isLoading ? Color(.secondaryLabel) : Color.accentPurple)
                .foregroundColor(.white)
                .cornerRadius(8)
                .shadow(color: Color(.label).opacity(0.18), radius: 5, y: 3)
                .disabled(presenter.isLoading)
                
                Button {
                    presenter.showRegister()
                } label: {
                    Text(L10n.noAccount)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(.label))
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .offset(y: -8)
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .alert(L10n.errorGeneral, isPresented: .constant(presenter.errorMessage != nil)) {
            Button("OK") {
                presenter.errorMessage = nil
            }
        } message: {
            Text(presenter.errorMessage ?? "")
        }
    }
}
