//
//  ScheduleRecordListView.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/21.
//

import RockCrabDomain
import RockCrabShared
import SwiftUI

struct ScheduleRecordListView: View {
    private let store: ScheduleRecordStoreProtocol
    @State private var viewModel: ScheduleRecordViewModel

    init(store: ScheduleRecordStoreProtocol) {
        self.store = store
        _viewModel = State(initialValue: ScheduleRecordViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                if viewModel.records.isEmpty {
                    EmptyStateView(
                        systemImage: "book.closed",
                        title: "아직 남긴 기록이 없어요",
                        subtitle: viewModel.errorMessage ?? "다녀온 일정의 감정과 사진을 기록해보세요."
                    )
                    .padding(.horizontal, 24)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(monthSections) { section in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(monthTitle(for: section.month))
                                        .font(.headline)
                                        .foregroundStyle(Color.textColor)
                                        .padding(.horizontal, 16)

                                    LazyVStack(spacing: 10) {
                                        ForEach(section.records) { record in
                                            NavigationLink(value: ScheduleRecordTarget(record: record)) {
                                                ScheduleRecordCard(record: record)
                                            }
                                            .buttonStyle(.plain)
                                            .simultaneousGesture(
                                                TapGesture().onEnded {
                                                    AnalyticsHelper.logAction(
                                                        actionName: "record_card_tap",
                                                        label: "기록 카드 선택",
                                                        parameters: [
                                                            "schedule_kind": record.linkedSchedule.kind.analyticsLabel,
                                                            "photo_count": record.photos.count,
                                                            "has_body": record.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1
                                                        ]
                                                    )
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .foregroundStyle(Color.textColor)
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: ScheduleRecordTarget.self) { target in
                ScheduleRecordEditView(
                    viewModel: ScheduleRecordEditViewModel(
                        target: target,
                        store: store
                    ),
                    onRecordChanged: {
                        viewModel.loadRecords()
                    }
                )
            }
        }
        .onAppear {
            viewModel.loadRecords()
            AnalyticsHelper.logScreen(
                screenName: "record_list",
                label: "기록 탭",
                parameters: [
                    "record_count": viewModel.records.count,
                    "is_empty": viewModel.records.isEmpty ? 1 : 0
                ]
            )
        }
    }

    private var monthSections: [ScheduleRecordMonthSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.records) { record in
            calendar.date(
                from: calendar.dateComponents([.year, .month], from: record.linkedSchedule.date)
            ) ?? record.linkedSchedule.date
        }

        return grouped.keys
            .sorted(by: >)
            .map { month in
                ScheduleRecordMonthSection(
                    month: month,
                    records: grouped[month]?.sorted { $0.linkedSchedule.date > $1.linkedSchedule.date } ?? []
                )
            }
    }

    private func monthTitle(for date: Date) -> String {
        Self.monthFormatter.string(from: date)
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = AppDateFormatterFactory.monthYearFormatter()
        return formatter
    }()
}

private struct ScheduleRecordMonthSection: Identifiable {
    let month: Date
    let records: [ScheduleRecord]

    var id: Date { month }
}
