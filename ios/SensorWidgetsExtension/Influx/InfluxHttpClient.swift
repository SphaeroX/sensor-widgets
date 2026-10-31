import Foundation

public final class InfluxHttpClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public static func maskToken(_ message: String, token: String) -> String {
        guard !token.isEmpty else { return message }
        return message.replacingOccurrences(of: token, with: "***")
    }

    public func query(
        connection: InfluxConnection,
        token: String,
        influxQl: String
    ) async throws -> Data {
        let trimmedBase = connection.url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var components = URLComponents(string: "\(trimmedBase)/query") else {
            throw InfluxError.networkError("Invalid InfluxDB URL: \(trimmedBase)")
        }

        components.queryItems = [
            URLQueryItem(name: "db", value: connection.database),
            URLQueryItem(name: "q", value: influxQl),
            URLQueryItem(name: "epoch", value: "ms")
        ]

        guard let url = components.url else {
            throw InfluxError.networkError("Failed to build InfluxDB query URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            let sanitized = Self.maskToken(error.localizedDescription, token: token)
            throw InfluxError.networkError("Network request failed: \(sanitized)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InfluxError.networkError("Invalid HTTP response received")
        }

        let bodyString = String(data: data, encoding: .utf8) ?? ""
        let maskedBody = Self.maskToken(bodyString, token: token)

        switch httpResponse.statusCode {
        case 200:
            return data
        case 401, 403:
            throw InfluxError.authError("Authentication failed (HTTP \(httpResponse.statusCode)): \(maskedBody)")
        case 404:
            throw InfluxError.notFoundError("InfluxDB resource or database not found (HTTP 404)")
        default:
            throw InfluxError.queryError("InfluxDB query error (HTTP \(httpResponse.statusCode)): \(maskedBody)")
        }
    }
}
