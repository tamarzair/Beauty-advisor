//
//  DailyLog.swift
//  Baddie Blueprint
//

import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var day: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineTask.dailyLog)
    var requiredTasks: [RoutineTask] = []

    init(day: Date) {
        self.day = day
    }

    var completionRate: Double {
        guard !requiredTasks.isEmpty else { return 0 }
        let completed = requiredTasks.filter(\.isCompleted).count
        return Double(completed) / Double(requiredTasks.count)
    }

    /// Populates a fresh log with the standard morning/evening routine, adding a gym task when scheduled.
    static func seedTasks(into log: DailyLog, gymDayToday: Bool) {
        var order = 0
        func add(_ title: String, _ cycle: RoutineCycle) {
            log.requiredTasks.append(RoutineTask(title: title, cycle: cycle, sortOrder: order))
            order += 1
        }

        add("Cleanse", .morning)
        add("Moisturize", .morning)
        add("SPF", .morning)
        if gymDayToday {
            add("Gym", .morning)
        }
        add("Cleanse", .evening)
        add("Treatment", .evening)
        add("Moisturize", .evening)
    }
}
