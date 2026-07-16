//
//  BaddieBlueprintSchema.swift
//  Baddie Blueprint
//
//  Core SwiftData schema for the entire local ecosystem.
//  Targets: iOS 17.0+ (SwiftData), shared between App + Widget via App Group.
//
//  Design notes:
//  - All persistence is LOCAL ONLY. No CloudKit sync configured by default.
//  - Enums are stored as raw `String`/`Int` values for schema-migration safety.
//  - One `DailyLog` per calendar day is the aggregation root for the
//    Tamagotchi engine, widgets, and scoring.
//

import Foundation
import SwiftData

// MARK: - ═══════════════════════════════════════════════════════════
// MARK: Domain Enums (Codable raw-value types — safe for SwiftData)
// MARK: ═══════════════════════════════════════════════════════════

/// The three widget/routine cycles the app revolves around.
enum RoutineCycle: String, Codable, CaseIterable, Sendable {
    case morning
    case afternoon
    case evening

    /// Local-time boundaries used by the app and the WidgetKit timeline.
    var hourRange: Range<Int> {
        switch self {
        case .morning:   return 4..<12
        case .afternoon: return 12..<18
        case .evening:   return 18..<24
        }
    }

    static func current(for date: Date = .now, calendar: Calendar = .current) -> RoutineCycle {
        let hour = calendar.component(.hour, from: date)
        return allCases.first { $0.hourRange.contains(hour) } ?? .evening
    }
}

/// Every trackable routine action. `penaltyWorkout` is injected automatically
/// when a gym task is skipped ("no excuses" rule).
enum TaskKind: String, Codable, CaseIterable, Sendable {
    // Morning — the "snatched" checklist
    case wakeUpOnTime
    case brushTeethAM
    case skincareAM
    case styling            // hair + outfit executed

    // Afternoon
    case hydrationGoal
    case mealLogged
    case movement           // steps / activity

    // Evening
    case gym
    case penaltyWorkout     // forced 5-min pre-bed sequence if gym unchecked
    case skincarePM
    case brushTeethPM
    case bedOnTime

    // Flexible
    case kindnessCheckIn
    case custom

    var defaultCycle: RoutineCycle {
        switch self {
        case .wakeUpOnTime, .brushTeethAM, .skincareAM, .styling:
            return .morning
        case .hydrationGoal, .mealLogged, .movement:
            return .afternoon
        default:
            return .evening
        }
    }
}

/// Visual state tiers for the pixel companion.
enum CompanionMood: String, Codable, CaseIterable, Sendable {
    case snatched      // 90–100% completion — full glam sprite
    case glowing       // 70–89%
    case coasting      // 50–69%
    case tired         // 25–49% — under-eye shadows, messy bun sprite
    case bummy         // 0–24%  — robe, slippers, wilted posture

    /// Asset catalog sprite prefix, e.g. "companion_snatched_stage2".
    var spritePrefix: String { "companion_\(rawValue)" }

    static func from(completionRate: Double) -> CompanionMood {
        switch completionRate {
        case 0.90...:   return .snatched
        case 0.70..<0.90: return .glowing
        case 0.50..<0.70: return .coasting
        case 0.25..<0.50: return .tired
        default:        return .bummy
        }
    }
}

/// Andre Walker–style hair typing, extended.
enum HairTexture: String, Codable, CaseIterable, Sendable {
    case type1A, type1B, type1C   // straight
    case type2A, type2B, type2C   // wavy
    case type3A, type3B, type3C   // curly
    case type4A, type4B, type4C   // coily
}

enum HairDensity: String, Codable, CaseIterable, Sendable {
    case low, medium, high
}

enum HairPorosity: String, Codable, CaseIterable, Sendable {
    case low, normal, high
}

enum SkinUndertone: String, Codable, CaseIterable, Sendable {
    case cool, warm, neutral, olive
}

/// Structural body-proportion read used for tactical styling advice.
enum TorsoLegRatio: String, Codable, CaseIterable, Sendable {
    case shortTorsoLongLegs
    case balanced
    case longTorsoShortLegs
}

