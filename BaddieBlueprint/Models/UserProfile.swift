import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var heightInches: Double
    var bodyType: String
    var skinUndertone: String
    var hairType: String
    var calorieGoal: Int
    var weightGoal: Int

    init(
        name: String = "",
        heightInches: Double = 64.0,
        bodyType: String = "",
        skinUndertone: String = "",
        hairType: String = "",
        calorieGoal: Int = 1800,
        weightGoal: Int = 140
    ) {
        self.name = name
        self.heightInches = heightInches
        self.bodyType = bodyType
        self.skinUndertone = skinUndertone
        self.hairType = hairType
        self.calorieGoal = calorieGoal
        self.weightGoal = weightGoal
    }
}
