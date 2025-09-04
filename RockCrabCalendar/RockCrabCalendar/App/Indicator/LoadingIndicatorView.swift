//
//  LoadingIndicatorView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/4/25.
//

import SwiftUI

struct LoadingIndicatorView: View {
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()
            
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.0)
                .tint(.white)
                .padding(24)
                .background(Color.black.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .transition(.opacity)
    }
}


#Preview {
    LoadingIndicatorView()
}
