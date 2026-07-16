import Foundation
import WidgetKit

struct SharedDefaults {
    static let appGroupID = "group.com.yourname.BaddieBlueprint" // Update with your actual group ID

    static func writeWidgetData(appearance: String, mood: String, completionRate: Double) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(appearance, forKey: "companionAppearance")
        defaults.set(mood, forKey: "companionMood")
        defaults.set(completionRate, forKey: "completionRate")

        // Signal the Widget system to fetch new timeline entries
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func readWidgetData() -> (appearance: String, mood: String, completionRate: Double) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return ("maintenance", "managing", 0.5)
        }
        let appearance = defaults.string(forKey: "companionAppearance") ?? "maintenance"
        let mood = defaults.string(forKey: "companionMood") ?? "managing"
        let completionRate = defaults.double(forKey: "completionRate")
        return (appearance, mood, completionRate)
    }
}
