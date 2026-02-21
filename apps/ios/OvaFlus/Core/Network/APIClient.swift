import Foundation
import OSLog

class APIClient {
    static let shared = APIClient()
    private let baseURL: String
    private let logger = Logger(subsystem: "com.ovaflus.app", category: "network")

    init(baseURL: String = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://vjiibk7bi7.execute-api.us-east-1.amazonaws.com") {
        self.baseURL = baseURL
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let url = URL(string: baseURL + endpoint.path) else {
            logger.error("Bad URL for path: \(endpoint.path)")
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = await AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            logger.debug("\(endpoint.method) \(endpoint.path) — authenticated")
        } else {
            logger.debug("\(endpoint.method) \(endpoint.path) — unauthenticated")
        }
        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let start = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let elapsed = String(format: "%.0fms", Date().timeIntervalSince(start) * 1000)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("\(endpoint.method) \(endpoint.path) — invalid response")
            throw URLError(.badServerResponse)
        }

        if 200...299 ~= httpResponse.statusCode {
            logger.info("\(endpoint.method) \(endpoint.path) → \(httpResponse.statusCode) (\(elapsed))")
        } else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            logger.error("\(endpoint.method) \(endpoint.path) → \(httpResponse.statusCode) (\(elapsed)) — \(body)")
            throw NSError(
                domain: "APIError",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(body)"]
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Decode failed for \(endpoint.path): \(error.localizedDescription)")
            throw error
        }
    }
}
