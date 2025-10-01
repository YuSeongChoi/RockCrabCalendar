//
//  ScheduleEditView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import SwiftUI

struct ScheduleEditView: View {
    enum Kind {
        case qwer
        case user
    }
    
    enum Mode: Equatable {
        case create(Kind)
        case editQWER(QWERScheduleItem)
        case editUser(UserScheduleItem)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Inputs
    let mode: Mode
    let defaultDate: Date

    private var kind: Kind {
        switch mode {
        case .create(let k): return k
        case .editQWER: return .qwer
        case .editUser: return .user
        }
    }

    // MARK: - Common States
    @State private var title: String = ""
    @State private var date: Date
    @State private var time: String = ""
    @State private var place: String = ""

    private let originalQWER: QWERScheduleItem?
    private let originalUser: UserScheduleItem?

    // MARK: - QWER States
    @State private var selectedMembers: Set<QWERMember> = []
    @State private var category: ScheduleCategory = .other

    // MARK: - User States
    @State private var isRepeat: Bool = false
    @State private var repeatType: UserScheduleItem.RepeatType = .none
    @State private var repeatEndDate: Date = Date()
    
    // Deletion alert state
    @State private var showNonDeletableAlert: Bool = false

    // MARK: - Init
    init(kind: Kind, defaultDate: Date = Date()) {
        self.init(mode: .create(kind), defaultDate: defaultDate)
    }
    
    init(mode: Mode, defaultDate: Date = Date()) {
        self.mode = mode
        self.defaultDate = defaultDate
        switch mode {
        case .create:
            _date = State(initialValue: defaultDate)
            self.originalQWER = nil
            self.originalUser = nil
        case .editQWER(let item):
            _title = State(initialValue: item.title)
            _date = State(initialValue: item.date)
            _time = State(initialValue: item.time)
            _place = State(initialValue: item.place)
            _selectedMembers = State(initialValue: Set(item.members))
            _category = State(initialValue: item.category)
            self.originalQWER = item
            self.originalUser = nil
        case .editUser(let item):
            _title = State(initialValue: item.title)
            _date = State(initialValue: item.date)
            _time = State(initialValue: item.time)
            _place = State(initialValue: item.place)
            _isRepeat = State(initialValue: item.isRepeat)
            _repeatType = State(initialValue: item.repeatType ?? .none)
            _repeatEndDate = State(initialValue: item.repeatEndDate ?? defaultDate)
            self.originalQWER = nil
            self.originalUser = item
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("제목", text: $title)
                    DatePicker("날짜", selection: $date, displayedComponents: .date)
                    TextField("시간 (예: 18:30)", text: $time)
                    TextField("장소", text: $place)
                }

                switch kind {
                case .qwer:
                    if case .editQWER = mode, !isEditingQWERLocal {
                        Section {
                            Label {
                                Text("이 일정은 Firestore에 등록된 항목이라 앱에서 삭제할 수 없습니다.\n사용자가 직접 추가한 QWER 일정만 삭제 가능합니다.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    Section("분류") {
                        Picker("카테고리", selection: $category) {
                            ForEach(ScheduleCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                    }

                    Section("멤버") {
                        ForEach(QWERMember.allCases, id: \.self) { member in
                            Toggle(isOn: Binding(
                                get: { selectedMembers.contains(member) },
                                set: { newValue in
                                    if newValue { selectedMembers.insert(member) }
                                    else { selectedMembers.remove(member) }
                                }
                            )) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(member.color)
                                        .frame(width: 10, height: 10)
                                    Text(member.name)
                                }
                            }
                            .tint(member.color)
                        }
                    }

                case .user:
                    Section("반복") {
                        Toggle("반복", isOn: $isRepeat)
                            .onChange(of: isRepeat) { _, newValue in
                                if newValue && repeatType == .none {
                                    repeatType = .week
                                }
                            }

                        if isRepeat {
                            Picker("반복 종류", selection: $repeatType) {
                                ForEach(UserScheduleItem.RepeatType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            DatePicker("반복 종료", selection: $repeatEndDate, displayedComponents: .date)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .listRowBackground(
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
                })
            )
            .background(
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark ? .black : .systemGroupedBackground
                })
            )
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        Text("저장")
                            .bold()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if case .editQWER = mode {
                        Button(role: .destructive) {
                            if isEditingQWERLocal {
                                deleteItem()
                            } else {
                                showNonDeletableAlert = true
                            }
                        } label: { Text("삭제") }
                    } else if case .editUser = mode {
                        Button(role: .destructive) { deleteItem() } label: { Text("삭제") }
                    }
                }
            }
            .toolbarBackground(
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark ? .black : .white
                }), for: .navigationBar
            )
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("삭제할 수 없습니다", isPresented: $showNonDeletableAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("Firestore에 올라간 QWER 일정은 삭제할 수 없습니다.\n사용자가 직접 추가한 QWER 일정만 삭제할 수 있어요.")
            }
        }
        .environment(\.locale, Locale(identifier: "ko_KR"))
    }
    