enum BodyFrame: String, Codable, CaseIterable, Sendable {
    case hourglass, pear, apple, rectangle, invertedTriangle
}

enum FitnessGoal: String, Codable, CaseIterable, Sendable {
    case cut, recomposition, maintain, build
}

/// "High-maintenance to stay low-maintenance" recurring cycles.
enum MaintenanceKind: String, Codable, CaseIterable, Sendable {
    case everythingShower
    case exfoliation
    case hairWash
    case deepCondition
    case waxing
    case lashes
    case nails
    case brows
    case periodCycle
    case doctorAppointment
    case dentistAppointment

    var suggestedIntervalDays: Int {
        switch self {
        case .everythingShower:   return 7
        case .exfoliation:        return 3
        case .hairWash:           return 4
        case .deepCondition:      return 14
        case .waxing:             return 28
        case .lashes:             return 21
        case .nails:              return 14
        case .brows:              return 21
        case .periodCycle:        return 28
        case .doctorAppointment:  return 365
        case .dentistAppointment: return 182
        }
    }
}

/// The Vision Analysis Protocol's strict photo requirements.
/// The advisor must request the *exact* type before analysis runs.
enum PhotoRequirement: String, Codable, CaseIterable, Sendable {
    case bareFaceColorMatch      // no makeup, no filters, neutral daylight
    case naturalHairState        // product-free, air-dried, texture visible
    case formFittingFullBody     // fitted wear, plain background, full frame

    var userInstruction: String {
        switch self {
        case .bareFaceColorMatch:
            return "Bare skin only. No makeup, no filters, no warm lamps — natural daylight, plain background. We're matching your undertone, not your ring light."
        case .naturalHairState:
            return "Hair in its natural, product-free state. Air-dried, no heat, no slick-back. I need to see the real texture and density."
        case .formFittingFullBody:
            return "Full body, head to toe, form-fitting wear, plain background, camera at waist height. Structure first — we can't tailor what we can't see."
        }
    }
}

enum AnalysisStatus: String, Codable, Sendable {
    case awaitingUpload
    case rejectedRetake     // image failed requirement validation
    case processing
    case complete
    case failed
}

// MARK: - ═══════════════════════════════════════════════════════════
// MARK: User Profile (Onboarding Quiz output)
// MARK: ═══════════════════════════════════════════════════════════

@Model
final class UserProfile {
    // Identity
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var onboardingComplete: Bool

    // Structure
    var heightCm: Double
    var weightKg: Double?
    var torsoLegRatioRaw: String
    var bodyFrameRaw: String?

    // Hair
    var hairTextureRaw: String
    var hairDensityRaw: String
    var hairPorosityRaw: String?

    // Skin
    var skinUndertoneRaw: String?      // nil until quiz or vision analysis fills it
    var skinDepthScale: Int?           // 1 (lightest) … 10 (deepest)
    var skinConcerns: [String]         // e.g. ["compromised barrier", "hyperpigmentation"]

    // Schedule & goals
    var wakeGoalMinutesFromMidnight: Int    // e.g. 360 = 6:00 AM
    var bedGoalMinutesFromMidnight: Int     // e.g. 1350 = 10:30 PM
    var dailyCalorieTarget: Int
    var dailyFiberTargetGrams: Int
    var dailyWaterTargetML: Int
    var fitnessGoalRaw: String
    var gymDaysPerWeek: Int

