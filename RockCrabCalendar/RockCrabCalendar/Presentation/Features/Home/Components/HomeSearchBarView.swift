//
//  HomeSearchBarView.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/20.
//

import SwiftUI

struct HomeSearchBarView: View {
    @Binding var text: String

    @FocusState private var isFocused: Bool

    private var animatedTextBinding: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    text = newValue
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("일정 검색", text: animatedTextBinding)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cardBackground)
        )
        .padding(.horizontal, 12)
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }
}
