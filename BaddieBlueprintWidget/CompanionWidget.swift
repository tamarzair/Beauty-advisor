import WidgetKit
import SwiftUI

// 1. Define the Widget Entry Schema
struct CompanionEntry: TimelineEntry {
    let date: Date
    let appearance: String
    let mood: String
    let completionRate: Double
}

// 2. The Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CompanionEntry {
        CompanionEntry(date: Date(), appearance: "snatched", mood: "glowing", completionRate: 1.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (CompanionEntry) -> Void) {
        let data = SharedDefaults.readWidgetData()
        let entry = CompanionEntry(
            date: Date(),
            appearance: data.appearance,
            mood: data.mood,
            completionRate: data.completionRate
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CompanionEntry>) -> Void) {
        let data = SharedDefaults.readWidgetData()
        let currentDate = Date()

        // Generate a single timeline entry representing the current cached state
        let entry = CompanionEntry(
            date: currentDate,
            appearance: data.appearance,
            mood: data.mood,
            completionRate: data.completionRate
        )

        // Reload every 15 minutes to synchronize daily cycles
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// 3. SwiftUI Widget Presentation Layer
struct CompanionWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color.black

            switch family {
            case .systemSmall:
                smallLayout
            default:
                mediumLayout
            }
        }
    }

    private var smallLayout: some View {
        VStack(spacing: 8) {
            Text(characterIcon(for: entry.appearance))
                .font(.system(size: 40))

            Text(entry.appearance.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            ProgressView(value: entry.completionRate)
                .tint(.pink)
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 12)
        }
        .padding(8)
    }

    private var mediumLayout: some View {
        HStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(characterIcon(for: entry.appearance))
                    .font(.system(size: 56))
                Text(entry.appearance.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 100)

            VStack(alignment: .leading, spacing: 10) {
                Text("BADDIE COMPANION")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mood: \(entry.mood.uppercased())")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.pink)
                    Text("Daily execution rate:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                ProgressView(value: entry.completionRate)
                    .tint(.pink)
                    .background(Color.white.opacity(0.2))
            }
            .padding(.trailing, 12)
        }
        .padding()
    }

    private func characterIcon(for appearance: String) -> String {
        switch appearance.lowercased() {
        case "snatched": return "💅"
        case "maintenance": return "🧖‍♀️"
        default: return "🛌"
        }
    }
}

// 4. Widget Configuration Declaration
@main
struct CompanionWidget: Widget {
    let kind: String = "CompanionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                CompanionWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                CompanionWidgetEntryView(entry: entry)
                    .padding()
            }
        }
        .configurationDisplayName("Baddie Companion")
        .description("Track your Tamagotchi beauty companion's alignment and routine execution.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
