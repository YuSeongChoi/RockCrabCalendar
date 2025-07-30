//
//  ScheduleViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/30/25.
//

import Foundation
import FirebaseFirestore
import Combine

final class ScheduleViewModel: ObservableObject {
    @Published var schedules: [ScheduleItem] = []
    
    
}
