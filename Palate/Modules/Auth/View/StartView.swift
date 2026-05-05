//
//  StartView.swift
//  Palate
//

import SwiftUI
import Foundation

struct StartView: View {
    @StateObject var presenter: AuthPresenter
    
    var body: some View {
        ZStack {
            Image("food_bg")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -70)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 18) {
                    Text(L10n.welcomeTitle)
                        .font(.custom("Condiment-Regular", size: 42))
                        .foregroundColor(.white)
                    
                    Text(L10n.welcomeSubtitle)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 10)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    Button {
                        presenter.showRegister()
                    } label: {
                        Text(L10n.register)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 180, height: 44)
                            .background(Color.accentPurple)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
                    }
                    
                    Button {
                        presenter.showLogin()
                    } label: {
                        Text(L10n.login)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.accentPurple)
                            .frame(width: 180, height: 44)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.14), radius: 5, y: 3)
                    }
                }
                .padding(.top, 34)
                .padding(.horizontal, 18)
                .padding(.bottom, 50)
                .frame(maxWidth: .infinity)
                .frame(height: 390)
                .background(Color.accentGreen.opacity(0.96))
                .cornerRadius(34)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 0)
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