    private var titleText: String {
        switch mode {
        case .create(let k):
            return k == .qwer ? "QWER 일정 추가" : "개인 일정 추가"
        case .editQWER:
            return "QWER 일정 편집"
        case .editUser:
            return "개인 일정 편집"
        }
    }
    
    private var isEditingQWERLocal: Bool {
        guard case .editQWER(let item) = mode else { return false }
        let service = QWERScheduleService()
        return service.isLocalSchedule(item)
    }
}

// MARK: - Save
private extension ScheduleEditView {
    func save() {
        switch mode {
        case .create(let k):
            switch k {
            case .qwer:
                let item = QWERScheduleItem(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    date: date,
                    time: time.trimmingCharacters(in: .whitespacesAndNewlines),
                    place: place.trimmingCharacters(in: .whitespacesAndNewlines),
                    members: Array(selectedMembers).sorted { $0.rawValue < $1.rawValue },
                    category: category
                )
                let service = QWERScheduleService()
                service.saveLocalSchedule(item)
            case .user:
                let item = UserScheduleItem(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    date: date,
                    time: time.trimmingCharacters(in: .whitespacesAndNewlines),
                    place: place.trimmingCharacters(in: .whitespacesAndNewlines),
                    isRepeat: isRepeat,
                    repeatType: isRepeat ? repeatType : nil,
                    repeatEndDate: isRepeat ? repeatEndDate : nil
                )
                let service = UserScheduleService()
                service.saveSchedule(item)
            }
        case .editQWER(let original):
            let updated = QWERScheduleItem(
                id: original.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                time: time.trimmingCharacters(in: .whitespacesAndNewlines),
                place: place.trimmingCharacters(in: .whitespacesAndNewlines),
                members: Array(selectedMembers).sorted { $0.rawValue < $1.rawValue },
                category: category
            )
            let service = QWERScheduleService()
            service.updateLocalSchedule(updated)
        case .editUser(let original):
            let updated = UserScheduleItem(
                id: original.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                time: time.trimmingCharacters(in: .whitespacesAndNewlines),
                place: place.trimmingCharacters(in: .whitespacesAndNewlines),
                isRepeat: isRepeat,
                repeatType: isRepeat ? repeatType : nil,
                repeatEndDate: isRepeat ? repeatEndDate : nil
            )
            let service = UserScheduleService()
            service.updateSchedule(updated)
        }

        switch mode {
        case .create(let k):
            switch k {
            case .qwer:
                NotificationCenter.default.post(name: .qwerLocalDidChange, object: nil)
            case .user:
                NotificationCenter.default.post(name: .userSchedulesDidChange, object: nil)
            }
        case .editQWER:
            NotificationCenter.default.post(name: .qwerLocalDidChange, object: nil)
        case .editUser:
            NotificationCenter.default.post(name: .userSchedulesDidChange, object: nil)
        }
        
        dismiss()
    }
    
    func deleteItem() {
        switch mode {
        case .editQWER(let original):
            let service = QWERScheduleService()
            service.deleteLocalSchedule(original)
        case .editUser(let original):
            let service = UserScheduleService()
            service.deleteSchedule(original)
        case .create:
            break
        }
        // Notify listeners to refresh (granular)
        switch mode {
        case .editQWER:
            NotificationCenter.default.post(name: .qwerLocalDidChange, object: nil)
        case .editUser:
            NotificationCenter.default.post(name: .userSchedulesDidChange, object: nil)
        case .create:
            break
        }
        dismiss()
    }
}

extension ScheduleEditView.Mode: Identifiable {
    var id: String {
        switch self {
        case .create(let k): return "create_\(k == .qwer ? "qwer" : "user")"
        case .editQWER(let item): return "qwer_\(item.id.uuidString)"
        case .editUser(let item): return "user_\(item.id.uuidString)"
        }
    }
}

extension ScheduleEditView.Mode: Hashable {
    static func == (lhs: ScheduleEditView.Mode, rhs: ScheduleEditView.Mode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
