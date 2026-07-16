import Foundation
import UIKit

/// The Vision Analysis Protocol's strict photo requirements. The user must
/// be told exactly which shot to take before an analysis can be trusted.
enum PhotoRequirement: String, CaseIterable, Identifiable {
    case bareFaceColorMatch
    case naturalHairState
    case formFittingFullBody

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bareFaceColorMatch: return "Bare Face"
        case .naturalHairState: return "Natural Hair"
        case .formFittingFullBody: return "Full Body"
        }
    }

    var instruction: String {
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

struct VisionAnalysisProfilePayload: Encodable {
    let name: String
    let heightInches: Double
    let bodyType: String
    let skinUndertone: String
    let hairType: String
}

struct VisionAnalysisRequest: Encodable {
    let imageBase64: String
    let photoRequirement: String
    let profile: VisionAnalysisProfilePayload
}

struct VisionAnalysisResponse: Decodable {
    let summary: String
    let recommendations: String
}

enum VisionAPIError: LocalizedError {
    case invalidImage
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not encode the captured photo."
        case .server(let message):
            return message
        }
    }
}

/// Client-side networking only. This talks to YOUR backend proxy, which holds
/// the Anthropic API key and calls Claude server-side — the app never embeds
/// a raw key or calls the Anthropic API directly.
struct VisionAPIClient {
    /// ⚠️ Point this at your deployed Cloudflare Worker URL before shipping.
    static var endpoint = URL(string: "https://your-cloudflare-worker-subdomain.workers.dev")!

    static func analyze(
        image: UIImage,
        requirement: PhotoRequirement,
        profile: UserProfile
    ) async throws -> VisionAnalysisResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw VisionAPIError.invalidImage
        }

        let payload = VisionAnalysisRequest(
            imageBase64: imageData.base64EncodedString(),
            photoRequirement: requirement.rawValue,
            profile: VisionAnalysisProfilePayload(
                name: profile.name,
                heightInches: profile.heightInches,
                bodyType: profile.bodyType,
                skinUndertone: profile.skinUndertone,
                hairType: profile.hairType
            )
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw VisionAPIError.server("Backend returned an error response.")
        }

        return try JSONDecoder().decode(VisionAnalysisResponse.self, from: data)
    }
}
