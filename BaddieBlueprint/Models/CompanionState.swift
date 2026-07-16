//
//  CompanionState.swift
//  Baddie Blueprint
//

import Foundation
import SwiftData

@Model
final class CompanionState {
    static let wellKnownID = "companion.singleton"

    @Attribute(.unique) var id: String
    var currentMood: CompanionMood
    var streakDays: Int
    var lastEvaluatedDay: Date?

    init(id: String = CompanionState.wellKnownID) {
        self.id = id
        self.currentMood = .coasting
        self.streakDays = 0
    }

    var spriteAssetName: String {
        currentMood.spriteAssetName
    }

    /// Re-derives mood from today's completion rate and bumps the streak once per new day.
    func refreshMood(from dailyLog: DailyLog) {
        let rate = dailyLog.completionRate

        switch rate {
        case 0.85...: currentMood = .thriving
        case 0.5..<0.85: currentMood = .coasting
        case 0.01..<0.5: currentMood = .sluggish
        default: currentMood = .neglected
        }

        let isNewDay = lastEvaluatedDay.map { !Calendar.current.isDate($0, inSameDayAs: dailyLog.day) } ?? true
        if isNewDay {
            streakDays = rate >= 0.85 ? streakDays + 1 : 0
            lastEvaluatedDay = dailyLog.day
        }
    }
}
