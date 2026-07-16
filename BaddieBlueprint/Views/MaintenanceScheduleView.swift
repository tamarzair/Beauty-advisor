import SwiftUI
import SwiftData

struct MaintenanceScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MaintenanceCycle.name) private var cycles: [MaintenanceCycle]

    @State private var showingAddCycle = false
    @State private var newCycleName = ""
    @State private var newFrequencyDays = 7

    var body: some View {
        NavigationStack {
            VStack {
                if cycles.isEmpty {
                    ContentUnavailableView(
                        "No Maintenance Cycles",
                        systemImage: "calendar.badge.clock",
                        description: Text("Set up recurring cycles (e.g., Wash Day, Wax, Exfoliate) to keep your baseline routine calibrated.")
                    )
                } else {
                    List {
                        ForEach(cycles) { cycle in
                            CycleRow(cycle: cycle, onComplete: {
                                cycle.lastCompletedDate = Date()
                                try? modelContext.save()
                            })
                        }
                        .onDelete(perform: deleteCycles)
                    }
                }

                Button("Add Maintenance Cycle") {
                    showingAddCycle = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .padding()
            }
            .navigationTitle("High Maintenance")
            .sheet(isPresented: $showingAddCycle) {
                addCycleSheet
            }
        }
    }

    private var addCycleSheet: some View {
        NavigationStack {
            Form {
                TextField("Cycle Name (e.g., Hair Wash Day)", text: $newCycleName)
                Stepper("Frequency: Every \(newFrequencyDays) days", value: $newFrequencyDays, in: 1...90)
            }
            .navigationTitle("New Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddCycle = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cycle = MaintenanceCycle(name: newCycleName, frequencyDays: newFrequencyDays)
                        modelContext.insert(cycle)
                        try? modelContext.save()

                        newCycleName = ""
                        newFrequencyDays = 7
                        showingAddCycle = false
                    }
                    .disabled(newCycleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func deleteCycles(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(cycles[index])
        }
        try? modelContext.save()
    }
}

struct CycleRow: View {
    var cycle: MaintenanceCycle
    var onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(cycle.name)
                    .font(.headline)
                Spacer()
                if cycle.isOverdue {
                    Text("OVERDUE")
                        .font(.caption2)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                } else {
                    Text("\(cycle.daysRemaining) days left")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Progress Bar representing elapsed time in cycle
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    Capsule()
                        .fill(cycle.isOverdue ? Color.red : Color.pink)
                        .frame(width: progressWidth(totalWidth: geo.size.width), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Last done: \(cycle.lastCompletedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Mark Completed", action: onComplete)
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(.pink)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        let elapsed = Double(cycle.frequencyDays - max(0, cycle.daysRemaining))
        let percentage = elapsed / Double(cycle.frequencyDays)
        return totalWidth * CGFloat(min(1.0, max(0.0, percentage)))
    }
}
