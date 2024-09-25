//
//  SwiftUI+Extension.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/25/24.
//

import SwiftUI

import RswiftResources

extension Text {
    func NotoSansReg(size: CGFloat) -> Text {
        self.font(R.font.notoSansCJKkrRegular.swiftFontOfSize(size))
    }
    
    func NotoSansMid(size: CGFloat) -> Text {
        self.font(R.font.notoSansCJKkrMedium.swiftFontOfSize(size))
    }
    
    func NotoSansBold(size: CGFloat) -> Text {
        self.font(R.font.notoSansCJKkrBold.swiftFontOfSize(size))
    }
    
    func LatoReg(size: CGFloat) -> Text {
        self.font(R.font.latoRegular.swiftFontOfSize(size))
    }
    
    func LatoBold(size: CGFloat) -> Text {
        self.font(R.font.latoBold.swiftFontOfSize(size))
    }
    
    func pretendBold(size: CGFloat) -> Text {
        self.font(R.font.pretendardBold.swiftFontOfSize(size))
    }
    
    func pretendSemiBold(size: CGFloat) -> Text {
        self.font(R.font.pretendardSemiBold.swiftFontOfSize(size))
    }
    
    func pretendMid(size: CGFloat) -> Text {
        self.font(R.font.pretendardMedium.swiftFontOfSize(size))
    }
    
    func pretendReg(size: CGFloat) -> Text {
        self.font(R.font.pretendardRegular.swiftFontOfSize(size))
    }
}

extension View {
    func NotoSansReg(size: CGFloat) -> some View {
        self.font(R.font.notoSansCJKkrRegular.swiftFontOfSize(size))
    }
    
    func NotoSansMid(size: CGFloat) -> some View {
        self.font(R.font.notoSansCJKkrMedium.swiftFontOfSize(size))
    }
    
    func NotoSansBold(size: CGFloat) -> some View {
        self.font(R.font.notoSansCJKkrBold.swiftFontOfSize(size))
    }
    
    func LatoReg(size: CGFloat) -> some View {
        self.font(R.font.latoRegular.swiftFontOfSize(size))
    }
    
    func LatoBold(size: CGFloat) -> some View {
        self.font(R.font.latoBold.swiftFontOfSize(size))
    }
    
    func pretendSemiBold(size: CGFloat) -> some View {
        self.font(R.font.pretendardSemiBold.swiftFontOfSize(size))
    }
    
    func pretendBold(size: CGFloat) -> some View {
        self.font(R.font.pretendardBold.swiftFontOfSize(size))
    }
    
    func pretendMid(size: CGFloat) -> some View {
        self.font(R.font.pretendardMedium.swiftFontOfSize(size))
    }
    
    func pretendReg(size: CGFloat) -> some View {
        self.font(R.font.pretendardRegular.swiftFontOfSize(size))
    }
}
