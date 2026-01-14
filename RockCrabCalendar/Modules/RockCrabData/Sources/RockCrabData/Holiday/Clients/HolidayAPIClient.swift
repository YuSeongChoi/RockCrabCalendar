//
//  HolidayAPIClient.swift
//  RockCrabCalendar
//
//  Thin API client for holiday endpoints.
//

import Foundation

struct HolidayAPIClient {
    private let apiKey: String

    init(apiKey: String = HOLIDAY_API_KEY) {
        self.apiKey = apiKey
    }

    func fetchHolidayItems(year: Int) async throws -> [HolidayItemJSON] {
        let response = try await HTTPRequestList.HolidayDateInfoRequest(
            apiKey: apiKey,
            solYear: String(year)
        )
        .buildDataRequest()
        .serializingDecodable(HolidayResponse.self, automaticallyCancelling: true)
        .result
        .mapError { $0.underlyingError ?? $0 }
        .get()

        return response.response.body.items?.item ?? []
    }
}