    // Typed accessors (raw storage keeps migrations painless)
    var torsoLegRatio: TorsoLegRatio {
        get { TorsoLegRatio(rawValue: torsoLegRatioRaw) ?? .balanced }
        set { torsoLegRatioRaw = newValue.rawValue }
    }
    var bodyFrame: BodyFrame? {
        get { bodyFrameRaw.flatMap(BodyFrame.init(rawValue:)) }
        set { bodyFrameRaw = newValue?.rawValue }
    }
    var hairTexture: HairTexture {
        get { HairTexture(rawValue: hairTextureRaw) ?? .type3A }
        set { hairTextureRaw = newValue.rawValue }
    }
    var hairDensity: HairDensity {
        get { HairDensity(rawValue: hairDensityRaw) ?? .medium }
        set { hairDensityRaw = newValue.rawValue }
    }
    var hairPorosity: HairPorosity? {
        get { hairPorosityRaw.flatMap(HairPorosity.init(rawValue:)) }
        set { hairPorosityRaw = newValue?.rawValue }
    }
    var skinUndertone: SkinUndertone? {
        get { skinUndertoneRaw.flatMap(SkinUndertone.init(rawValue:)) }
        set { skinUndertoneRaw = newValue?.rawValue }
    }
    var fitnessGoal: FitnessGoal {
        get { FitnessGoal(rawValue: fitnessGoalRaw) ?? .maintain }
        set { fitnessGoalRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        heightCm: Double = 165,
        weightKg: Double? = nil,
        torsoLegRatio: TorsoLegRatio = .balanced,
        hairTexture: HairTexture = .type3A,
        hairDensity: HairDensity = .medium,
        wakeGoalMinutesFromMidnight: Int = 6 * 60,
        bedGoalMinutesFromMidnight: Int = 22 * 60 + 30,
        dailyCalorieTarget: Int = 1900,
        dailyFiberTargetGrams: Int = 30,
        dailyWaterTargetML: Int = 2500,
        fitnessGoal: FitnessGoal = .maintain,
        gymDaysPerWeek: Int = 4
    ) {
        self.id = id
        self.createdAt = .now
        self.onboardingComplete = false
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.torsoLegRatioRaw = torsoLegRatio.rawValue
        self.bodyFrameRaw = nil
        self.hairTextureRaw = hairTexture.rawValue
        self.hairDensityRaw = hairDensity.rawValue
        self.hairPorosityRaw = nil
        self.skinUndertoneRaw = nil
        self.skinDepthScale = nil
        self.skinConcerns = []
        self.wakeGoalMinutesFromMidnight = wakeGoalMinutesFromMidnight
        self.bedGoalMinutesFromMidnight = bedGoalMinutesFromMidnight
        self.dailyCalorieTarget = dailyCalorieTarget
        self.dailyFiberTargetGrams = dailyFiberTargetGrams
        self.dailyWaterTargetML = dailyWaterTargetML
        self.fitnessGoalRaw = fitnessGoal.rawValue
        self.gymDaysPerWeek = gymDaysPerWeek
    }
}

// MARK: - ═══════════════════════════════════════════════════════════
// MARK: Daily Log — the aggregation root per calendar day
// MARK: ═══════════════════════════════════════════════════════════

@Model
final class DailyLog {
    /// Start-of-day (local calendar) — one log per day, enforced by uniqueness.
    @Attribute(.unique) var day: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineTask.dailyLog)
    var tasks: [RoutineTask]

    @Relationship(deleteRule: .cascade, inverse: \SleepLog.dailyLog)
    var sleepLog: SleepLog?

    @Relationship(deleteRule: .cascade, inverse: \MealLog.dailyLog)
    var meals: [MealLog]

    @Relationship(deleteRule: .cascade, inverse: \KindnessCheckIn.dailyLog)
    var kindnessCheckIn: KindnessCheckIn?

    var hydrationML: Int
    var notes: String?

    // ── Derived scoring ──────────────────────────────────────────

    var requiredTasks: [RoutineTask] { tasks.filter(\.isRequired) }

    var completionRate: Double {
        let required = requiredTasks
        guard !required.isEmpty else { return 0 }
        let done = required.filter(\.isCompleted).count
        return Double(done) / Double(required.count)
    }

    func completionRate(for cycle: RoutineCycle) -> Double {
        let cycleTasks = requiredTasks.filter { $0.cycle == cycle }
        guard !cycleTasks.isEmpty else { return 0 }
        return Double(cycleTasks.filter(\.isCompleted).count) / Double(cycleTasks.count)
    }

    var companionMood: CompanionMood { .from(completionRate: completionRate) }

