//
//  RegisterView.swift
//  Palate
//

import Foundation
import SwiftUI

private var authHeader: some View {
    ZStack {
        Image("food_bg")
            .resizable()
            .scaledToFill()
            .frame(width: UIScreen.main.bounds.width, height: 390)
            .offset(y: -45)
    }
    .frame(width: UIScreen.main.bounds.width, height: 280)
}

struct RegisterView: View {
    @StateObject var presenter: AuthPresenter
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 0) {
            authHeader
            
            VStack(spacing: 12) {
                Text(L10n.welcomeTitle)
                    .font(.custom("Condiment-Regular", size: 42))
                    .foregroundColor(.accentGreen)
                    .padding(.bottom, 8)
                
                authField(L10n.name, text: $name)
                
                authField(L10n.email, text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                VStack(alignment: .leading, spacing: 4) {
                    authSecureField(L10n.password, text: $password)
                    
                    Text(L10n.minPassword)
                        .font(.system(size: 11))
                        .foregroundColor(password.count >= 6 ? .green : Color(.secondaryLabel))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    authSecureField(L10n.confirmPassword, text: $confirmPassword)
                    
                    if !confirmPassword.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(password == confirmPassword ? L10n.passwordsMatch : L10n.passwordsDontMatch)
                        }
                        .font(.system(size: 11))
                        .foregroundColor(password == confirmPassword ? .green : .red)
                    }
                }
                
                Button {
                    Task {
                        await presenter.register(
                            email: email,
                            password: password,
                            confirmPassword: confirmPassword,
                            displayName: name
                        )
                        if presenter.isAuthenticated {
                            dismiss()
                        }
                    }
                } label: {
                    if presenter.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(L10n.register.uppercased())
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isValid && !presenter.isLoading ? Color.accentPurple : Color(.secondaryLabel))
                .foregroundColor(.white)
                .cornerRadius(8)
                .shadow(color: Color(.label).opacity(0.18), radius: 5, y: 3)
                .disabled(!isValid || presenter.isLoading)
                .padding(.top, 6)
                
                Button {
                    presenter.showLogin()
                } label: {
                    Text(L10n.alreadyHaveAccount)
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
            .offset(y: -58)
            
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
    
    private func authField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .font(.system(size: 14))
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
            )
    }
    
    private func authSecureField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .font(.system(size: 14))
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.secondaryLabel).opacity(0.35), lineWidth: 1)
            )
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        email.contains(".") &&
        password.count >= 6 &&
        password == confirmPassword
    }
}
