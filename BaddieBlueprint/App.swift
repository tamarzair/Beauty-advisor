import SwiftUI
import SwiftData

@main
struct BaddieBlueprintApp: App {
    var body: some Scene {
        WindowGroup {
            MainContainerView()
        }
        .modelContainer(for: [UserProfile.self, DailyLog.self, RoutineTask.self, FridgeItem.self, MaintenanceCycle.self])
    }
}

struct MainContainerView: View {
    @Query private var profiles: [UserProfile]
    @State private var showingOnboarding = false

    var body: some View {
        Group {
            if profiles.isEmpty {
                Color.clear
                    .onAppear {
                        showingOnboarding = true
                    }
            } else {
                MainTabView()
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingQuizView()
                .interactiveDismissDisabled()
        }
        .onChange(of: profiles.isEmpty) { _, isEmpty in
            showingOnboarding = isEmpty
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "sparkles")
                }

            FridgeView()
                .tabItem {
                    Label("Kitchen", systemImage: "refrigerator")
                }

            SleepTrackerView()
                .tabItem {
                    Label("Sleep", systemImage: "moon.zzz")
                }

            MaintenanceScheduleView()
                .tabItem {
                    Label("Maintenance", systemImage: "calendar.badge.clock")
                }

            VisionAnalysisView()
                .tabItem {
                    Label("Vision", systemImage: "camera.viewfinder")
                }
        }
        .tint(.pink)
    }
}
