//
//  ScheduleEditView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import SwiftUI

struct ScheduleEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ScheduleViewModel
    @State private var title :String = ""
    @State private var date: Date = Date()
    @State private var endDate: Date = Date()
    @State private var place: String = ""
    @State private var repeatOption: RepeatType = .none
    @State private var repeatEndDate: Date = Date()
    @State private var selectedMembers: [QWERMember] = []
    
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("일정 제목", text: $title)
                    DatePicker("시작 시간", selection: $date)
                    DatePicker("종료 시간", selection: $endDate)
                    TextField("장소", text: $place)
                } header: {
                    Text("기본 정보")
                }
            }
            .navigationTitle("일정 추가")
        }
    }
}

extension ScheduleEditView {
    enum RepeatType {
        case none
        case week
        case month
        case year
    }
}
