import SwiftUI
import SwiftData

struct FridgeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FridgeItem.addedAt, order: .reverse) private var items: [FridgeItem]
    @Query private var profiles: [UserProfile]

    @State private var showingAddItem = false
    @State private var newItemName = ""
    @State private var newItemQuantity = 1.0
    @State private var recommendedRecipe: String? = nil
    @State private var isGeneratingRecipe = false

    var body: some View {
        NavigationStack {
            VStack {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Your Fridge is Empty",
                        systemImage: "refrigerator",
                        description: Text("Add ingredients to get personalized, target-aligned recipe recommendations.")
                    )
                } else {
                    List {
                        Section(header: Text("In Your Kitchen")) {
                            ForEach(items) { item in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                        Text("Added: \(item.addedAt.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(item.quantity, specifier: "%.1f") servings")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .onDelete(perform: deleteItems)
                        }

                        if let recipe = recommendedRecipe {
                            Section(header: Text("Baddie Recipe Blueprint")) {
                                Text(recipe)
                                    .font(.system(.body, design: .serif))
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                }

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: generateRecipeWithClaude) {
                        HStack {
                            if isGeneratingRecipe {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text("Generate Recipe Blueprint")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(items.isEmpty ? Color.gray : Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(items.isEmpty || isGeneratingRecipe)

                    Button("Add Ingredient") {
                        showingAddItem = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.pink)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("Kitchen Inventory")
            .sheet(isPresented: $showingAddItem) {
                addItemSheet
            }
        }
    }

    private var addItemSheet: some View {
        NavigationStack {
            Form {
                TextField("Ingredient Name", text: $newItemName)
                Stepper("Quantity: \(newItemQuantity, specifier: "%.1f")", value: $newItemQuantity, in: 0.5...100.0, step: 0.5)
            }
            .navigationTitle("New Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddItem = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let item = FridgeItem(name: newItemName, quantity: newItemQuantity, addedAt: Date())
                        modelContext.insert(item)
                        try? modelContext.save()

                        // Reset fields
                        newItemName = ""
                        newItemQuantity = 1.0
                        showingAddItem = false
                    }
                    .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }

    private func generateRecipeWithClaude() {
        guard let profile = profiles.first else { return }
        isGeneratingRecipe = true

        // Extract names of ingredients in the fridge
        let ingredientList = items.map { "\($0.quantity)x \($0.name)" }.joined(separator: ", ")

        // This structural payload will be routed through your secure backend proxy in production.
        // It prompts Claude using the system guidelines established in your master developer prompt.
        let payloadPrompt = """
        User Profile:
        - Target Weight: \(profile.weightGoal) lbs
        - Calorie Target: \(profile.calorieGoal) kcal
        - Body Type: \(profile.bodyType)

        Ingredients Available:
        [\(ingredientList)]

        Generate a strict, single-serving, high-fiber recipe matching this user profile.
        Focus heavily on high-value, whole-food nutritional structures (fiber and protein).
        Maintain a direct, professional, high-standard "Baddie Blueprint" tone.
        Do not suggest external brand purchases. Outline exact step-by-step preparation steps.
        """

        // Mocking API delay for local development. Swap this block with your production URLSession network utility.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.recommendedRecipe = """
            High-Fiber Sculpting Recipe:
            Using your available ingredients (\(self.items.first?.name ?? "protein source")), here is your dynamic nutrition profile:

            1. Prep: Mix ingredients prioritizing raw fiber volume.
            2. Macro Balance: Zero refined carbohydrates. High lipid and fiber matrix to preserve muscle tone.

            Keep your execution clean. No excuses.
            """
            self.isGeneratingRecipe = false
        }
    }
}
