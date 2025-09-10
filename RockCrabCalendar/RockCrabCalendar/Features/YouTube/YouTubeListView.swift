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
        Group {
            if viewModel.isLoading && viewModel.youtubeList.isEmpty {
                // 첫 로딩 풀스크린
                VStack(spacing: 12) {
                    ProgressView()
                    Text("불러오는 중...")
                        .pretendReg(size: 18)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } 
        }
        .task {
            viewModel.loadIfNeeded() // 최초진입
        }
        .refreshable {
            viewModel.refresh()      // 당겨서 새로고침
        }
    }
}

struct YouTubeVideoRow: View {
    let video: YouTubeVideo
    let dateFormatter: DateFormatter
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: video.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    Rectangle().fill(.gray.opacity(0.2))
                        .overlay(Image(systemName: "video.slash").foregroundStyle(.secondary))
                case .empty:
                    Rectangle().fill(.gray.opacity(0.15))
                        .overlay(ProgressView().scaleEffect(0.8))
                @unknown default:
                    Rectangle().fill(.gray.opacity(0.15))
                }
            }
            .frame(width: 120, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .pretendBold(size: 22)
                    .lineLimit(2)
                
                if let date = video.publishedAt {
                    Text(dateFormatter.string(from: date))
                        .pretendReg(size: 14)
                        .foregroundStyle(.secondary)
                }
                
                if !video.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(video.description)
                        .pretendReg(size: 14)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .contentShape(Rectangle()) // 터치 영역 넓게
    }
}
