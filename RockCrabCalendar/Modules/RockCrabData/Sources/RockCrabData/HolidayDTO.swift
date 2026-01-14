//
//  HolidayDTO.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 12/17/25.
//

import Foundation

struct HolidayResponse: Codable {
    struct Response: Codable {
        struct Body: Codable {
            struct Items: Codable {
                let item: [HolidayItemJSON]?
            }
            let items: Items?
        }
        let body: Body
    }
    let response: Response
}

public struct HolidayItemJSON: Codable {
    public let locdate: Int
    public let dateName: String
    public let isHoliday: String?

    public init(locdate: Int, dateName: String, isHoliday: String?) {
        self.locdate = locdate
        self.dateName = dateName
        self.isHoliday = isHoliday
    }
}
