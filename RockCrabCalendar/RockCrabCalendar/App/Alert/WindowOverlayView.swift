//
//  WindowOverlayView.swift
//  Lucid (refactored for iOS 17)
//
//
//
//  기능 요약
//  - 별도 UIWindow 를 만들어 앱 최상단 레벨에서 SwiftUI 뷰를 오버레이로 표시
//  - iOS 17 최소 타겟 기준으로 레거시 분기 제거
//  - Environment(\.windowScene) 의존 제거: UIApplication 의 활성 UIWindowScene 에 직접 부착
//  - 오버레이 루트가 hit 되면 터치 이벤트를 하위 뷰로 통과시킴
//

import SwiftUI
import UIKit

// MARK: - 외부에서 사용하는 래퍼 View
public struct WindowOverlayView<Content: View>: View {
    public var level: CGFloat
    public var isHidden: Bool
    private let content: Content

    /// 기존 API 유지 (level / isHidden / content)
    @usableFromInline
    internal init(level: CGFloat, isHidden: Bool, content: Content) {
        self.level = level
        self.isHidden = isHidden
        self.content = content
    }

    @inlinable
    public init(level: CGFloat, isHidden: Bool, @ViewBuilder content: () -> Content) {
        self.init(level: level, isHidden: isHidden, content: content())
    }

    public var body: some View {
        OverlayWindowHost(isHidden: isHidden, level: .init(level)) { content }
            .frame(width: 0, height: 0)   // 레이아웃 영향 제거
            .allowsHitTesting(false)      // 자체 SwiftUI 뷰는 터치 대상 아님 (윈도우에서 처리)
    }
}

public extension WindowOverlayView where Content == EmptyView {
    @inlinable
    init() {
        self.init(level: 0, isHidden: true, content: .init())
    }
}

// MARK: - 오버레이용 UIWindow
@MainActor
final class OverlayWindow: UIWindow {
    // keyWindow 가 되지 않도록
    nonisolated override var canBecomeKey: Bool { false }

    // 루트 뷰 자체가 hit 되면 이벤트 통과
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let target = super.hitTest(point, with: event) else { return nil }
        return (rootViewController?.view === target) ? nil : target
    }
}

// MARK: - UIViewRepresentable Host
/// SwiftUI 콘텐츠를 별도 UIWindow 에 마운트해주는 호스트
struct OverlayWindowHost<Content: View>: UIViewRepresentable {
    typealias UIViewType = UIView

    let isHidden: Bool
    let level: UIWindow.Level
    let content: Content

    init(isHidden: Bool, level: UIWindow.Level, @ViewBuilder content: () -> Content) {
        self.isHidden = isHidden
        self.level = level
        self.content = content()
    }

    final class Coordinator {
        var window: OverlayWindow?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIViewType {
        let view = UIView()
        view.backgroundColor = .clear
        attachWindowIfNeeded(context: context)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        // 윈도우가 없으면 재부착 시도 (Scene 교체 대비)
        if context.coordinator.window == nil {
            attachWindowIfNeeded(context: context)
        }
        guard let window = context.coordinator.window else { return }

        // 레벨/가시성/인터랙션 갱신
        window.windowLevel = level
        window.isHidden = isHidden
        window.isUserInteractionEnabled = context.environment.isEnabled

        // 루트 뷰 갱신
        if let hosting = window.rootViewController as? UIHostingController<Content> {
            withTransaction(context.transaction) {
                hosting.rootView = content
            }
        } else {
            let hosting = UIHostingController(rootView: content)
            hosting.view.backgroundColor = nil
            withTransaction(context.transaction) {
                window.rootViewController = hosting
            }
        }
    }

    // 활성 UIWindowScene 에 오버레이 윈도우 부착
    private func attachWindowIfNeeded(context: Context) {
        DispatchQueue.main.async {
            guard context.coordinator.window == nil else { return }

            // 1) 포그라운드 활성 Scene 우선, 없으면 첫 번째 Scene 사용
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
            guard let scene else { return }

            let window = OverlayWindow(windowScene: scene)
            window.backgroundColor = nil
            window.windowLevel = level
            window.isHidden = isHidden
            window.rootViewController = UIHostingController(rootView: content)
            window.makeKeyAndVisible()
            context.coordinator.window = window
        }
    }
}
