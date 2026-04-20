//
//  ScheduleSearchMatcher.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/20.
//

import Foundation
import RockCrabDomain

enum ScheduleSearchMatcher {
    static func filter(
        qwerSchedules: [QWERScheduleItem],
        userSchedules: [UserScheduleItem],
        query: String
    ) -> ([QWERScheduleItem], [UserScheduleItem]) {
        let normalizedQuery = query.normalizedSearchQuery
        guard !normalizedQuery.isEmpty else {
            return (qwerSchedules, userSchedules)
        }

        return (
            qwerSchedules.filter { $0.matchesSearchQuery(normalizedQuery) },
            userSchedules.filter { $0.matchesSearchQuery(normalizedQuery) }
        )
    }
}

private extension QWERScheduleItem {
    func matchesSearchQuery(_ query: String) -> Bool {
        let categoryTerms = [category.rawValue, category.displayName]
        let memberTerms = members.flatMap { [$0.rawValue, $0.name] }
        let searchableTerms = [
            title,
            place,
            displayPlace
        ] + categoryTerms + memberTerms

        return searchableTerms.contains(where: { $0.normalizedSearchQuery.contains(query) })
    }
}

private extension UserScheduleItem {
    func matchesSearchQuery(_ query: String) -> Bool {
        let searchableTerms = [
            title,
            place,
            displayPlace
        ]

        return searchableTerms.contains(where: { $0.normalizedSearchQuery.contains(query) })
    }
}

private extension String {
    var normalizedSearchQuery: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
