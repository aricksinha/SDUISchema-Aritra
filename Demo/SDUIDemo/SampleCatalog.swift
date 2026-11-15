import Foundation

/// The demo's content, as plain data. Each renderer we build adds
/// its samples here and nothing else changes.
enum SampleCatalog {
    static let sections: [SampleSection] = [
        SampleSection(id: "text", title: "Text", samples: [text, textBoxed]),
        SampleSection(
            id: "stacks",
            title: "Stacks",
            samples: [verticalStack, horizontalStack, nestedStack]
        )
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

    private static let textBoxed = ComponentSample(
        id: "text-boxed",
        title: "Text with Box Style",
        json: #"""
        {
          "screenId": "text-boxed",
          "structureVersion": 1,
          "root": {
            "id": "title",
            "type": "text",
            "style": {
              "textColorToken": "accent",
              "fontToken": "titleLarge",
              "backgroundColorToken": "surfaceSecondary",
              "paddingToken": "spacingLg",
              "radiusToken": "radiusMd",
              "borderColorToken": "accent"
            },
            "props": { "content": "Hello from the server", "numberOfLines": 2 }
          }
        }
        """#
    )

    private static let verticalStack = ComponentSample(
        id: "stack-vertical",
        title: "Stack · vertical",
        json: #"""
        {
          "screenId": "stack-vertical",
          "structureVersion": 1,
          "root": {
            "id": "root", "type": "stack",
            "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
            "children": [
              { "id": "a", "type": "text", "props": { "content": "First" } },
              { "id": "b", "type": "text", "props": { "content": "Second" } },
              { "id": "c", "type": "text", "props": { "content": "Third" } }
            ]
          }
        }
        """#
    )

    private static let horizontalStack = ComponentSample(
        id: "stack-horizontal",
        title: "Stack · horizontal",
        json: #"""
        {
          "screenId": "stack-horizontal",
          "structureVersion": 1,
          "root": {
            "id": "root", "type": "stack",
            "layout": { "direction": "horizontal", "alignment": "center", "spacingToken": "spacingLg" },
            "children": [
              { "id": "a", "type": "text", "props": { "content": "Left" } },
              { "id": "b", "type": "text", "props": { "content": "Mid" } },
              { "id": "c", "type": "text", "props": { "content": "Right" } }
            ]
          }
        }
        """#
    )

    private static let nestedStack = ComponentSample(
        id: "stack-nested",
        title: "Stack · nested",
        json: #"""
        {
          "screenId": "stack-nested",
          "structureVersion": 1,
          "root": {
            "id": "outer", "type": "stack",
            "layout": { "direction": "vertical", "spacingToken": "spacingLg" },
            "children": [
              { "id": "heading", "type": "text",
                "style": { "fontToken": "titleLarge", "textColorToken": "accent" },
                "props": { "content": "Nested rows" } },
              { "id": "row1", "type": "stack",
                "layout": { "direction": "horizontal", "spacingToken": "spacingMd" },
                "children": [
                  { "id": "r1a", "type": "text", "props": { "content": "A" } },
                  { "id": "r1b", "type": "text", "props": { "content": "B" } }
                ] }
            ]
          }
        }
        """#
    )
}
