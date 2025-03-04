//
//  TodoItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2/27/25.
//

import Foundation

struct TodoItem: Identifiable, Codable {
    var id: UUID = UUID() 
    let title: String
    var isComplted: Bool = false
}
