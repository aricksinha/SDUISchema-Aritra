import Foundation

/// The demo's content, as plain data. Each renderer we build adds
/// its samples here and nothing else changes.
enum SampleCatalog {
    static let sections: [SampleSection] = [
        SampleSection(id: "components", title: "Components", samples: [text])
    ]

    static var all: [ComponentSample] { sections.flatMap(\.samples) }

    static func sample(id: ComponentSample.ID?) -> ComponentSample? {
        all.first { $0.id == id }
    }

    private static let text = ComponentSample(
        id: "text",
        title: "Text",
        json: #"""
        {
          "screenId": "text-basic",
          "structureVersion": 1,
          "root": {
            "id": "title",
            "type": "text",
            "style": { "textColorToken": "accent", "fontToken": "titleLarge" },
            "props": { "content": "Hello from the server", "numberOfLines": 2 }
          }
        }
        """#
    )
}
