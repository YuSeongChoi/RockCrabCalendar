//
//  ScheduleRecordEditViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 4/21/26.
//

import Foundation
import RockCrabDomain

@Observable
final class ScheduleRecordEditViewModel {
    let target: ScheduleRecordTarget
    private let store: ScheduleRecordStoreProtocol
    private let originalRecord: ScheduleRecord?

    var form: ScheduleRecordEditFormState
    var errorMessage: String?

    var isEditing: Bool {
        originalRecord != nil
    }

    init(
        target: ScheduleRecordTarget,
        store: ScheduleRecordStoreProtocol
    ) {
        self.target = target
        self.store = store

        let existingRecord = try? store.record(
            linkedTo: target.scheduleID,
            kind: target.kind
        )

        self.originalRecord = existingRecord
        self.form = ScheduleRecordEditFormState(
            record: existingRecord,
            target: target
        )
    }

    @discardableResult
    func save() -> Bool {
        guard form.canSave else {
            errorMessage = "제목 또는 내용을 입력해주세요."
            return false
        }

        let now = Date()
        let record = ScheduleRecord(
            id: originalRecord?.id ?? UUID(),
            linkedSchedule: target.snapshot,
            emoji: form.normalizedEmoji,
            title: form.trimmedTitle.isEmpty ? target.title : form.trimmedTitle,
            body: form.trimmedBody,
            photos: originalRecord?.photos ?? [],
            createdAt: originalRecord?.createdAt ?? now,
            updatedAt: now
        )

        do {
            try store.saveRecord(record)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "기록을 저장하지 못했습니다."
            return false
        }
    }
}
