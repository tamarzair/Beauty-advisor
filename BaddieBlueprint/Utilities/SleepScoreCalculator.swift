import Foundation

struct SleepScoreCalculator {
    static func calculateScore(bedtime: Date?, wakeTime: Date?, snoozeCount: Int, napMinutes: Int) -> (score: Double, commentary: String) {
        guard let bed = bedtime, let wake = wakeTime else {
            return (0.0, "Log your bedtime and wake times to compute your card.")
        }

        // 1. Calculate main nocturnal sleep duration (in hours)
        let interval = wake.timeIntervalSince(bed)
        let hoursSlept = max(0.0, interval / 3600.0)

        // 2. Baseline Score (8 Hours = 100%)
        let baselineScore = min(100.0, (hoursSlept / 8.0) * 100.0)

        // 3. Nap Bonus (+5 points per 30-min block, cap at +10)
        let napBonus = min(10.0, Double(napMinutes / 30) * 5.0)

        // 4. Snooze Penalty (-5 points per snooze hit)
        let snoozePenalty = Double(snoozeCount * 5)

        // 5. Aggregate Score
        let finalScore = min(100.0, max(0.0, baselineScore + napBonus - snoozePenalty))

        // 6. Generate Icon-Driven Commentary (Baddie Blueprint Archetype)
        let commentary: String
        switch finalScore {
        case 90...100:
            commentary = "Flawless sleep. Your skin barrier is fully regenerated, and cortisol levels are flatlined. Face card: Approved."
        case 70..<90:
            commentary = "Adequate recovery, but hitting snooze is holding you back from peak alignment. Clean it up tomorrow."
        case 40..<70:
            commentary = "Compromised beauty cycle. Dark spots and oxidative stress are tracking upward. Get your hydration locked down."
        default:
            commentary = "Severe sleep deficit. Cell turnover has stalled. Skip the excuses, prioritize your rest, and fix your schedule tonight."
        }

        return (finalScore, commentary)
    }
}
