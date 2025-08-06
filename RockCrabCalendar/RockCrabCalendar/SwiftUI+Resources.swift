//
//  SwiftUI+Resources.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/25/24.
//

import SwiftUI

import RswiftResources

extension RswiftResources.ImageResource {
    var swiftImage: Image {
        .init(self)
    }
}

extension RswiftResources.ColorResource {
    var swiftColor: Color {
        .init(self)
    }
}

extension FontResource {
    func swiftFontOfSize(_ size: CGFloat) -> Font {
        .custom(self, size: size)
    }
}
