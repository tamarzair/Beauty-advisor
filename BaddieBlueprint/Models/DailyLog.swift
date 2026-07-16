import Foundation
import SwiftData

@Model
final class DailyLog {
    var day: Date // Normalized to midnight
    @Relationship(deleteRule: .cascade) var requiredTasks: [RoutineTask]
    var caloriesConsumed: Int

    // Sleep Tracker Properties
    var bedtime: Date?
    var wakeTime: Date?
    var snoozeCount: Int
    var napDurationMinutes: Int
    var sleepScore: Double

    init(
        day: Date = Date(),
        requiredTasks: [RoutineTask] = [],
        caloriesConsumed: Int = 0,
        bedtime: Date? = nil,
        wakeTime: Date? = nil,
        snoozeCount: Int = 0,
        napDurationMinutes: Int = 0,
        sleepScore: Double = 0.0
    ) {
        self.day = Calendar.current.startOfDay(for: day)
        self.requiredTasks = requiredTasks
        self.caloriesConsumed = caloriesConsumed
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.snoozeCount = snoozeCount
        self.napDurationMinutes = napDurationMinutes
        self.sleepScore = sleepScore
    }
}
