//
//  HomeScheduleFloatingButton.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/14.
//

import SwiftUI

struct HomeScheduleFloatingButton: View {
    @Binding var isExpanded: Bool
    let onAddQWER: () -> Void
    let onAddUser: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    if isExpanded {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { isExpanded = false }
                            onAddQWER()
                        } label: {
                            Label("QWER 스케줄", systemImage: "person.3.fill")
                                .labelStyle(.titleAndIcon)
                                .pretendSemiBold(size: 14)
                                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                                .background(
                                    Capsule().fill(Color.pillBackground)
                                )
                                .foregroundColor(.primary)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { isExpanded = false }
                            onAddUser()
                        } label: {
                            Label("개인 스케줄", systemImage: "person.fill")
                                .labelStyle(.titleAndIcon)
                                .pretendSemiBold(size: 14)
                                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                                .background(
                                    Capsule().fill(Color.pillBackground)
                                )
                                .foregroundColor(.primary)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "xmark.circle" : "plus.circle")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color(UIColor {
                                $0.userInterfaceStyle == .dark ? .RGB_173 : .black
                            }))
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 20)
                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isExpanded)
            }
        }
    }
}
