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
    let qwerVM: QWERScheduleViewModel
    let userVM: UserScheduleViewModel

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
    @State private var isAllDay: Bool = true
    @State private var startTime: Date? = nil
    @State private var endTime: Date? = nil
    @State private var shouldNotify: Bool = false

    private let originalQWER: QWERScheduleItem?
    private let originalUser: UserScheduleItem?

    // MARK: - QWER States
    @State private var selectedMembers: Set<QWERMember> = []
    @State private var category: ScheduleCategory = .other

    // MARK: - User States
    @State private var isRepeat: Bool = false
    @State private var repeatType: UserScheduleItem.RepeatType = .none
    @State private var repeatEndDate: Date = Date()
    @State private var selectedColor: Color = .purple
    
    // Deletion alert state
    @State private var showNonDeletableAlert: Bool = false
    @State private var isQWERLocalSchedule: Bool = false

    // MARK: - Init
    init(
        kind: Kind,
        defaultDate: Date = Date(),
        qwerVM: QWERScheduleViewModel,
        userVM: UserScheduleViewModel,
        defaultColor: Color = .purple
    ) {
        self.init(mode: .create(kind), defaultDate: defaultDate, qwerVM: qwerVM, userVM: userVM)
        if kind == .user {
            _selectedColor = State(initialValue: defaultColor)
        }
    }
    
    init(
        mode: Mode,
        defaultDate: Date = Date(),
        qwerVM: QWERScheduleViewModel,
        userVM: UserScheduleViewModel,
        defaultColor: Color = .purple
    ) {
        self.mode = mode
        self.defaultDate = defaultDate
        self.qwerVM = qwerVM
        self.userVM = userVM
        
        switch mode {
        case .create:
            _date = State(initialValue: defaultDate)
            self.originalQWER = nil
            self.originalUser = nil
            _isAllDay = State(initialValue: true)
            _startTime = State(initialValue: nil)
            _endTime = State(initialValue: nil)
            _shouldNotify = State(initialValue: false)
            
        case .editQWER(let item):
            _title = State(initialValue: item.title)
            _date = State(initialValue: item.date)
            _time = State(initialValue: item.time)
            _place = State(initialValue: item.place)
            _selectedMembers = State(initialValue: Set(item.members))
            _category = State(initialValue: item.category)
            _isAllDay = State(initialValue: item.isAllDay)
            _startTime = State(initialValue: item.startTime)
            _endTime = State(initialValue: item.endTime)
            _shouldNotify = State(initialValue: item.shouldNotify)
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
            _selectedColor = State(initialValue: Color(hex: item.colorHex))
            _isAllDay = State(initialValue: item.isAllDay)
            _startTime = State(initialValue: item.startTime)
            _endTime = State(initialValue: item.endTime)
            _shouldNotify = State(initialValue: item.shouldNotify)
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
                    Toggle("하루종일", isOn: $isAllDay)

                    if !isAllDay {
                        DatePicker(
                            "시작 시간",
                            selection: Binding(
                                get: { startTime ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date)! },
                                set: { startTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )

                        DatePicker(
                            "종료 시간",
                            selection: Binding(
                                get: { endTime ?? Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: date)! },
                                set: { endTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        
                        Toggle("시작 전에 알림 받기", isOn: $shouldNotify)
                    }
                    
                    TextField("장소", text: $place)
                }
                .onChange(of: isAllDay) { _, newValue in
                    if newValue {
                        startTime = nil
                        endTime = nil
                    } else {
                        startTime = startTime ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date)!
                        endTime = endTime ?? Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: date)!
                    }
                }

                switch kind {
                case .qwer:
                    if case .editQWER = mode, !isQWERLocalSchedule {
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
                                        .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                                        .background(Circle().fill(member.color))
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
                    Section("색상") {
                        ColorPicker("색상 선택", selection: $selectedColor, supportsOpacity: false)
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
                            if isQWERLocalSchedule {
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
        .task {
            await refreshLocalFlagIfNeeded()
        }
        .onAppear {
            AnalyticsHelper.logEvent(eventName: "schedule_edit_screen", parameters: ["label":"일정수정화면"])
        }
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
    
    private func refreshLocalFlagIfNeeded() async {
        guard case .editQWER(let item) = mode else {
            isQWERLocalSchedule = false
            return
        }
        let service = QWERScheduleService()
        isQWERLocalSchedule = await service.isLocalSchedule(item)
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
                    isAllDay: isAllDay,
                    startTime: isAllDay ? nil : startTime,
                    endTime: isAllDay ? nil : endTime,
                    place: place.trimmingCharacters(in: .whitespacesAndNewlines),
                    shouldNotify: shouldNotify,
                    members: Array(selectedMembers).sorted { $0.rawValue < $1.rawValue },
                    category: category
                )
                qwerVM.addLocal(item)
                if item.shouldNotify {
                    NotificationManager.shared.schedule(for: item)
                }
            case .user:
                let item = UserScheduleItem(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    date: date,
                    time: time.trimmingCharacters(in: .whitespacesAndNewlines),
                    isAllDay: isAllDay,
                    startTime: isAllDay ? nil : startTime,
                    endTime: isAllDay ? nil : endTime,
                    place: place.trimmingCharacters(in: .whitespacesAndNewlines),
                    shouldNotify: shouldNotify,
                    isRepeat: isRepeat,
                    repeatType: isRepeat ? repeatType : nil,
                    repeatEndDate: isRepeat ? repeatEndDate : nil,
                    colorHex: selectedColor.toHexString()
                )
                userVM.add(item)
                if item.shouldNotify {
                    NotificationManager.shared.schedule(for: item)
                }
            }
        case .editQWER(let original):
            let updated = QWERScheduleItem(
                id: original.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                time: time.trimmingCharacters(in: .whitespacesAndNewlines),
                isAllDay: isAllDay,
                startTime: isAllDay ? nil : startTime,
                endTime: isAllDay ? nil : endTime,
                place: place.trimmingCharacters(in: .whitespacesAndNewlines),
                shouldNotify: shouldNotify,
                members: Array(selectedMembers).sorted { $0.rawValue < $1.rawValue },
                category: category
            )
            qwerVM.updateLocal(updated)
            if updated.shouldNotify {
                NotificationManager.shared.schedule(for: updated)
            } else {
                NotificationManager.shared.cancel(for: updated)
            }
        case .editUser(let original):
            let updated = UserScheduleItem(
                id: original.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                time: time.trimmingCharacters(in: .whitespacesAndNewlines),
                isAllDay: isAllDay,
                startTime: isAllDay ? nil : startTime,
                endTime: isAllDay ? nil : endTime,
                place: place.trimmingCharacters(in: .whitespacesAndNewlines),
                shouldNotify: shouldNotify,
                isRepeat: isRepeat,
                repeatType: isRepeat ? repeatType : nil,
                repeatEndDate: isRepeat ? repeatEndDate : nil,
                colorHex: selectedColor.toHexString()
            )
            userVM.update(updated)
            if updated.shouldNotify {
                NotificationManager.shared.schedule(for: updated)
            } else {
                NotificationManager.shared.cancel(for: updated)
            }
        }

        dismiss()
    }
    
    func deleteItem() {
        switch mode {
        case .editQWER(let original):
            NotificationManager.shared.cancel(for: original)
            qwerVM.deleteLocal(original)
        case .editUser(let original):
            NotificationManager.shared.cancel(for: original)
            userVM.delete(original)
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


// MARK: - Color <-> Hex Extension
import UIKit
extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    func toHexString() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X",
                      Int(red * 255),
                      Int(green * 255),
                      Int(blue * 255))
    }
}
