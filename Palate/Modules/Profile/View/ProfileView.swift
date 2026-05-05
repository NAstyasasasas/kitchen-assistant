//
//  ProfileView.swift
//  Palate
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject var presenter: ProfilePresenter
    @StateObject private var languageManager = LanguageManager.shared
    @State private var selectedAvatarItem: PhotosPickerItem?
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        profileHeader
                        statisticsBlock
                        settingsBlock

                        Spacer(minLength: 250)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }

                logoutButton
                    .padding(.horizontal, 64)
                    .padding(.bottom, 18)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .task {
                await presenter.loadStats()
            }
        }
    }

    private var profileHeader: some View {
        HStack(alignment: .center, spacing: 28) {
            ZStack {
                RoundedRectangle(cornerRadius: 42)
                    .fill(Color(hex: "#EEE8F2"))

                if let avatarUrl = presenter.currentUser?.avatarUrl,
                   let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 72))
                                .foregroundColor(Color(hex: "#C8C1CC"))
                        }
                    }
                    .frame(width: 132, height: 132)
                    .clipped()
                    .cornerRadius(42)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(Color(hex: "#C8C1CC"))
                }
            }
            .frame(width: 132, height: 132)

            VStack(alignment: .leading, spacing: 10) {
                Text(presenter.currentUser?.displayName ?? "")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(.label))

                Text(presenter.currentUser?.email ?? "")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#4F4A55"))

                PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .bold))
                        Text(L10n.loadPhoto)
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 48)
                    .background(Color.accentGreen)
                    .cornerRadius(24)
                }
                .padding(.top, 4)
                .onChange(of: selectedAvatarItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await presenter.updateAvatar(image)
                        }
                        selectedAvatarItem = nil
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var statisticsBlock: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(L10n.statistics)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(.label))

            HStack(spacing: 14) {
                StatCard(title: L10n.cooked, value: "\(presenter.cookedCount)", color: .accentGreen)
                StatCard(title: L10n.inPlan, value: "\(presenter.wantToCookCount)", color: .accentPurple)
                StatCard(title: L10n.custom, value: "\(presenter.customRecipesCount)", color: Color(.secondaryLabel))
            }
        }
    }

    private var settingsBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.settings)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(.label))
                .padding(.horizontal, 4)

            HStack {
                Text(L10n.darkTheme)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(.label))

                Spacer()

                Toggle("", isOn: $themeManager.isDarkTheme)
                    .labelsHidden()
                    .tint(.accentPurple)
            }
            .padding(.horizontal, 22)
            .frame(height: 50)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.secondaryLabel).opacity(0.45), lineWidth: 1.3)
            )

            Menu {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button(language.displayName) {
                        languageManager.appLanguage = language
                    }
                }
            } label: {
                HStack {
                    Text(L10n.language)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(.label))

                    Spacer()

                    Text(languageManager.appLanguage.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabel))

                    Image(systemName: "chevron.down")
                        .foregroundColor(Color(.secondaryLabel))
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 22)
                .frame(height: 50)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.secondaryLabel).opacity(0.45), lineWidth: 1.3)
                )
            }
        }
    }

    private var logoutButton: some View {
        Button {
            presenter.signOut()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 20, weight: .bold))
                Text(L10n.signOut)
                    .font(.system(size: 20, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(hex: "#FF3B3B"))
            .cornerRadius(32)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color, lineWidth: 1.5)
        )
        .shadow(color: Color(.label).opacity(0.16), radius: 4, x: 0, y: 3)
    }
}
