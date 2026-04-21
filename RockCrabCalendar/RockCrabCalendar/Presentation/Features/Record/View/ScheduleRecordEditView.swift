//
//  ScheduleRecordEditView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 4/21/26.
//

import RockCrabShared
import SwiftUI

struct ScheduleRecordEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScheduleRecordEditViewModel
    @State private var isShowingEmojiPicker = false

    init(viewModel: ScheduleRecordEditViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    linkedScheduleSection
                    recordInputSection
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
                        dismiss()
                    }
                }
                .fontWeight(.semibold)
                .disabled(viewModel.form.canSave == false)
            }
        }
        .alert("저장 실패", isPresented: errorBinding) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $isShowingEmojiPicker) {
            emojiPickerSheet
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
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
    private var recordInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("기록")
                .font(.headline)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        isShowingEmojiPicker = true
                    } label: {
                        Text(verbatim: viewModel.form.normalizedEmoji)
                            .font(.system(size: 28))
                            .frame(width: 58, height: 52)
                            .background(Color.appBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    TextField("기록 제목", text: $viewModel.form.title)
                        .font(.headline)
                        .textInputAutocapitalization(.never)
                }

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

            Text("사진 추가는 다음 단계에서 연결합니다.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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

    private static let scheduleDateFormatter: DateFormatter = {
        let formatter = AppDateFormatterFactory.recordDetailDateFormatter()
        return formatter
    }()

    private static let selectableEmojis = [
        "🦀", "😀", "🥰", "😭", "🤩",
        "❤️", "🍀", "🔥", "✨", "🎉"
    ]
}
