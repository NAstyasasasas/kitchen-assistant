//
//  SearchBar.swift
//  Palate
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var onSearch: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(.secondaryLabel))
            
            TextField(L10n.searchPlaceholder, text: $text)
                .font(.system(size: 16))
                .onSubmit(onSearch)
            
            if !text.isEmpty {
                Button {
                    text = ""
                    onSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}