    var totalCalories: Int { meals.reduce(0) { $0 + $1.calories } }
    var totalFiberGrams: Double { meals.reduce(0) { $0 + $1.fiberGrams } }

    /// "No excuses" rule: gym skipped after its window → inject the
    /// mandatory 5-minute pre-bed sequence if not already present.
    @discardableResult
    func enforceGymPenaltyIfNeeded(now: Date = .now) -> RoutineTask? {
        guard
            let gym = tasks.first(where: { $0.kind == .gym }),
            gym.isRequired, !gym.isCompleted,
            RoutineCycle.current(for: now) == .evening,
            !tasks.contains(where: { $0.kind == .penaltyWorkout })
        else { return nil }

        let penalty = RoutineTask(
            kind: .penaltyWorkout,
            cycle: .evening,
            title: "5-Min Pre-Bed Circuit (non-negotiable)",
            isRequired: true,
            sortOrder: 99
        )
        penalty.dailyLog = self
        tasks.append(penalty)
        return penalty
    }

    init(day: Date) {
        self.day = Calendar.current.startOfDay(for: day)
        self.tasks = []
        self.meals = []
        self.hydrationML = 0
    }

    /// Standard task template applied when a new day is created.
    static func seedTasks(into log: DailyLog, gymDayToday: Bool) {
        let template: [(TaskKind, String, Bool)] = [
            (.wakeUpOnTime, "Up on the first alarm", true),
            (.brushTeethAM, "Teeth — AM", true),
            (.skincareAM,   "AM skincare protocol", true),
            (.styling,      "Hair + outfit executed", true),
            (.hydrationGoal,"Hit water target", true),
            (.mealLogged,   "Meals logged", true),
            (.movement,     "Daily movement", true),
            (.gym,          "Gym session", gymDayToday),
            (.skincarePM,   "PM skincare protocol", true),
            (.brushTeethPM, "Teeth — PM", true),
            (.bedOnTime,    "In bed on schedule", true),
            (.kindnessCheckIn, "Kindness & mindset check-in", true),
        ]
        for (index, entry) in template.enumerated() {
            let task = RoutineTask(
                kind: entry.0,
                cycle: entry.0.defaultCycle,
                title: entry.1,
                isRequired: entry.2,
                sortOrder: index
            )
            task.dailyLog = log
            log.tasks.append(task)
        }
    }
}

// MARK: - Routine Task

@Model
final class RoutineTask {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var cycleRaw: String
    var title: String
    var isRequired: Bool
    var isCompleted: Bool
    var completedAt: Date?
    var sortOrder: Int

    var dailyLog: DailyLog?

    var kind: TaskKind {
        get { TaskKind(rawValue: kindRaw) ?? .custom }
        set { kindRaw = newValue.rawValue }
    }
    var cycle: RoutineCycle {
        get { RoutineCycle(rawValue: cycleRaw) ?? .morning }
        set { cycleRaw = newValue.rawValue }
    }

    func toggle(now: Date = .now) {
        isCompleted.toggle()
        completedAt = isCompleted ? now : nil
    }

    init(
        id: UUID = UUID(),
        kind: TaskKind,
        cycle: RoutineCycle,
        title: String,
        isRequired: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.cycleRaw = cycle.rawValue
        self.title = title
        self.isRequired = isRequired
        self.isCompleted = false
        self.sortOrder = sortOrder
    }
}

// MARK: - ═══════════════════════════════════════════════════════════
// MARK: Sleep — Beauty Sleep Score
// MARK: ═══════════════════════════════════════════════════════════

@Model
final class SleepLog {
    @Attribute(.unique) var id: UUID
    var bedtime: Date?
    var wakeTime: Date?
    var snoozeCount: Int
    var napMinutes: Int

    var dailyLog: DailyLog?

    var sleepDurationMinutes: Int? {
        guard let bedtime, let wakeTime, wakeTime > bedtime else { return nil }
        return Int(wakeTime.timeIntervalSince(bedtime) / 60)
    }

