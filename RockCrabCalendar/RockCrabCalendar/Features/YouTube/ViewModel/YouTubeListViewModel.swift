//
//  YouTubeListViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/9/25.
//

import Foundation

@Observable
final class YouTubeListViewModel {
    // MARK: - 공개 상태 (View에서 바인딩)
    private(set)var youtubeList: [YouTubeVideo] = []    // 화면에 뿌릴 목록
    private(set)var isLoading: Bool = false             // 최초/추가 로딩
    private(set)var isRefreshing: Bool = false          // 리프레시 로딩
    private(set)var lastSyncedAt: Date? = nil           // 마지막 동기화 시작 (UI 표시용)
    private(set)var channelThumnailURL: URL? = nil      // 채널 썸네일 URL (동글안 이미지용)
    
    // MARK: - 페이징 상태
    private var nextPageToken: String?      // 다음 페이지 토큰
    private var hasMore: Bool = true        // 다음 페이지 존재 여부
    private let useCase: YouTubeUseCase

    // MARK: - 퍼블릭 API
    // Inject use-case for DI and testability.
    init(useCase: YouTubeUseCase = YouTubeUseCase(repository: YouTubeRepositoryImpl())) {
        self.useCase = useCase
    }

    /// 화면 최초 진입 시 한번만 호출
    func loadIfNeeded() {
        guard youtubeList.isEmpty, !isLoading else { return }
        Task { await loadInitial() }
    }
    
    /// 당겨서 새로고침/버튼 새로고침 대응 (완전 리셋)
    func refresh() {
        guard !isRefreshing else { return }
        Task { await refreshInternal() }
    }
    
    /// 무한 스크롤 트리거 (마지막 셀 노출 시 호출)
    func loadMoreIfNeeded(currentItem item: YouTubeVideo?) {
        guard hasMore, !isLoading else { return }
        guard let item, let last = youtubeList.last, item.id == last.id else { return }
        Task { await loadNextPage() }
    }
    
    // MARK: - 내부 로딩 구현
    private func loadInitial() async {
        await setLoading(true)
        defer { Task { await setLoading(false) } }
        
        do {
            let result = try await requestYoutubeList(pageToken: nil)
            await MainActor.run {
                self.youtubeList = result.videos
                self.nextPageToken = result.nextPageToken
                self.hasMore = (result.nextPageToken != nil)
                self.lastSyncedAt = Date()
            }
        } catch {
            AppLogger.error("\(#function) \(error.localizedDescription)", category: .youtube)
        }
    }
    
    private func refreshInternal() async {
        await setRefreshing(true)
        defer { Task { await setRefreshing(false) } }
        
        do {
            let result = try await requestYoutubeList(pageToken: nil)
            await MainActor.run {
                self.youtubeList = result.videos
                self.nextPageToken = result.nextPageToken
                self.hasMore = (result.nextPageToken != nil)
                self.lastSyncedAt = Date()
            }
        } catch {
            AppLogger.error("\(#function) \(error.localizedDescription)", category: .youtube)
        }
    }
    
    private func loadNextPage() async {
        await setLoading(true)
        defer { Task { await setLoading(false) } }
        
        do {
            let result = try await requestYoutubeList(pageToken: nextPageToken)
            await MainActor.run {
                self.youtubeList.append(contentsOf: result.videos)
                self.nextPageToken = result.nextPageToken
                self.hasMore = (result.nextPageToken != nil)
                self.lastSyncedAt = Date()
            }
        } catch {
            AppLogger.error("\(#function) \(error.localizedDescription)", category: .youtube)
        }
    }
    
    // MARK: - 네트워킹 (단일 책임: DTO 디코드 -> 도메인 매핑)
    /// YouTube Search API 호출 -> DTO 디코드 -> 도메인 매핑
    /// - Parameter pageToken: 다음 페이지 토큰(없으면 최초 페이지)
    /// - Returns: (도메인 모델 매핑, 다음 페이지 토큰)
    private func requestYoutubeList(pageToken: String?) async throws -> (videos: [YouTubeVideo], nextPageToken: String?) {
        // Use-case handles DTO -> Domain mapping.
        try await useCase.fetchVideoPage(pageToken: pageToken)
    }
    
    func requestChannelInfo() async throws {
        // Use-case returns the parsed thumbnail URL.
        let url = try await useCase.fetchChannelThumbnailURL()
        await MainActor.run {
            self.channelThumnailURL = url
        }
    }
    
    // MARK: - MainActor 상태 변경 헬퍼
    @MainActor private func setLoading(_ flag: Bool) { isLoading = flag }
    @MainActor private func setRefreshing(_ flag: Bool) { isRefreshing = flag }
}
