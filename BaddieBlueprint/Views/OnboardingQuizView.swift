import SwiftUI
import SwiftData

struct OnboardingQuizView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var name = ""
    @State private var heightInches: Double = 64.0
    @State private var selectedBodyType = "Balanced Frame"
    @State private var selectedUndertone = "Neutral"
    @State private var selectedHairType = "Straight"
    @State private var weightGoal = 140
    @State private var activityLevel = "Moderately Active"

    let bodyTypes = ["Short Torso & Long Legs", "Long Torso & Short Legs", "Balanced Frame", "Athletic / Broad Shoulders"]
    let undertones = ["Cool (Pink/Blue)", "Warm (Yellow/Golden)", "Neutral", "Olive"]
    let hairTypes = ["Straight", "Wavy (2A-2C)", "Curly (3A-3C)", "Coily/Kinky (4A-4C)"]
    let activityLevels = ["Sedentary", "Lightly Active", "Moderately Active", "Very Active"]

    var body: some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(currentStep + 1), total: 5.0)
                .tint(.pink)
                .padding(.horizontal)

            Spacer()

            stepContentView
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            Spacer()

            navigationButtons
        }
        .padding()
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var stepContentView: some View {
        switch currentStep {
        case 0:
            IdentityStepView(name: $name)
        case 1:
            ProportionStepView(
                heightInches: $heightInches,
                selectedBodyType: $selectedBodyType,
                bodyTypes: bodyTypes
            )
        case 2:
            AestheticStepView(
                selectedUndertone: $selectedUndertone,
                undertones: undertones,
                selectedHairType: $selectedHairType,
                hairTypes: hairTypes
            )
        case 3:
            FitnessStepView(
                weightGoal: $weightGoal,
                activityLevel: $activityLevel,
                activityLevels: activityLevels
            )
        case 4:
            CompletionStepView()
        default:
            EmptyView()
        }
    }

    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation { currentStep -= 1 }
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }

            Spacer()

            Button(currentStep == 4 ? "Complete Profile" : "Continue") {
                if currentStep < 4 {
                    withAnimation { currentStep += 1 }
                } else {
                    saveProfileAndComplete()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .disabled(currentStep == 0 && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
    }

    private func saveProfileAndComplete() {
        // 1. Calculate Activity Modifier
        let activityModifier: Int
        switch activityLevel {
        case "Sedentary":
            activityModifier = 200
        case "Lightly Active":
            activityModifier = 400
        case "Moderately Active":
            activityModifier = 600
        case "Very Active":
            activityModifier = 800
        default:
            activityModifier = 400
        }

        // 2. Calculate Caloric Goal anchored to Weight Goal
        let calculatedCalories = (weightGoal * 10) + activityModifier

        // 3. Construct and Insert User Profile
        let newProfile = UserProfile(
            name: name,
            heightInches: heightInches,
            bodyType: selectedBodyType,
            skinUndertone: selectedUndertone,
            hairType: selectedHairType,
            calorieGoal: calculatedCalories,
            weightGoal: weightGoal
        )

        modelContext.insert(newProfile)

        // 4. Seed dynamic log tracking
        _ = SharedPersistence.todayLog(in: modelContext)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to persist onboarding configurations: \(error.localizedDescription)")
        }
    }
}

// MARK: - Step Subviews

struct IdentityStepView: View {
    @Binding var name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What is your name?")
                .font(.title)
                .fontWeight(.bold)

            TextField("Enter your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
        }
        .padding()
    }
}

struct ProportionStepView: View {
    @Binding var heightInches: Double
    @Binding var selectedBodyType: String
    let bodyTypes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Proportions")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading) {
                Text("Height: \(Int(heightInches / 12))' \(Int(heightInches) % 12)\"")
                    .font(.headline)
                Slider(value: $heightInches, in: 48...84, step: 1.0)
                    .tint(.pink)
            }

            Text("Body Structure")
                .font(.headline)
                .padding(.top, 8)

            Picker("Body Structure", selection: $selectedBodyType) {
                ForEach(bodyTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
        }
        .padding()
    }
}

struct AestheticStepView: View {
    @Binding var selectedUndertone: String
    let undertones: [String]
    @Binding var selectedHairType: String
    let hairTypes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Aesthetic Profile")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Skin Undertone")
                    .font(.headline)
                Picker("Undertone", selection: $selectedUndertone) {
                    ForEach(undertones, id: \.self) { tone in
                        Text(tone).tag(tone)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Hair Texture")
                    .font(.headline)
                Picker("Hair Texture", selection: $selectedHairType) {
                    ForEach(hairTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .tint(.pink)
            }
        }
        .padding()
    }
}

struct FitnessStepView: View {
    @Binding var weightGoal: Int
    @Binding var activityLevel: String
    let activityLevels: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Habits & Targets")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading) {
                Stepper("Weight Goal: \(weightGoal) lbs", value: $weightGoal, in: 80...300)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Activity Level")
                    .font(.headline)
                Picker("Activity Level", selection: $activityLevel) {
                    ForEach(activityLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(.inline)
            }
        }
        .padding()
    }
}

struct CompletionStepView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Profile Locked")
                .font(.title)
                .fontWeight(.bold)

            Text("Your custom calibration is complete. Preparing database configuration and populating daily baddie checklist protocols.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
