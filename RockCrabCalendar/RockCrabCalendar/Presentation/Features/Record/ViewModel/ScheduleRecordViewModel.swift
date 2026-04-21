//
//  ScheduleRecordViewModel.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/21.
//

import Foundation
import Observation
import RockCrabDomain

@Observable
final class ScheduleRecordViewModel {
    private let store: ScheduleRecordStoreProtocol

    private(set) var records: [ScheduleRecord] = []
    private(set) var errorMessage: String?

    init(store: ScheduleRecordStoreProtocol) {
        self.store = store
    }

    func loadRecords() {
        do {
            records = try store.fetchRecords()
            errorMessage = nil
        } catch {
            errorMessage = "기록을 불러오지 못했습니다."
        }
    }
}
