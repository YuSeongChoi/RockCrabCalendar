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
    private let photoStore: RecordPhotoStore
    private let originalRecord: ScheduleRecord?
    private var newlyAddedFileNames: Set<String> = []
    private var pendingDeletedFileNames: Set<String> = []

    var form: ScheduleRecordEditFormState
    var photos: [ScheduleRecord.Photo]
    var errorMessage: String?
    var errorTitle: String = "저장 실패"

    var isEditing: Bool {
        originalRecord != nil
    }

    var canAddPhoto: Bool {
        photos.count < ScheduleRecord.maxPhotoCount
    }

    var canSave: Bool {
        form.trimmedBody.isEmpty == false || photos.isEmpty == false
    }

    init(
        target: ScheduleRecordTarget,
        store: ScheduleRecordStoreProtocol,
        photoStore: RecordPhotoStore = RecordPhotoStore()
    ) {
        self.target = target
        self.store = store
        self.photoStore = photoStore

        let existingRecord = try? store.record(
            linkedTo: target.scheduleID,
            kind: target.kind
        )

        self.originalRecord = existingRecord
        self.form = ScheduleRecordEditFormState(
            record: existingRecord,
            target: target
        )
        self.photos = existingRecord?.photos ?? []
    }

    @discardableResult
    func save() -> Bool {
        guard canSave else {
            errorMessage = "내용 또는 사진을 추가해주세요."
            return false
        }

        let now = Date()
        let record = ScheduleRecord(
            id: originalRecord?.id ?? UUID(),
            linkedSchedule: target.snapshot,
            emoji: form.normalizedEmoji,
            title: target.title,
            body: form.trimmedBody,
            photos: photos,
            createdAt: originalRecord?.createdAt ?? now,
            updatedAt: now
        )

        do {
            try store.saveRecord(record)
            deletePendingPhotos()
            newlyAddedFileNames.removeAll()
            errorMessage = nil
            return true
        } catch {
            errorTitle = "저장 실패"
            errorMessage = "기록을 저장하지 못했습니다."
            return false
        }
    }

    @discardableResult
    func deleteRecord() -> Bool {
        guard let originalRecord else { return false }

        do {
            let removedRecord = try store.deleteRecord(id: originalRecord.id) ?? originalRecord
            deletePhotos(removedRecord.photos)
            deletePhotos(photos)
            deletePendingPhotos()
            newlyAddedFileNames.removeAll()
            errorMessage = nil
            return true
        } catch {
            errorTitle = "삭제 실패"
            errorMessage = "기록을 삭제하지 못했습니다."
            return false
        }
    }

    func addPhoto(data: Data) {
        guard canAddPhoto else {
            errorMessage = "사진은 최대 \(ScheduleRecord.maxPhotoCount)장까지 추가할 수 있습니다."
            return
        }

        do {
            let fileName = try photoStore.saveImageData(data)
            newlyAddedFileNames.insert(fileName)
            photos.append(
                ScheduleRecord.Photo(
                    fileName: fileName,
                    createdAt: Date()
                )
            )
            errorMessage = nil
        } catch {
            errorMessage = "사진을 추가하지 못했습니다."
        }
    }

    func removePhoto(id: UUID) {
        guard let index = photos.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = photos.remove(at: index)
        if newlyAddedFileNames.remove(removed.fileName) != nil {
            photoStore.delete(fileName: removed.fileName)
        } else {
            pendingDeletedFileNames.insert(removed.fileName)
        }
    }

    func imageData(for photo: ScheduleRecord.Photo) -> Data? {
        photoStore.imageData(fileName: photo.fileName)
    }

    func discardUnsavedPhotoFiles() {
        newlyAddedFileNames.forEach {
            photoStore.delete(fileName: $0)
        }
        newlyAddedFileNames.removeAll()
    }

    private func deletePendingPhotos() {
        pendingDeletedFileNames.forEach {
            photoStore.delete(fileName: $0)
        }
        pendingDeletedFileNames.removeAll()
    }

    private func deletePhotos(_ photos: [ScheduleRecord.Photo]) {
        photos.forEach {
            photoStore.delete(fileName: $0.fileName)
        }
    }
}
