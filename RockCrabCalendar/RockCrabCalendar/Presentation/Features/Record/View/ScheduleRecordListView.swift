//
//  ScheduleRecordListView.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/21.
//

import RockCrabDomain
import SwiftUI

struct ScheduleRecordListView: View {
    @State private var viewModel: ScheduleRecordViewModel

    init(store: ScheduleRecordStoreProtocol) {
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
                                            ScheduleRecordCard(record: record)
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
        }
        .onAppear {
            viewModel.loadRecords()
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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()
}

private struct ScheduleRecordMonthSection: Identifiable {
    let month: Date
    let records: [ScheduleRecord]

    var id: Date { month }
}
