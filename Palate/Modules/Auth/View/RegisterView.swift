//
//  RegisterView.swift
//  Palate
//

import Foundation
import SwiftUI

struct RegisterView: View {
    @StateObject var presenter: AuthPresenter
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: 300)
            
            VStack(spacing: 16) {
                TextField("name".localized, text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                TextField("email".localized, text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                VStack(alignment: .leading, spacing: 4) {
                    SecureField("password".localized, text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Text("min_password".localized)
                        .font(.caption)
                        .foregroundColor(password.count >= 6 ? .green : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    SecureField("confirm_password".localized, text: $confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    if !confirmPassword.isEmpty {
                        HStack {
                            Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(password == confirmPassword ? .green : .red)
                            Text(password == confirmPassword ? "passwords_match".localized : "passwords_dont_match".localized)
                                .font(.caption)
                                .foregroundColor(password == confirmPassword ? .green : .red)
                        }
                    }
                }
                
                Button {
                    Task {
                        await presenter.register(email: email, password: password, confirmPassword: confirmPassword, displayName: name)
                        if presenter.isAuthenticated {
                            dismiss()
                        }
                    }
                } label: {
                    if presenter.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("register".localized.uppercased())
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValid && !presenter.isLoading ? Color.accentPurple : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(!isValid || presenter.isLoading)
                
                Button("already_have_account".localized) {
                    presenter.showLogin()
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
        .alert("error_general".localized, isPresented: .constant(presenter.errorMessage != nil)) {
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
            
            Text("Palate")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.accentPurple)
                .padding(.bottom, 10)
        }
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") && email.contains(".") &&
        password.count >= 6 &&
        password == confirmPassword
    }
}
