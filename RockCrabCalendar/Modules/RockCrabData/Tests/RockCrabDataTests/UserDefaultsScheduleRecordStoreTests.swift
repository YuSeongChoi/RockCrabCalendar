import XCTest
import RockCrabDomain
@testable import RockCrabData

final class UserDefaultsScheduleRecordStoreTests: XCTestCase {
    private var suite: UserDefaults!
    private var store: UserDefaultsScheduleRecordStore!

    override func setUp() {
        super.setUp()
        suite = UserDefaults(suiteName: "UserDefaultsScheduleRecordStoreTests")
        suite.removePersistentDomain(forName: "UserDefaultsScheduleRecordStoreTests")
        store = UserDefaultsScheduleRecordStore(userDefaults: suite)
    }

    override func tearDown() {
        suite.removePersistentDomain(forName: "UserDefaultsScheduleRecordStoreTests")
        suite = nil
        store = nil
        super.tearDown()
    }

    func testSaveAndFetchRecordsSortedByCreatedAtDescending() throws {
        let oldRecord = makeRecord(
            title: "오래된 기록",
            createdAt: Date(timeIntervalSince1970: 0)
        )
        let recentRecord = makeRecord(
            title: "최근 기록",
            createdAt: Date(timeIntervalSince1970: 100)
        )

        try store.saveRecord(oldRecord)
        try store.saveRecord(recentRecord)

        let records = try store.fetchRecords()
        XCTAssertEqual(records.map(\.title), ["최근 기록", "오래된 기록"])
    }

    func testRecordLinkedToScheduleReturnsMatchingRecord() throws {
        let scheduleID = UUID()
        let record = makeRecord(scheduleID: scheduleID, kind: .qwer)

        try store.saveRecord(record)

        let fetched = try store.record(linkedTo: scheduleID, kind: .qwer)
        XCTAssertEqual(fetched?.id, record.id)
    }

    func testSaveRecordReplacesExistingRecordForSameSchedule() throws {
        let scheduleID = UUID()
        let first = makeRecord(
            scheduleID: scheduleID,
            kind: .qwer,
            title: "첫 기록"
        )
        let replacement = makeRecord(
            scheduleID: scheduleID,
            kind: .qwer,
            title: "교체 기록"
        )

        try store.saveRecord(first)
        try store.saveRecord(replacement)

        let records = try store.fetchRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.title, "교체 기록")
        XCTAssertEqual(try store.record(linkedTo: scheduleID, kind: .qwer)?.id, replacement.id)
    }

    func testDeleteRecordReturnsRemovedRecordAndRemovesItFromStore() throws {
        let record = makeRecord()
        try store.saveRecord(record)

        let removed = try store.deleteRecord(id: record.id)

        XCTAssertEqual(removed?.id, record.id)
        XCTAssertTrue(try store.fetchRecords().isEmpty)
    }

    func testRecordLimitsPhotosToFive() throws {
        let photos = (0..<8).map {
            ScheduleRecord.Photo(fileName: "photo-\($0).jpg")
        }

        let record = makeRecord(photos: photos)

        XCTAssertEqual(record.photos.count, ScheduleRecord.maxPhotoCount)
    }
}

private extension UserDefaultsScheduleRecordStoreTests {
    func makeRecord(
        scheduleID: UUID = UUID(),
        kind: ScheduleRecord.LinkedScheduleKind = .qwer,
        title: String = "기록",
        createdAt: Date = Date(timeIntervalSince1970: 0),
        photos: [ScheduleRecord.Photo] = []
    ) -> ScheduleRecord {
        ScheduleRecord(
            linkedSchedule: ScheduleRecord.LinkedScheduleSnapshot(
                kind: kind,
                scheduleID: scheduleID,
                title: "일정",
                date: Date(timeIntervalSince1970: 0)
            ),
            emoji: "🦀",
            title: title,
            body: "회고",
            photos: photos,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}
