import SwiftUI
import SwiftData
import UIKit

struct VisionAnalysisView: View {
    @Query private var profiles: [UserProfile]

    @State private var selectedRequirement: PhotoRequirement = .bareFaceColorMatch
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @State private var isAnalyzing = false
    @State private var analysisResult: VisionAnalysisResponse?
    @State private var errorMessage: String?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Photo Type", selection: $selectedRequirement) {
                        ForEach(PhotoRequirement.allCases) { requirement in
                            Text(requirement.title).tag(requirement)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedRequirement.instruction)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let capturedImage {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                    } else {
                        ContentUnavailableView(
                            "No Photo Yet",
                            systemImage: "camera",
                            description: Text("Capture a photo matching the requirement above.")
                        )
                        .frame(height: 240)
                    }

                    Button(capturedImage == nil ? "Open Camera" : "Retake Photo") {
                        showingCamera = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.pink)
                    .frame(maxWidth: .infinity)

                    Button(action: runAnalysis) {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text("Analyze")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(capturedImage == nil ? Color.gray : Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(capturedImage == nil || isAnalyzing || profile == nil)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if let analysisResult {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Analysis")
                                .font(.title3.bold())
                            Text(analysisResult.summary)
                                .font(.system(.body, design: .serif))
                            ForEach(analysisResult.recommendations, id: \.self) { recommendation in
                                Label(recommendation, systemImage: "checkmark.circle")
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("Vision Analysis")
            .sheet(isPresented: $showingCamera) {
                CameraCaptureView(capturedImage: $capturedImage)
                    .ignoresSafeArea()
            }
        }
    }

    private func runAnalysis() {
        guard let capturedImage, let profile else { return }
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil

        Task {
            do {
                let result = try await VisionAPIClient.analyze(
                    image: capturedImage,
                    requirement: selectedRequirement,
                    profile: profile
                )
                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Analysis failed: \(error.localizedDescription)"
                    isAnalyzing = false
                }
            }
        }
    }
}
