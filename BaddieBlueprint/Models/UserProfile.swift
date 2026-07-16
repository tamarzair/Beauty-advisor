import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var heightInches: Double
    var bodyType: String
    var skinUndertone: String
    var hairType: String
    var calorieGoal: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        heightInches: Double,
        bodyType: String,
        skinUndertone: String,
        hairType: String,
        calorieGoal: Int
    ) {
        self.id = id
        self.name = name
        self.heightInches = heightInches
        self.bodyType = bodyType
        self.skinUndertone = skinUndertone
        self.hairType = hairType
        self.calorieGoal = calorieGoal
        self.createdAt = .now
    }
}
