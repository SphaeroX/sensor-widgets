import AppIntents
import Foundation

public struct WidgetDefinitionEntity: AppEntity, Identifiable {
    public static var defaultQuery = WidgetDefinitionQuery()
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sensor Widget"

    public var id: String
    public var title: String
    public var typeName: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(typeName)"
        )
    }

    public init(id: String, title: String, typeName: String) {
        self.id = id
        self.title = title
        self.typeName = typeName
    }
}

public struct WidgetDefinitionQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [WidgetDefinitionEntity] {
        let all = SharedGroupStorage.shared.loadWidgetDefinitions()
        return all.filter { identifiers.contains($0.id) }.map {
            WidgetDefinitionEntity(id: $0.id, title: $0.title, typeName: $0.type.label)
        }
    }

    public func suggestedEntities() async throws -> [WidgetDefinitionEntity] {
        let all = SharedGroupStorage.shared.loadWidgetDefinitions()
        return all.map {
            WidgetDefinitionEntity(id: $0.id, title: $0.title, typeName: $0.type.label)
        }
    }

    public func defaultResult() async -> WidgetDefinitionEntity? {
        try? await suggestedEntities().first
    }
}

public struct SelectWidgetIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Select Sensor Widget"
    public static var description = IntentDescription("Choose which sensor widget to display.")

    @Parameter(title: "Widget")
    public var widget: WidgetDefinitionEntity?

    public init() {}

    public init(widget: WidgetDefinitionEntity?) {
        self.widget = widget
    }
}
