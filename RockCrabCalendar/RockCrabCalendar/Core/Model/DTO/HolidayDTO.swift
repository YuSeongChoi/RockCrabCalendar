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

struct HolidayItemJSON: Codable {
    let locdate: Int
    let dateName: String
    let isHoliday: String?
}