    /// 0–100. Duration (60 pts) + consistency vs. goals (25 pts) − snooze
    /// penalty (up to −15) + smart-nap bonus (up to +5, capped at 100).
    func beautySleepScore(profile: UserProfile?) -> Int {
        var score = 0.0

        // Duration: full 60 points at 7.5–9h, linear falloff outside.
        if let duration = sleepDurationMinutes {
            let hours = Double(duration) / 60.0
            switch hours {
            case 7.5...9.0: score += 60
            case ..<7.5:    score += max(0, 60 - (7.5 - hours) * 20)
            default:        score += max(0, 60 - (hours - 9.0) * 15)
            }
        }

        // Consistency vs. bed/wake goals (within 30 min → full credit).
        if let profile, let bedtime, let wakeTime {
            let cal = Calendar.current
            func minutesFromMidnight(_ date: Date) -> Int {
                cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
            }
            func circularDelta(_ a: Int, _ b: Int) -> Int {
                let d = abs(a - b) % 1440
                return min(d, 1440 - d)
            }
            let bedDelta = circularDelta(minutesFromMidnight(bedtime), profile.bedGoalMinutesFromMidnight)
            let wakeDelta = circularDelta(minutesFromMidnight(wakeTime), profile.wakeGoalMinutesFromMidnight)
            score += max(0, 12.5 - Double(max(0, bedDelta - 30)) * 0.25)
            score += max(0, 12.5 - Double(max(0, wakeDelta - 30)) * 0.25)
        }

        // Snooze penalty: the alarm is not a suggestion.
        score -= Double(min(snoozeCount, 5)) * 3.0

        // Nap bonus: 10–30 min power naps only.
        if (10...30).contains(napMinutes) { score += 5 }

        return Int(score.rounded()).clamped(to: 0...100)
    }

    init(id: UUID = UUID(), bedtime: Date? = nil, wakeTime: Date? = nil,
         snoozeCount: Int = 0, napMinutes: Int = 0) {
        self.id = id
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.snoozeCount = snoozeCount
        self.napMinutes = napMinutes
    }
}

// MARK: - ═══════════════════════════════════════════════════════════
// MARK: Kitchen — Fridge Inventory & Meal Logging
// MARK: ═══════════════════════════════════════════════════════════

@Model
final class FridgeItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var servingsRemaining: Double
    var servingDescription: String        // "1 cup", "100 g", "1 fillet"
    var caloriesPerServing: Int
    var proteinGramsPerServing: Double
    var fiberGramsPerServing: Double
    var carbsGramsPerServing: Double
    var fatGramsPerServing: Double
    var expiresOn: Date?
    var addedAt: Date

    var isExpiringSoon: Bool {
        guard let expiresOn else { return false }
        return expiresOn.timeIntervalSinceNow < 48 * 3600
    }

    init(
        id: UUID = UUID(),
        name: String,
        servingsRemaining: Double,
        servingDescription: String,
        caloriesPerServing: Int,
        proteinGramsPerServing: Double = 0,
        fiberGramsPerServing: Double = 0,
        carbsGramsPerServing: Double = 0,
        fatGramsPerServing: Double = 0,
        expiresOn: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.servingsRemaining = servingsRemaining
        self.servingDescription = servingDescription
        self.caloriesPerServing = caloriesPerServing
        self.proteinGramsPerServing = proteinGramsPerServing
        self.fiberGramsPerServing = fiberGramsPerServing
        self.carbsGramsPerServing = carbsGramsPerServing
        self.fatGramsPerServing = fatGramsPerServing
        self.expiresOn = expiresOn
        self.addedAt = .now
    }
}

@Model
final class MealLog {
    @Attribute(.unique) var id: UUID
    var name: String
    var loggedAt: Date
    var calories: Int
    var proteinGrams: Double
    var fiberGrams: Double
    var carbsGrams: Double
    var fatGrams: Double
    /// FridgeItem IDs consumed — servings are decremented at log time.
    var consumedFridgeItemIDs: [UUID]
    /// True when the meal came from an AI-generated recipe suggestion.
    var fromAISuggestion: Bool

    var dailyLog: DailyLog?

