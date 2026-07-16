import SwiftUI
import SwiftData

struct SleepTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var logs: [DailyLog]

    @State private var localBedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var localWakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var localSnooze = 0
    @State private var localNaps = 0

    var currentLog: DailyLog {
        SharedPersistence.todayLog(in: modelContext)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Gauge Progress Ring
                    sleepGaugeHeader

                    // Time Selectors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Log Your Sleep Cycle")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        DatePicker("Bedtime", selection: $localBedtime, displayedComponents: [.hourAndMinute, .date])
                            .datePickerStyle(.compact)

                        DatePicker("Wake Time", selection: $localWakeTime, displayedComponents: [.hourAndMinute, .date])
                            .datePickerStyle(.compact)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Adjusters
                    VStack(spacing: 20) {
                        Stepper(value: $localSnooze, in: 0...10) {
                            HStack {
                                Image(systemName: "alarm")
                                    .foregroundColor(.pink)
                                Text("Snoozes Hit: \(localSnooze)")
                                    .bold()
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bolt.heart")
                                    .foregroundColor(.pink)
                                Text("Naps Logged: \(localNaps) mins")
                                    .bold()
                            }
                            Slider(value: Binding(
                                get: { Double(localNaps) },
                                set: { localNaps = Int($0) }
                            ), in: 0...120, step: 15)
                            .tint(.pink)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Sleep Blueprint")
            .onAppear(perform: initializeLocalState)
            .onChange(of: localBedtime) { _, _ in updateLogData() }
            .onChange(of: localWakeTime) { _, _ in updateLogData() }
            .onChange(of: localSnooze) { _, _ in updateLogData() }
            .onChange(of: localNaps) { _, _ in updateLogData() }
        }
    }

    private var sleepGaugeHeader: some View {
        let calculations = SleepScoreCalculator.calculateScore(
            bedtime: currentLog.bedtime,
            wakeTime: currentLog.wakeTime,
            snoozeCount: currentLog.snoozeCount,
            napMinutes: currentLog.napDurationMinutes
        )

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.pink.opacity(0.2), lineWidth: 16)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0.0, to: CGFloat(calculations.score / 100.0))
                    .stroke(Color.pink, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: calculations.score)

                VStack {
                    Text("\(Int(calculations.score))")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                    Text("Sleep Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)

            Text(calculations.commentary)
                .font(.subheadline)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
        }
    }

    private func initializeLocalState() {
        let log = currentLog

        // Default bedtime to last night if nil
        if let storedBedtime = log.bedtime {
            localBedtime = storedBedtime
        } else {
            let lastNight = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            localBedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: lastNight) ?? lastNight
            log.bedtime = localBedtime
        }

        // Default wakeTime to today if nil
        if let storedWakeTime = log.wakeTime {
            localWakeTime = storedWakeTime
        } else {
            localWakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
            log.wakeTime = localWakeTime
        }

        localSnooze = log.snoozeCount
        localNaps = log.napDurationMinutes

        updateLogData()
    }

    private func updateLogData() {
        let log = currentLog
        log.bedtime = localBedtime
        log.wakeTime = localWakeTime
        log.snoozeCount = localSnooze
        log.napDurationMinutes = localNaps

        let calculations = SleepScoreCalculator.calculateScore(
            bedtime: localBedtime,
            wakeTime: localWakeTime,
            snoozeCount: localSnooze,
            napMinutes: localNaps
        )

        log.sleepScore = calculations.score
        try? modelContext.save()
    }
}
