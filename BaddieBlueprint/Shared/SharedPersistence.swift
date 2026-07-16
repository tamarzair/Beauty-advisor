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
