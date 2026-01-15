//
//  ScheduleEditView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import SwiftUI
import RockCrabDomain

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
                ScheduleEditBasicInfoSection(
                    title: $title,
                    date: $date,
                    isAllDay: $isAllDay,
                    startTime: $startTime,
                    endTime: $endTime,
                    shouldNotify: $shouldNotify,
                    place: $place,
                    defaultStartTime: defaultStartTime,
                    defaultEndTime: defaultEndTime
                )
                if kind == .qwer {
                    ScheduleEditQWERSection(
                        mode: mode,
                        isLocalOnly: isQWERLocalSchedule,
                        category: $category,
                        selectedMembers: $selectedMembers,
                        memberColor: qwerVM.memberColor
                    )
                } else {
                    ScheduleEditUserSection(
                        isRepeat: $isRepeat,
                        repeatType: $repeatType,
                        repeatEndDate: $repeatEndDate,
                        selectedColor: $selectedColor
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .listRowBackground(listRowBackgroundColor)
            .background(listBackgroundColor)
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
    
    // Query ViewModel to determine if the QWER item is local-only.
    private func refreshLocalFlagIfNeeded() async {
        guard case .editQWER(let item) = mode else {
            isQWERLocalSchedule = false
            return
        }
        isQWERLocalSchedule = await qwerVM.isLocalSchedule(item)
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

// MARK: - Sections
private extension ScheduleEditView {
    var listRowBackgroundColor: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
        })
    }

    var listBackgroundColor: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .systemGroupedBackground
        })
    }

    func defaultStartTime() -> Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
    }

    func defaultEndTime() -> Date {
        Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: date) ?? date
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
