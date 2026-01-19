//
//  YouTubeListView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/9/25.
//

import SwiftUI
import RockCrabDomain
import RockCrabShared

struct YouTubeListView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var viewModel: YouTubeListViewModel
    
    // 표시용 날짜 포매터
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()

    // Inject environment for DI.
    init(environment: AppEnvironment = .live()) {
        _viewModel = State(initialValue: YouTubeListViewModel(useCase: environment.youTubeUseCase))
    }
    
    var body: some View {
        ZStack { // 전체 배경을 안전영역까지 깔아 하얀 플래시 방지
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            ScrollView {
                if viewModel.isLoading && viewModel.youtubeList.isEmpty {
                    // 첫 로딩 (스크롤뷰 안에서도 중앙 정렬)
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("불러오는 중...")
                            .pretendReg(size: 18)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else if viewModel.youtubeList.isEmpty {
                    // 비어있는 상태도 refresh 가능하도록 ScrollView 내부에 유지
                    VStack(spacing: 12) {
                        Image(systemName: "video")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("표시할 영상이 없어요!")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    LazyVStack(spacing: 12) {
                        if let synced = viewModel.lastSyncedAt {
                            HStack {
                                Text("동기화 : \(dateFormatter.string(from: synced))")
                                    .pretendReg(size: 14)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                Spacer()
                            }
                        }

                        ForEach(viewModel.youtubeList, id: \.self) { video in
                            YouTubeVideoCard(
                                video: video,
                                dateFormatter: dateFormatter,
                                channelThumbnailURL: viewModel.channelThumnailURL
                            )
                        }

                        // 페이징 센티넬: 리스트의 맨 아래 도달 시 한 번만 트리거
                        Group {
                            if viewModel.isLoading && !viewModel.youtubeList.isEmpty {
                                ProgressView().padding(.vertical)
                            } else {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        viewModel.loadMoreIfNeeded()
                                    }
                            }
                        }
                    }
                }
            }
        }
        .toolbarBackground(
            scheme == .dark
            ? Color.black.opacity(0.9)
            : Color.white, // 필요하면 시스템 색도 가능: Color(.systemBackground)
            for: .navigationBar
        )
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(scheme == .dark ? .dark : .light, for: .navigationBar)
        .navigationTitle("QWER 영상")
        .toolbarRole(.editor)
        .refreshable {
            viewModel.refresh()
        }
        .task {
            viewModel.loadIfNeeded() // 최초 진입 (캐시→백그라운드 최신화)
            do {
                try await viewModel.requestChannelInfo()
            } catch {
                AppLogger.error("YouTubeListView channel info error: \(error.localizedDescription)", category: .youtube)
            }
        }
    }
}

// 리스트 하단 센티넬에서 호출할 간단 wrapper
extension YouTubeListViewModel {
    /// 리스트 하단 센티넬에서 사용할 간단 호출. 내부에서 nextPageToken/isPaging 가드가 있어야 함.
    @MainActor
    func loadMoreIfNeeded() {
        if let last = youtubeList.last { loadMoreIfNeeded(currentItem: last) }
    }
}

struct YouTubeVideoCard: View {
    let video: YouTubeVideo
    let dateFormatter: DateFormatter
    var channelThumbnailURL: URL? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 1) 큰 썸네일 (16:9, 가로 꽉차게)
            AsyncImage(url: video.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()                     // 가로폭을 꽉 채우고 필요시 크롭
                        .frame(maxWidth: .infinity)
//                        .scaledToFill()
//                        .aspectRatio(16/9, contentMode: .fill)
//                        .clipped()                          // 넘치는 영역 잘라내기
//                        .transition(.opacity.combined(with: .scale))
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            Image(systemName: "photo")
                                .imageScale(.large)
                                .foregroundStyle(.secondary)
                        )
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.12))
                        .overlay(ProgressView())
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                @unknown default:
                    Rectangle().fill(Color.black)
                        .aspectRatio(16/9, contentMode: .fit)
                }
            }
            .frame(maxWidth: .infinity)
            
            // 2) 채널 아바타 + 제목/베타 정보
            HStack(alignment: .top, spacing: 12) {
                ChannelAvatar(title: video.channelTitle, url: channelThumbnailURL)
                    .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(video.title)
                        .pretendBold(size: 16)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Text(video.channelTitle)
                        if let date = video.publishedAt {
                            Text("• \(dateFormatter.string(from: date))")
                        }
                    }
                    .pretendReg(size: 13)
                    .foregroundStyle(.secondary)
                    
                    if !video.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(video.description)
                            .pretendReg(size: 12)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .contentShape(Rectangle()) // 터치 영역 넓게
    }
}

/// 채널 아바타: URL 있으면 로드, 없으면 이니셜 플레이스홀더
private struct ChannelAvatar: View {
    let title: String
    let url: URL?
    
    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack {
                            Circle().fill(.gray.opacity(0.12))
                            ProgressView().scaleEffect(0.7)
                        }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
    
    private var placeholder: some View {
        ZStack {
            Circle().fill(.gray.opacity(0.15))
            Text(initials(from: title))
                .pretendBold(size: 12)
                .foregroundStyle(.secondary)
        }
    }
    
    private func initials(from title: String) -> String {
        let comps = title.split(separator: " ")
        let first = comps.first?.prefix(1) ?? "?"
        let second = comps.dropFirst().first?.prefix(1) ?? ""
        return String(first + second)
    }
}