    init(
        id: UUID = UUID(),
        name: String,
        loggedAt: Date = .now,
        calories: Int,
        proteinGrams: Double = 0,
        fiberGrams: Double = 0,
        carbsGrams: Double = 0,
        fatGrams: Double = 0,
        consumedFridgeItemIDs: [UUID] = [],
        fromAISuggestion: Bool = false
    ) {
        self.id = id
        self.name = name
        self.loggedAt = loggedAt
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.fiberGrams = fiberGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.consumedFridgeItemIDs = consumedFridgeItemIDs
        self.fromAISuggestion = fromAISuggestion
    }
}

// MARK: - ═══════════════════════════════════════════════════════════
// MARK: Schedule Manager — Maintenance Cycles & Appointments
// MARK: ═══════════════════════════════════════════════════════════

@Model
final class MaintenanceCycle {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var customLabel: String?
    var intervalDays: Int
    var lastCompletedOn: Date?
    var isActive: Bool
    var notes: String?

    var kind: MaintenanceKind {
        get { MaintenanceKind(rawValue: kindRaw) ?? .everythingShower }
        set { kindRaw = newValue.rawValue }
    }

    var nextDue: Date? {
        guard let lastCompletedOn else { return nil }
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: lastCompletedOn)
    }

    var isOverdue: Bool {
        guard let nextDue else { return false }
        return nextDue < .now
    }

    func markCompleted(on date: Date = .now) { lastCompletedOn = date }

    init(id: UUID = UUID(), kind: MaintenanceKind, intervalDays: Int? = nil,
         customLabel: String? = nil, lastCompletedOn: Date? = nil) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.customLabel = customLabel
        self.intervalDays = intervalDays ?? kind.suggestedIntervalDays
        self.lastCompletedOn = lastCompletedOn
        self.isActive = true
    }
}

/// Fixed-date bookings (doctor, dentist, wax appointment, etc.).
@Model
final class ScheduledAppointment {
    @Attribute(.unique) var id: UUID
    var title: String
    var kindRaw: String?
    var date: Date
    var locationNote: String?
    var isCompleted: Bool

    var kind: MaintenanceKind? {
        get { kindRaw.flatMap(MaintenanceKind.init(rawValue:)) }
        set { kindRaw = newValue?.rawValue }
    }

    init(id: UUID = UUID(), title: String, kind: MaintenanceKind? = nil,
         date: Date, locationNote: String? = nil) {
        self.id = id
        self.title = title
        self.kindRaw = kind?.rawValue
        self.date = date
        self.locationNote = locationNote
        self.isCompleted = false
    }
}

// MARK: - ═══════════════════════════════════════════════════════════
// MARK: Kindness & Mindset Check-in
// MARK: ═══════════════════════════════════════════════════════════

@Model
final class KindnessCheckIn {
    @Attribute(.unique) var id: UUID
    var loggedAt: Date
    var actsOfSelfCare: [String]
    var mindsetScore: Int          // 1 (spiraling) … 5 (aligned)
    var affirmation: String?
    var journalEntry: String?

    var dailyLog: DailyLog?

    init(id: UUID = UUID(), loggedAt: Date = .now,
         actsOfSelfCare: [String] = [], mindsetScore: Int = 3,
         affirmation: String? = nil, journalEntry: String? = nil) {
        self.id = id
        self.loggedAt = loggedAt
        self.actsOfSelfCare = actsOfSelfCare
        self.mindsetScore = mindsetScore
        self.affirmation = affirmation
        self.journalEntry = journalEntry
    }
}

// MARK: - ═══════════════════════════════════════════════════════════
// MARK: Companion State (Tamagotchi Engine persistence)
// MARK: ═══════════════════════════════════════════════════════════

@Model
final class CompanionState {
    /// Singleton row — always fetch-or-create with `wellKnownID`.
    @Attribute(.unique) var id: UUID
    static let wellKnownID = UUID(uuidString: "B4DD1E00-0000-0000-0000-000000000001")!

    var displayName: String
    var currentMoodRaw: String
    var evolutionStage: Int          // grows with sustained streaks
    var streakDays: Int
    var longestStreak: Int
    var lastEvaluatedDay: Date?
    var unlockedWardrobeIDs: [String]

