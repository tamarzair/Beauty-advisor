import Foundation
import SwiftData

@Model
final class RoutineTask {
    var id: UUID
    var name: String
    var isCompleted: Bool
    var category: String // "morning", "afternoon", "night"

    init(id: UUID = UUID(), name: String, category: String, isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.isCompleted = isCompleted
    }
}

@Model
final class DailyLog {
    var day: Date // Normalized to midnight
    @Relationship(deleteRule: .cascade) var requiredTasks: [RoutineTask]
    var caloriesConsumed: Int
    var sleepScore: Double

    init(day: Date = Date(), requiredTasks: [RoutineTask] = [], caloriesConsumed: Int = 0, sleepScore: Double = 0.0) {
        // Normalize day to midnight for accurate daily grouping
        self.day = Calendar.current.startOfDay(for: day)
        self.requiredTasks = requiredTasks
        self.caloriesConsumed = caloriesConsumed
        self.sleepScore = sleepScore
    }
}

// Global Manager for Safe Seeding and Retrieval
struct SharedPersistence {
    static func todayLog(in context: ModelContext) -> DailyLog {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { $0.day == today }
        )

        if let existingLog = try? context.fetch(descriptor).first {
            return existingLog
        } else {
            // Seed default daily baddie tasks
            let defaultTasks = [
                RoutineTask(name: "Brush Teeth & Hair", category: "morning"),
                RoutineTask(name: "Morning Skincare", category: "morning"),
                RoutineTask(name: "Full Makeup / Snatched Check", category: "morning"),
                RoutineTask(name: "Hydration Check-in", category: "afternoon"),
                RoutineTask(name: "Log Meals & Calorie Target", category: "afternoon"),
                RoutineTask(name: "Gym Workout / 5-Min Cardio", category: "night"),
                RoutineTask(name: "Nightly Skincare & Retinol", category: "night")
            ]

            let newLog = DailyLog(day: today, requiredTasks: defaultTasks)
            context.insert(newLog)
            try? context.save()
            return newLog
        }
    }
}
