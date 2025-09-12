//
//  YouTubeListView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/9/25.
//

import SwiftUI

struct YouTubeListView: View {
    @State private var viewModel = YouTubeListViewModel()
    
    // 표시용 날짜 포매터
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()
    
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
                            YouTubeVideoRow(video: video, dateFormatter: dateFormatter)
                                .padding(.horizontal)
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
        .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle("QWER 영상")
        .refreshable {
            viewModel.refresh()
        }
        .task {
            viewModel.loadIfNeeded() // 최초 진입 (캐시→백그라운드 최신화)
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

struct YouTubeVideoRow: View {
    let video: YouTubeVideo
    let dateFormatter: DateFormatter
    
    var body: some View {
        let thumbWidth = UIScreen.main.bounds.width * 0.25 // TODO: 필요 시 GeometryReader로 셀 가용 폭의 1/4로 개선
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: video.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable() // 스케일은 아래 aspectRatio에서 처리
                case .failure:
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .overlay(Image(systemName: "video.slash").foregroundStyle(.secondary))
                case .empty:
                    Rectangle()
                        .fill(.gray.opacity(0.15))
                        .overlay(ProgressView().scaleEffect(0.8))
                @unknown default:
                    Rectangle().fill(.gray.opacity(0.15))
                }
            }
            .aspectRatio(16.0/9.0, contentMode: .fill) // 16:9 비율 고정
            .frame(width: thumbWidth)                  // 화면 너비의 1/4로 고정
            .clipped()                                 // 넘치는 영역 잘라내기
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .pretendBold(size: 16)
                    .lineLimit(2)
                
                if let date = video.publishedAt {
                    Text(dateFormatter.string(from: date))
                        .pretendReg(size: 14)
                        .foregroundStyle(.secondary)
                }
                
                if !video.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(video.description)
                        .pretendReg(size: 11)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle()) // 터치 영역 넓게
    }
}
