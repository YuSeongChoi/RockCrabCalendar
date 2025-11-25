//
//  ScheduleCardUserView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 10/17/25.
//

import SwiftUI

struct ScheduleCardUserView: View {
    let item: UserScheduleItem
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ScheduleCardUserView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleCardUserView(
            item: .init(title: "테스트", date: Date(), time: "15:00", place: "강남"),
            color: .pastelMing,
            onTap: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
