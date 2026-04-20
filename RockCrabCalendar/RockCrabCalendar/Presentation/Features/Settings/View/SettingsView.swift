//
//  SettingsView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2026/01/15.
//

import SwiftUI
import UIKit
import RockCrabShared

struct SettingsView: View {
    @AppStorage(AppStorageKeys.preferredAppLanguage, store: AppGroupUserDefaults.shared)
    private var preferredAppLanguageRaw = AppLanguageOption.system.rawValue
    @State private var scheduleVM: QWERScheduleViewModel
    @State private var userVM: UserScheduleViewModel

    @State private var isExporting = false
    @State private var isSyncingServer = false
    @State private var isClearingFetched = false
    @State private var exportURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    @State private var showSyncResult = false
    @State private var syncResultMessage = ""
    @State private var showClearConfirmAlert = false
    @State private var notificationAuthorizationStatus: NotificationAuthorizationStatus = .notDetermined

    init(scheduleVM: QWERScheduleViewModel, userVM: UserScheduleViewModel) {
        _scheduleVM = State(initialValue: scheduleVM)
        _userVM = State(initialValue: userVM)
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QWER 서버 일정")
                            .font(.headline)

                        actionButton(
                            title: "서버에 저장된 스케줄 가져오기",
                            isLoading: isSyncingServer,
                            isDisabled: isSyncingServer || isClearingFetched,
                            action: syncServerSchedules
                        )

                        actionButton(
                            title: "가져온 스케줄 삭제하기",
                            isLoading: isClearingFetched,
                            isDisabled: isSyncingServer || isClearingFetched,
                            action: { showClearConfirmAlert = true }
                        )

                        if let lastFetchedAt = scheduleVM.lastFetchedAt {
                            Text(String.localizedStringWithFormat(
                                AppLocalization.string("마지막 가져오기: %@"),
                                formatDateTime(lastFetchedAt)
                            ))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("아직 서버에서 가져온 스케줄이 없습니다.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("일정")
                            .font(.headline)

                        actionButton(
                            title: "전체 일정 내보내기 (ICS)",
                            isLoading: isExporting,
                            isDisabled: isExporting,
                            action: exportSchedules
                        )
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("알림")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(notificationAuthorizationStatus.summaryText)
                                .font(.subheadline.weight(.semibold))
                            Text(notificationAuthorizationStatus.detailText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("일정 추가/수정 화면에서 일정별 알림 시간을 선택할 수 있어요.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if notificationAuthorizationStatus != .authorized {
                            actionButton(
                                title: "기기 설정에서 알림 켜기",
                                isLoading: false,
                                isDisabled: false,
                                action: openNotificationSettings
                            )
                        }
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("앱 언어")
                            .font(.headline)

                        Menu {
                            Picker("앱 언어", selection: $preferredAppLanguageRaw) {
                                ForEach(AppLanguageOption.allCases) { option in
                                    Text(option.displayName)
                                        .tag(option.rawValue)
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedLanguage.displayName)
                                        .fontWeight(.semibold)
                                    Text("앱과 위젯에 사용할 언어를 선택합니다.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(UIColor.secondarySystemFill))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .foregroundStyle(Color.textColor)
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
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
        .alert("서버 일정 동기화", isPresented: $showSyncResult) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(syncResultMessage)
        }
        .alert("가져온 스케줄을 삭제할까요?", isPresented: $showClearConfirmAlert) {
            Button("삭제", role: .destructive) {
                clearFetchedServerSchedules()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("서버의 원본 데이터는 삭제되지 않습니다. 앱에 저장된 가져온 일정만 삭제합니다.")
        }
        .task {
            await refreshNotificationAuthorizationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await refreshNotificationAuthorizationStatus()
            }
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

    private func syncServerSchedules() {
        isSyncingServer = true

        Task { @MainActor in
            let success = await scheduleVM.syncServerSchedules()
            isSyncingServer = false
            syncResultMessage = success
                ? AppLocalization.string("서버에서 최신 QWER 일정을 가져왔습니다.")
                : AppLocalization.string("서버 일정 가져오기에 실패했습니다. 네트워크 상태를 확인해 주세요.")
            showSyncResult = true
        }
    }

    private func clearFetchedServerSchedules() {
        isClearingFetched = true

        Task { @MainActor in
            await scheduleVM.clearFetchedServerSchedules()
            isClearingFetched = false
            syncResultMessage = AppLocalization.string("가져온 서버 일정을 삭제했습니다. 로컬로 추가한 일정은 유지됩니다.")
            showSyncResult = true
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        return AppDateFormatterFactory.dateTimeFormatter().string(from: date)
    }

    private func refreshNotificationAuthorizationStatus() async {
        notificationAuthorizationStatus = await NotificationManager.shared.authorizationStatus()
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var selectedLanguage: AppLanguageOption {
        AppLanguageOption(rawValue: preferredAppLanguageRaw) ?? .system
    }

    @ViewBuilder
    private func actionButton(
        title: String,
        isLoading: Bool,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(LocalizedStringKey(title))
                    .fontWeight(.semibold)
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(Color.textColor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.secondarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 1)
            )
            .foregroundStyle(Color.textColor)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
