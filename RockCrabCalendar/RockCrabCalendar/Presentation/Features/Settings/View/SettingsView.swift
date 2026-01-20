//
//  SettingsView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2026/01/15.
//

import SwiftUI

struct SettingsView: View {
    @State private var scheduleVM: QWERScheduleViewModel
    @State private var userVM: UserScheduleViewModel

    @State private var isExporting = false
    @State private var exportURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showExportError = false
    @State private var exportErrorMessage = ""

    init(scheduleVM: QWERScheduleViewModel, userVM: UserScheduleViewModel) {
        _scheduleVM = State(initialValue: scheduleVM)
        _userVM = State(initialValue: userVM)
    }

    var body: some View {
        VStack {
            Form {
                Section("일정") {
                    Button {
                        exportSchedules()
                    } label: {
                        HStack {
                            Text("전체 일정 내보내기 (ICS)")
                            Spacer()
                            if isExporting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .foregroundStyle(Color.textColor)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ActivityView(activityItems: [url])
            }
        }
        .alert("내보내기 실패", isPresented: $showExportError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(exportErrorMessage)
        }
    }

    private func exportSchedules() {
        isExporting = true

        Task { @MainActor in
            let qwer = scheduleVM.schedules
            let user = userVM.schedules
            let ics = ICSExporter.makeCalendar(
                qwerSchedules: qwer,
                userSchedules: user
            )
            let filename = "RockCrabCalendar.ics"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            do {
                try ics.write(to: url, atomically: true, encoding: .utf8)
                exportURL = url
                showShareSheet = true
            } catch {
                exportErrorMessage = error.localizedDescription
                showExportError = true
            }

            isExporting = false
        }
    }
}