    var currentMood: CompanionMood {
        get { CompanionMood(rawValue: currentMoodRaw) ?? .coasting }
        set { currentMoodRaw = newValue.rawValue }
    }

    /// Full sprite asset name for rendering in-app and in widgets.
    var spriteAssetName: String {
        "\(currentMood.spritePrefix)_stage\(evolutionStage)"
    }

    /// End-of-day evaluation: mood from completion, streak bookkeeping,
    /// evolution every 7 consecutive "glowing or better" days.
    func evaluate(dailyLog: DailyLog, now: Date = .now) {
        let day = Calendar.current.startOfDay(for: dailyLog.day)
        guard lastEvaluatedDay.map({ Calendar.current.startOfDay(for: $0) != day }) ?? true else { return }

        currentMood = dailyLog.companionMood

        if dailyLog.completionRate >= 0.70 {
            streakDays += 1
            longestStreak = max(longestStreak, streakDays)
            if streakDays.isMultiple(of: 7) {
                evolutionStage = min(evolutionStage + 1, 5)
            }
        } else {
            streakDays = 0
        }
        lastEvaluatedDay = day
    }

    /// Intraday refresh so the widget degrades/upgrades in real time.
    func refreshMood(from dailyLog: DailyLog) {
        currentMood = dailyLog.companionMood
    }

    init(displayName: String = "Baddie") {
        self.id = Self.wellKnownID
        self.displayName = displayName
        self.currentMoodRaw = CompanionMood.coasting.rawValue
        self.evolutionStage = 1
        self.streakDays = 0
        self.longestStreak = 0
        self.unlockedWardrobeIDs = []
    }
}

// MARK: - ═══════════════════════════════════════════════════════════
// MARK: Vision Analysis Protocol (metadata only — pixels never persisted
// MARK: beyond the encrypted upload pipeline)
// MARK: ═══════════════════════════════════════════════════════════

@Model
final class VisionAnalysisRecord {
    @Attribute(.unique) var id: UUID
    var requirementRaw: String
    var statusRaw: String
    var submittedAt: Date?
    var completedAt: Date?
    var rejectionReason: String?      // e.g. "Filter detected — retake bare-faced"

    /// Structured findings from the model, stored as JSON
    /// (e.g. {"undertone":"olive","depth":6,"frame":"pear"}).
    var findingsJSON: String?

    /// Whether findings were merged into the UserProfile.
    var appliedToProfile: Bool

    var requirement: PhotoRequirement {
        get { PhotoRequirement(rawValue: requirementRaw) ?? .bareFaceColorMatch }
        set { requirementRaw = newValue.rawValue }
    }
    var status: AnalysisStatus {
        get { AnalysisStatus(rawValue: statusRaw) ?? .awaitingUpload }
        set { statusRaw = newValue.rawValue }
    }

    func decodedFindings<T: Decodable>(_ type: T.Type) -> T? {
        guard let findingsJSON, let data = findingsJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    init(id: UUID = UUID(), requirement: PhotoRequirement) {
        self.id = id
        self.requirementRaw = requirement.rawValue
        self.statusRaw = AnalysisStatus.awaitingUpload.rawValue
        self.appliedToProfile = false
    }
}

// MARK: - ═══════════════════════════════════════════════════════════
// MARK: Schema Registry
// MARK: ═══════════════════════════════════════════════════════════

enum BaddieSchema {
    /// Single source of truth for every persisted model — used by the
    /// app target AND the widget extension.
    static let models: [any PersistentModel.Type] = [
        UserProfile.self,
        DailyLog.self,
        RoutineTask.self,
        SleepLog.self,
        FridgeItem.self,
        MealLog.self,
        MaintenanceCycle.self,
        ScheduledAppointment.self,
        KindnessCheckIn.self,
        CompanionState.self,
        VisionAnalysisRecord.self,
    ]

    static var schema: Schema { Schema(models) }
}

// MARK: - Small utilities

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
