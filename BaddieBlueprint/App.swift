import SwiftUI
import SwiftData

@main
struct BaddieBlueprintApp: App {
    var body: some Scene {
        WindowGroup {
            MainContainerView()
        }
        .modelContainer(for: [UserProfile.self, DailyLog.self, RoutineTask.self, FridgeItem.self])
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
                DashboardView()
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
