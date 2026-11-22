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
        ),
        SampleSection(
            id: "buttons",
            title: "Buttons",
            samples: [button, normalButton, iconButton]
        ),
        SampleSection(id: "images", title: "Images", samples: [image, standaloneImage]),
        SampleSection(id: "cards", title: "Cards", samples: [card, complexCards])
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

    private static let button = ComponentSample(
        id: "button",
        title: "Button showcase",
        json: #"""
        {
          "screenId": "button-basic",
          "structureVersion": 1,
          "root": {
            "id": "col", "type": "stack",
            "layout": { "direction": "vertical", "spacingToken": "spacingMd", "alignment": "leading" },
            "style": { "paddingToken": "spacingLg" },
            "children": [
              { "id": "t", "type": "text", "props": { "content": "Tap the button" } },
              { "id": "b", "type": "button", "actionId": "checkout", "props": { "title": "Checkout" } },
              {
                "id": "b-icon",
                "type": "button",
                "actionId": "addToCart",
                "props": { "title": "Add to cart", "systemImage": "cart.fill" }
              }
            ]
          }
        }
        """#
    )

    private static let normalButton = ComponentSample(
        id: "button-label",
        title: "Button properties",
        json: #"""
        {
          "screenId": "button-label",
          "structureVersion": 1,
          "root": {
            "id": "button",
            "type": "button",
            "actionId": "checkout",
            "props": { "title": "Checkout" }
          }
        }
        """#
    )

    private static let iconButton = ComponentSample(
        id: "button-icon",
        title: "Button with icon",
        json: #"""
        {
          "screenId": "button-icon",
          "structureVersion": 1,
          "root": {
            "id": "button",
            "type": "button",
            "actionId": "addToCart",
            "props": { "title": "Add to cart", "systemImage": "cart.fill" }
          }
        }
        """#
    )
    
    private static let image = ComponentSample(
        id: "image",
        title: "Image with caption",
        json: #"""
        {
          "screenId": "image-basic",
          "structureVersion": 1,
          "root": {
            "id": "card", "type": "stack",
            "layout": { "direction": "vertical", "spacingToken": "spacingMd" },
            "style": { "paddingToken": "spacingLg" },
            "children": [
              { "id": "hero", "type": "image",
                "props": { "url": "https://picsum.photos/600/400", "contentMode": "fill" } },
              { "id": "caption", "type": "text", "props": { "content": "Loaded from a server URL" } }
            ]
          }
        }
        """#
    )

    private static let standaloneImage = ComponentSample(
        id: "image-standalone",
        title: "Image",
        json: #"""
        {
          "screenId": "image-standalone",
          "structureVersion": 1,
          "root": {
            "id": "hero",
            "type": "image",
            "props": {
              "url": "https://picsum.photos/600/400",
              "contentMode": "fill"
            }
          }
        }
        """#
    )

    private static let card = ComponentSample(
        id: "card",
        title: "Card",
        json: #"""
        {
          "screenId": "card-basic",
          "structureVersion": 1,
          "root": {
            "id": "card", "type": "card", "actionId": "openProduct",
            "layout": { "direction": "vertical", "spacingToken": "spacingSm", "alignment": "leading" },
            "style": {
              "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingLg",
              "radiusToken": "radiusLg", "borderColorToken": "accent", "borderWidthToken": "borderThin"
            },
            "children": [
              { "id": "t", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "Tap to open the offer" } },
              { "id": "s", "type": "text", "props": { "content": "Tap the card content to see its action." } }
            ]
          }
        }
        """#
    )

    private static let complexCards = ComponentSample(
        id: "cards-showcase",
        title: "10 Complex Cards · Recursion",
        json: #"""
        {
          "screenId": "cards-showcase",
          "structureVersion": 1,
          "root": {
            "id": "showcase",
            "type": "stack",
            "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingLg" },
            "style": { "paddingToken": "spacingMd" },
            "children": [
              {
                "id": "trip-card",
                "type": "card",
                "actionId": "openTrip",
                "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
                "style": {
                  "backgroundColorToken": "surfaceSecondary",
                  "paddingToken": "spacingLg",
                  "radiusToken": "radiusLg",
                  "borderColorToken": "accent",
                  "borderWidthToken": "borderThin"
                },
                "children": [
                  {
                    "id": "trip-photo",
                    "type": "image",
                    "style": { "radiusToken": "radiusMd" },
                    "props": { "url": "https://picsum.photos/seed/coast-trip/720/360", "contentMode": "fill" }
                  },
                  {
                    "id": "trip-title",
                    "type": "text",
                    "style": { "fontToken": "titleLarge", "textColorToken": "textPrimary" },
                    "props": { "content": "Coastal escape", "numberOfLines": 1 }
                  },
                  {
                    "id": "trip-description",
                    "type": "text",
                    "style": { "textColorToken": "textSecondary" },
                    "props": { "content": "Three slow mornings by the sea, with breakfast included.", "numberOfLines": 2 }
                  },
                  {
                    "id": "trip-facts",
                    "type": "stack",
                    "layout": { "direction": "horizontal", "alignment": "center", "spacingToken": "spacingLg" },
                    "children": [
                      { "id": "trip-rating", "type": "text", "style": { "textColorToken": "accent" }, "props": { "content": "★ 4.9" } },
                      { "id": "trip-duration", "type": "text", "props": { "content": "3 nights" } },
                      { "id": "trip-price", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "$420" } }
                    ]
                  }
                ]
              },
              {
                "id": "profile-card",
                "type": "card",
                "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
                "style": { "backgroundColorToken": "surfacePrimary", "paddingToken": "spacingLg", "radiusToken": "radiusLg", "borderColorToken": "surfaceSecondary" },
                "children": [
                  { "id": "profile-title", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "Good morning, Maya" } },
                  { "id": "profile-subtitle", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "A little progress adds up." } },
                  {
                    "id": "profile-metrics",
                    "type": "stack",
                    "layout": { "direction": "horizontal", "alignment": "top", "spacingToken": "spacingMd" },
                    "children": [
                      {
                        "id": "streak-tile",
                        "type": "card",
                        "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingSm" },
                        "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                        "children": [
                          { "id": "streak-value", "type": "text", "style": { "fontToken": "titleLarge", "textColorToken": "accent" }, "props": { "content": "12 days" } },
                          { "id": "streak-label", "type": "text", "props": { "content": "Current streak" } }
                        ]
                      },
                      {
                        "id": "goal-tile",
                        "type": "card",
                        "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingSm" },
                        "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                        "children": [
                          { "id": "goal-value", "type": "text", "style": { "fontToken": "titleLarge", "textColorToken": "accent" }, "props": { "content": "8 / 10" } },
                          { "id": "goal-label", "type": "text", "props": { "content": "Weekly goal" } }
                        ]
                      }
                    ]
                  },
                  { "id": "profile-action", "type": "button", "actionId": "showMessage", "props": { "title": "View profile", "systemImage": "person.crop.circle" } }
                ]
              },
              {
                "id": "order-card",
                "type": "card",
                "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
                "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingLg", "radiusToken": "radiusLg" },
                "children": [
                  { "id": "order-title", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "Order summary" } },
                  {
                    "id": "order-coffee",
                    "type": "stack",
                    "layout": { "direction": "horizontal", "alignment": "center", "spacingToken": "spacingMd" },
                    "children": [
                      { "id": "coffee-name", "type": "text", "props": { "content": "House blend · 2 bags" } },
                      { "id": "coffee-price", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "$28.00" } }
                    ]
                  },
                  {
                    "id": "order-tea",
                    "type": "stack",
                    "layout": { "direction": "horizontal", "alignment": "center", "spacingToken": "spacingMd" },
                    "children": [
                      { "id": "tea-name", "type": "text", "props": { "content": "Jasmine tea · 1 tin" } },
                      { "id": "tea-price", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "$16.00" } }
                    ]
                  },
                  {
                    "id": "order-total",
                    "type": "card",
                    "layout": { "direction": "horizontal", "alignment": "center", "spacingToken": "spacingLg" },
                    "style": { "backgroundColorToken": "surfacePrimary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                    "children": [
                      { "id": "total-label", "type": "text", "props": { "content": "Total" } },
                      { "id": "total-value", "type": "text", "style": { "fontToken": "titleLarge", "textColorToken": "accent" }, "props": { "content": "$44.00" } }
                    ]
                  },
                  { "id": "order-action", "type": "button", "actionId": "checkout", "props": { "title": "Continue to checkout", "systemImage": "arrow.right" } }
                ]
              },
              {
                "id": "offer-card",
                "type": "card",
                "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
                "style": { "backgroundColorToken": "surfacePrimary", "paddingToken": "spacingLg", "radiusToken": "radiusLg", "borderColorToken": "accent", "borderWidthToken": "borderThick" },
                "children": [
                  {
                    "id": "offer-hero",
                    "type": "stack",
                    "layout": { "direction": "overlay", "alignment": "center" },
                    "children": [
                      { "id": "offer-image", "type": "image", "props": { "url": "https://picsum.photos/seed/weekend-offer/720/360", "contentMode": "fill" } },
                      { "id": "offer-badge", "type": "text", "style": { "fontToken": "titleLarge", "textColorToken": "accent", "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" }, "props": { "content": "WEEKEND · 25% OFF" } }
                    ]
                  },
                  { "id": "offer-title", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "A little more room to explore" } },
                  { "id": "offer-copy", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "Your next local escape is one tap away." } },
                  { "id": "offer-action", "type": "button", "actionId": "showMessage", "props": { "title": "See the offer", "systemImage": "sparkles" } }
                ]
              },
              {
                "id": "membership-card",
                "type": "card",
                "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
                "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingLg", "radiusToken": "radiusLg" },
                "children": [
                  { "id": "membership-heading", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "Your membership" } },
                  { "id": "membership-copy", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "One nested card, with its own independent action." } },
                  {
                    "id": "membership-inner-card",
                    "type": "card",
                    "actionId": "openMembership",
                    "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingSm" },
                    "style": { "backgroundColorToken": "surfacePrimary", "paddingToken": "spacingLg", "radiusToken": "radiusMd", "borderColorToken": "accent", "borderWidthToken": "borderThin" },
                    "children": [
                      { "id": "membership-tier", "type": "text", "style": { "fontToken": "titleLarge", "textColorToken": "accent" }, "props": { "content": "GOLD MEMBER" } },
                      { "id": "membership-detail", "type": "text", "props": { "content": "Renewal date · 18 June" } },
                      {
                        "id": "membership-benefits",
                        "type": "stack",
                        "layout": { "direction": "horizontal", "alignment": "center", "spacingToken": "spacingMd" },
                        "children": [
                          { "id": "benefit-one", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "Free delivery" } },
                          { "id": "benefit-two", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "Early access" } }
                        ]
                      }
                    ]
                  }
                ]
              },
              {
                "id": "itinerary-card",
                "type": "card",
                "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
                "style": { "backgroundColorToken": "surfacePrimary", "paddingToken": "spacingLg", "radiusToken": "radiusLg", "borderColorToken": "surfaceSecondary" },
                "children": [
                  { "id": "itinerary-title", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "Saturday itinerary" } },
                  {
                    "id": "itinerary-stops",
                    "type": "stack",
                    "layout": { "direction": "horizontal", "alignment": "top", "spacingToken": "spacingMd" },
                    "children": [
                      {
                        "id": "market-stop",
                        "type": "card",
                        "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingSm" },
                        "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                        "children": [
                          { "id": "market-time", "type": "text", "style": { "fontToken": "titleLarge", "textColorToken": "accent" }, "props": { "content": "9:30" } },
                          { "id": "market-name", "type": "text", "props": { "content": "Farmers market" } }
                        ]
                      },
                      {
                        "id": "gallery-stop",
                        "type": "card",
                        "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingSm" },
                        "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                        "children": [
                          { "id": "gallery-time", "type": "text", "style": { "fontToken": "titleLarge", "textColorToken": "accent" }, "props": { "content": "13:00" } },
                          { "id": "gallery-name", "type": "text", "props": { "content": "Modern art gallery" } }
                        ]
                      }
                    ]
                  },
                  { "id": "itinerary-action", "type": "button", "actionId": "showMessage", "props": { "title": "Open itinerary", "systemImage": "map" } }
                ]
              },
              {
                "id": "product-card",
                "type": "card",
                "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
                "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingLg", "radiusToken": "radiusLg", "borderColorToken": "accent", "borderWidthToken": "borderThin" },
                "children": [
                  { "id": "product-photo", "type": "image", "props": { "url": "https://picsum.photos/seed/ceramic-cup/720/360", "contentMode": "fit" } },
                  { "id": "product-title", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "Hand-thrown ceramic cup" } },
                  { "id": "product-copy", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "Made in small batches by local makers." } },
                  { "id": "product-action", "type": "button", "actionId": "addToCart", "props": { "title": "Add to cart", "systemImage": "cart.fill" } }
                ]
              },
              {
                "id": "stats-card",
                "type": "card",
                "actionId": "openStats",
                "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
                "style": { "backgroundColorToken": "surfacePrimary", "paddingToken": "spacingLg", "radiusToken": "radiusLg", "borderColorToken": "accent", "borderWidthToken": "borderThick" },
                "children": [
                  { "id": "stats-title", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "Your week at a glance" } },
                  {
                    "id": "stats-row",
                    "type": "stack",
                    "layout": { "direction": "horizontal", "alignment": "top", "spacingToken": "spacingSm" },
                    "children": [
                      {
                        "id": "stat-steps",
                        "type": "card",
                        "layout": { "direction": "vertical", "alignment": "center", "spacingToken": "spacingSm" },
                        "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                        "children": [
                          { "id": "steps-value", "type": "text", "style": { "fontToken": "titleLarge", "textColorToken": "accent" }, "props": { "content": "42k" } },
                          { "id": "steps-label", "type": "text", "props": { "content": "Steps" } }
                        ]
                      },
                      {
                        "id": "stat-focus",
                        "type": "card",
                        "layout": { "direction": "vertical", "alignment": "center", "spacingToken": "spacingSm" },
                        "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                        "children": [
                          { "id": "focus-value", "type": "text", "style": { "fontToken": "titleLarge", "textColorToken": "accent" }, "props": { "content": "6.5h" } },
                          { "id": "focus-label", "type": "text", "props": { "content": "Focus" } }
                        ]
                      },
                      {
                        "id": "stat-goals",
                        "type": "card",
                        "layout": { "direction": "vertical", "alignment": "center", "spacingToken": "spacingSm" },
                        "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                        "children": [
                          { "id": "goals-value", "type": "text", "style": { "fontToken": "titleLarge", "textColorToken": "accent" }, "props": { "content": "5 / 7" } },
                          { "id": "goals-label", "type": "text", "props": { "content": "Goals" } }
                        ]
                      }
                    ]
                  },
                  { "id": "stats-hint", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "Tap this entire card to open the report." } }
                ]
              },
              {
                "id": "notification-card",
                "type": "card",
                "actionId": "openNotifications",
                "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
                "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingLg", "radiusToken": "radiusLg" },
                "children": [
                  { "id": "notification-title", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "A few things need you" } },
                  {
                    "id": "notification-list",
                    "type": "stack",
                    "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingSm" },
                    "children": [
                      {
                        "id": "notification-shipping",
                        "type": "card",
                        "layout": { "direction": "horizontal", "alignment": "center", "spacingToken": "spacingMd" },
                        "style": { "backgroundColorToken": "surfacePrimary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                        "children": [
                          { "id": "shipping-mark", "type": "text", "style": { "textColorToken": "accent" }, "props": { "content": "●" } },
                          { "id": "shipping-copy", "type": "text", "props": { "content": "Your parcel is out for delivery." } }
                        ]
                      },
                      {
                        "id": "notification-reminder",
                        "type": "card",
                        "layout": { "direction": "horizontal", "alignment": "center", "spacingToken": "spacingMd" },
                        "style": { "backgroundColorToken": "surfacePrimary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                        "children": [
                          { "id": "reminder-mark", "type": "text", "style": { "textColorToken": "accent" }, "props": { "content": "●" } },
                          { "id": "reminder-copy", "type": "text", "props": { "content": "Your weekly plan is ready to review." } }
                        ]
                      }
                    ]
                  },
                  { "id": "notification-hint", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "Tap to see all notifications." } }
                ]
              },
              {
                "id": "payment-card",
                "type": "card",
                "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingMd" },
                "style": { "backgroundColorToken": "surfacePrimary", "paddingToken": "spacingLg", "radiusToken": "radiusLg", "borderColorToken": "surfaceSecondary", "borderWidthToken": "borderThin" },
                "children": [
                  { "id": "payment-title", "type": "text", "style": { "fontToken": "titleLarge" }, "props": { "content": "Ready when you are" } },
                  { "id": "payment-copy", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "Review your delivery and payment details before placing the order." } },
                  {
                    "id": "payment-details",
                    "type": "card",
                    "layout": { "direction": "vertical", "alignment": "leading", "spacingToken": "spacingSm" },
                    "style": { "backgroundColorToken": "surfaceSecondary", "paddingToken": "spacingMd", "radiusToken": "radiusMd" },
                    "children": [
                      {
                        "id": "payment-address",
                        "type": "stack",
                        "layout": { "direction": "horizontal", "alignment": "center", "spacingToken": "spacingMd" },
                        "children": [
                          { "id": "address-label", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "Deliver to" } },
                          { "id": "address-value", "type": "text", "props": { "content": "Maya · 24 Oak Street" } }
                        ]
                      },
                      {
                        "id": "payment-method",
                        "type": "stack",
                        "layout": { "direction": "horizontal", "alignment": "center", "spacingToken": "spacingMd" },
                        "children": [
                          { "id": "method-label", "type": "text", "style": { "textColorToken": "textSecondary" }, "props": { "content": "Payment" } },
                          { "id": "method-value", "type": "text", "props": { "content": "•••• 2048" } }
                        ]
                      }
                    ]
                  },
                  { "id": "payment-action", "type": "button", "actionId": "checkout", "props": { "title": "Place order", "systemImage": "lock.fill" } }
                ]
              }
            ]
          }
        }
        """#
    )
}
