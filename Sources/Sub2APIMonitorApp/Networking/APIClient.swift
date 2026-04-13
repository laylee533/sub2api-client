import Foundation

enum APIClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case missingResponseData
    case badStatus(Int, String)
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "站点地址无效，无法构建 API 请求。"
        case .invalidResponse:
            return "服务端返回了无法识别的响应。"
        case .missingResponseData:
            return "服务端返回成功，但缺少 data 字段。请检查 sub2api 版本或网关返回格式。"
        case let .badStatus(statusCode, message):
            return "请求失败（\(statusCode)）：\(message)"
        case let .serverMessage(message):
            return message
        }
    }
}

private struct APIEnvelope<T: Decodable>: Decodable {
    var code: Int
    var message: String
    var data: T
}

private struct APIStatusEnvelope: Decodable {
    var code: Int
    var message: String
}

struct APIClient {
    var session: URLSession = .shared

    func get<T: Decodable>(
        _ type: T.Type,
        site: SiteConfiguration,
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        guard let url = site.apiURL(path: path, queryItems: queryItems) else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(site.adminToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await send(request, as: type)
    }

    func post<T: Decodable, Body: Encodable>(
        _ type: T.Type,
        site: SiteConfiguration,
        path: String,
        body: Body
    ) async throws -> T {
        guard let url = site.apiURL(path: path) else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("Bearer \(site.adminToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return try await send(request, as: type)
    }

    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else {
            let message = decodeErrorMessage(from: data) ?? HTTPURLResponse.localizedString(forStatusCode: (response as? HTTPURLResponse)?.statusCode ?? 500)
            throw APIClientError.badStatus((response as? HTTPURLResponse)?.statusCode ?? 500, message)
        }

        let decoder = JSONDecoder.sub2api

        if let envelope = try? decoder.decode(APIEnvelope<T>.self, from: data) {
            guard envelope.code == 0 else {
                throw APIClientError.serverMessage(envelope.message)
            }
            return envelope.data
        }

        if hasResponseCodeField(in: data) {
            let envelope = try decoder.decode(APIStatusEnvelope.self, from: data)
            guard envelope.code == 0 else {
                throw APIClientError.serverMessage(envelope.message)
            }
            guard hasResponseDataField(in: data) else {
                throw APIClientError.missingResponseData
            }

            return try decoder.decode(APIEnvelope<T>.self, from: data).data
        }

        return try decoder.decode(T.self, from: data)
    }

    private func decodeErrorMessage(from data: Data) -> String? {
        guard let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        if let message = payload["message"] as? String, !message.isEmpty {
            return message
        }

        if
            let detail = payload["detail"] as? [String: Any],
            let message = detail["message"] as? String,
            !message.isEmpty
        {
            return message
        }

        return nil
    }

    private func hasResponseCodeField(in data: Data) -> Bool {
        guard let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }

        return payload["code"] != nil
    }

    private func hasResponseDataField(in data: Data) -> Bool {
        guard let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }

        return payload.keys.contains("data")
    }
}

extension JSONDecoder {
    static var sub2api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)

            if let date = parseISO8601Date(stringValue, includingFractionalSeconds: true) {
                return date
            }

            if let date = parseISO8601Date(stringValue, includingFractionalSeconds: false) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported ISO8601 date: \(stringValue)"
            )
        }
        return decoder
    }
}

private func parseISO8601Date(_ stringValue: String, includingFractionalSeconds: Bool) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = includingFractionalSeconds
        ? [.withInternetDateTime, .withFractionalSeconds]
        : [.withInternetDateTime]
    return formatter.date(from: stringValue)
}
