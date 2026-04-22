//
//  ScheduleRecordEditView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 4/21/26.
//

import SwiftUI
import PhotosUI
import RockCrabShared
import RockCrabDomain

struct ScheduleRecordEditView: View {
    @Environment(\.dismiss) private var dismiss
    private let onRecordChanged: () -> Void
    @State private var viewModel: ScheduleRecordEditViewModel
    @State private var isShowingEmojiPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var previewPhoto: RecordPhotoPreview?
    @State private var isShowingDeleteConfirm = false

    private var scheduleDateText: String {
        Self.scheduleDateFormatter.string(from: viewModel.target.date)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    private var maxSelectablePhotoCount: Int {
        max(0, ScheduleRecord.maxPhotoCount - viewModel.photos.count)
    }

    init(
        viewModel: ScheduleRecordEditViewModel,
        onRecordChanged: @escaping () -> Void = {}
    ) {
        self.onRecordChanged = onRecordChanged
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    linkedScheduleSection
                    emotionSection
                    recordInputSection
                    photosSection
                    deleteSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.textColor)
        .navigationTitle(viewModel.isEditing ? "기록 수정" : "기록 남기기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("저장") {
                    if viewModel.save() {
                        onRecordChanged()
                        dismiss()
                    }
                }
                .fontWeight(.semibold)
                .disabled(viewModel.canSave == false)
            }
        }
        .alert(viewModel.errorTitle, isPresented: errorBinding) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("기록을 삭제할까요?", isPresented: $isShowingDeleteConfirm) {
            Button("삭제", role: .destructive) {
                if viewModel.deleteRecord() {
                    onRecordChanged()
                    dismiss()
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("삭제한 기록과 첨부 사진은 복구할 수 없습니다.")
        }
        .sheet(isPresented: $isShowingEmojiPicker) {
            emojiPickerSheet
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $previewPhoto) { preview in
            photoPreview(preview)
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                await handleSelectedPhotoItems(newItems)
            }
        }
        .onDisappear {
            guard previewPhoto == nil, isShowingEmojiPicker == false else { return }
            viewModel.discardUnsavedPhotoFiles()
        }
    }

    @ViewBuilder
    private var linkedScheduleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("연결된 일정")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.target.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text(scheduleDateText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private var emotionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("감정")
                .font(.headline)

            Button {
                isShowingEmojiPicker = true
            } label: {
                HStack(spacing: 10) {
                    Text(verbatim: viewModel.form.normalizedEmoji)
                        .font(.system(size: 28))
                        .frame(width: 52, height: 52)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("탭해서 이모지를 선택하세요.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textColor)

                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var recordInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("기록")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                TextField(
                    "일정은 어땠나요?",
                    text: $viewModel.form.body,
                    axis: .vertical
                )
                .lineLimit(6, reservesSpace: true)
                .textInputAutocapitalization(.never)
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("사진")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.photos.count)/\(ScheduleRecord.maxPhotoCount)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if viewModel.photos.isEmpty {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: maxSelectablePhotoCount,
                    matching: .images
                ) {
                    emptyPhotoPicker
                }
                .disabled(viewModel.canAddPhoto == false || isLoadingPhotos)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.photos) { photo in
                            photoThumbnail(photo)
                                .transition(.scale(scale: 0.92).combined(with: .opacity))
                        }

                        if viewModel.canAddPhoto {
                            PhotosPicker(
                                selection: $selectedPhotoItems,
                                maxSelectionCount: maxSelectablePhotoCount,
                                matching: .images
                            ) {
                                addPhotoTile
                            }
                            .disabled(isLoadingPhotos)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    @ViewBuilder
    private var deleteSection: some View {
        if viewModel.isEditing {
            Button(role: .destructive) {
                isShowingDeleteConfirm = true
            } label: {
                Text("기록 삭제")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private var emojiPickerSheet: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("감정 선택")
                    .font(.headline)
                    .foregroundStyle(Color.textColor)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5),
                    spacing: 10
                ) {
                    ForEach(Self.selectableEmojis, id: \.self) { emoji in
                        Button {
                            viewModel.form.emoji = emoji
                            isShowingEmojiPicker = false
                        } label: {
                            Text(verbatim: emoji)
                                .font(.system(size: 30))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(emoji == viewModel.form.normalizedEmoji ? Color.cardBackground : Color.appBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.cardBackground, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
    }

    private var emptyPhotoPicker: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appBackground)
                    .frame(width: 58, height: 58)

                if isLoadingPhotos {
                    ProgressView()
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("사진 추가")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textColor)

                Text("최대 5장까지 좌우로 넘겨볼 수 있어요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var addPhotoTile: some View {
        VStack(spacing: 8) {
            if isLoadingPhotos {
                ProgressView()
            } else {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("추가")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: Self.photoTileSize, height: Self.photoTileSize)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    Color.secondary.opacity(0.18),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                )
        )
    }

    private func photoThumbnail(_ photo: ScheduleRecord.Photo) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                openPhotoPreview(photo)
            } label: {
                Group {
                    if let data = viewModel.imageData(for: photo),
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.cardBackground)
                    }
                }
                .frame(width: Self.photoTileSize, height: Self.photoTileSize)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .clipped()
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.snappy(duration: 0.22)) {
                    viewModel.removePhoto(id: photo.id)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .animation(.snappy(duration: 0.22), value: viewModel.photos)
    }

    private func photoPreview(_ preview: RecordPhotoPreview) -> some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            ZoomableImageView(image: preview.image)
                .ignoresSafeArea()

            Button {
                previewPhoto = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.45))
                    .padding(20)
            }
            .buttonStyle(.plain)
        }
    }

    private func openPhotoPreview(_ photo: ScheduleRecord.Photo) {
        guard let data = viewModel.imageData(for: photo),
              let image = UIImage(data: data) else { return }
        previewPhoto = RecordPhotoPreview(id: photo.id, image: image)
    }

    @MainActor
    private func handleSelectedPhotoItems(_ items: [PhotosPickerItem]) async {
        guard items.isEmpty == false else { return }

        isLoadingPhotos = true
        defer {
            isLoadingPhotos = false
            selectedPhotoItems = []
        }

        for item in items.prefix(maxSelectablePhotoCount) {
            if let data = try? await item.loadTransferable(type: Data.self) {
                viewModel.addPhoto(data: data)
            }
        }
    }
}

extension ScheduleRecordEditView {
    private static let scheduleDateFormatter: DateFormatter = {
        let formatter = AppDateFormatterFactory.recordDetailDateFormatter()
        return formatter
    }()

    private static let selectableEmojis = [
        "🦀", "😀", "🥰", "😭", "🤩",
        "❤️", "🍀", "🔥", "✨", "🎉"
    ]

    private static let photoTileSize: CGFloat = 112
}

private struct RecordPhotoPreview: Identifiable {
    let id: UUID
    let image: UIImage
}

private struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.backgroundColor = .black
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }
    }
}
