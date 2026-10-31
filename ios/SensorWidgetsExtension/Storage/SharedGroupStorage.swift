import Foundation
import Security

public struct CachedSensorData: Codable, Equatable {
    public let singleValue: Double?
    public let series: [SensorDataPoint]?
    public let multiValues: [String: Double]?
    public let aggregate: [String: Double]?
    public let lastUpdated: Date
    public let errorMessage: String?

    public init(
        singleValue: Double? = nil,
        series: [SensorDataPoint]? = nil,
        multiValues: [String: Double]? = nil,
        aggregate: [String: Double]? = nil,
        lastUpdated: Date = Date(),
        errorMessage: String? = nil
    ) {
        self.singleValue = singleValue
        self.series = series
        self.multiValues = multiValues
        self.aggregate = aggregate
        self.lastUpdated = lastUpdated
        self.errorMessage = errorMessage
    }
}

public final class SharedGroupStorage {
    public static let shared = SharedGroupStorage()

    public let appGroupId: String
    private let userDefaults: UserDefaults?

    public init(appGroupId: String = "group.io.github.mgasc.influx_sensor_widgets") {
        self.appGroupId = appGroupId
        self.userDefaults = UserDefaults(suiteName: appGroupId)
    }

    // MARK: - Widget Definitions

    public func loadWidgetDefinitions() -> [WidgetDefinition] {
        guard let jsonString = userDefaults?.string(forKey: "widget_definitions_v1"),
              let data = jsonString.data(using: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(WidgetDefinitionsEnvelope.self, data: data) {
            return envelope.widgets
        } else if let array = try? decoder.decode([WidgetDefinition].self, data: data) {
            return array
        }
        return []
    }

    public func loadWidgetDefinition(id: String) -> WidgetDefinition? {
        loadWidgetDefinitions().first { $0.id == id }
    }

    // MARK: - Connections Metadata

    public func loadConnections() -> [InfluxConnection] {
        guard let jsonString = userDefaults?.string(forKey: "connections_metadata_v1"),
              let data = jsonString.data(using: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        return (try? decoder.decode([InfluxConnection].self, data: data)) ?? []
    }

    public func loadConnection(id: String) -> InfluxConnection? {
        loadConnections().first { $0.id == id }
    }

    // MARK: - Secure Token (Keychain)

    public func loadToken(connectionId: String) -> String? {
        let key = "influx_token_\(connectionId)"

        // Query Keychain with App Group Access Group
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        #if !targetEnvironment(simulator)
        query[kSecAttrAccessGroup as String] = appGroupId
        #endif

        var item: CFTypeRef?
        var status = SecItemCopyMatching(query as CFDictionary, &item)

        // Fallback without access group if group query fails (e.g. simulator/dev)
        if status != errSecSuccess {
            query.removeValue(forKey: kSecAttrAccessGroup as String)
            status = SecItemCopyMatching(query as CFDictionary, &item)
        }

        if status == errSecSuccess, let data = item as? Data, let token = String(data: data, encoding: .utf8) {
            return token
        }

        return nil
    }

    // MARK: - Cache

    public func loadCachedData(widgetId: String) -> CachedSensorData? {
        guard let data = userDefaults?.data(forKey: "widget_cache_\(widgetId)") else {
            return nil
        }
        return try? JSONDecoder().decode(CachedSensorData.self, data: data)
    }

    public func saveCachedData(widgetId: String, data: CachedSensorData) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults?.set(encoded, forKey: "widget_cache_\(widgetId)")
        }
    }
}
