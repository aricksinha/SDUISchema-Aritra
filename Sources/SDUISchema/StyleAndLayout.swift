import Foundation

/// Style is ALWAYS a reference to a token name, resolved later by
/// `SDUIDesignSystem`'s `Theme`. `SDUISchema` never carries a raw
/// color, font, or point value — that's the entire mechanism that
/// keeps the wire format decoupled from a specific design system's
/// concrete representation. A re-skin is a new `Theme`, never a
/// schema change.
///
/// Token names are an OPEN set (design systems grow new tokens
/// constantly) — that's why these are plain `String?`, not an enum.
/// An unresolvable token name is a `Theme`-layer concern (fall back
/// to a default), not a decode-time concern.
public struct StyleRef: Codable, Equatable {
    public let backgroundColorToken: String?
    public let textColorToken: String?
    public let fontToken: String?
    public let paddingToken: String?
    public let radiusToken: String?
    public let borderColorToken: String?

    public init(
        backgroundColorToken: String? = nil,
        textColorToken: String? = nil,
        fontToken: String? = nil,
        paddingToken: String? = nil,
        radiusToken: String? = nil,
        borderColorToken: String? = nil
    ) {
        self.backgroundColorToken = backgroundColorToken
        self.textColorToken = textColorToken
        self.fontToken = fontToken
        self.paddingToken = paddingToken
        self.radiusToken = radiusToken
        self.borderColorToken = borderColorToken
    }
}

/// Layout primitives are a CLOSED set, deliberately modeled as real
/// enums rather than raw strings. Direction/alignment don't grow the
/// way component types do — if a sixth stack direction is ever
/// needed, that's a genuine structural schema change and SHOULD
/// bump `structureVersion`, not silently decode as an unrecognized
/// string. This is the mirror image of `StyleRef`'s open-set
/// tokens: matching the Swift representation to how the underlying
/// set actually behaves, not defaulting everything to `String` for
/// convenience.
public struct Layout: Codable, Equatable {
    public enum Direction: String, Codable, Equatable {
        case horizontal, vertical, overlay
    }

    public enum Alignment: String, Codable, Equatable {
        case leading, center, trailing, top, bottom
    }

    public let direction: Direction
    public let alignment: Alignment?
    public let spacingToken: String?
    /// Relative sizing weight within a stack (flex-grow-style). Absent
    /// means "intrinsic size" — deliberately opt-in rather than a
    /// default of 0/1, so intrinsic sizing (the safer default under
    /// Dynamic Type) is what happens when the server says nothing.
    public let weight: Double?

    public init(
        direction: Direction,
        alignment: Alignment? = nil,
        spacingToken: String? = nil,
        weight: Double? = nil
    ) {
        self.direction = direction
        self.alignment = alignment
        self.spacingToken = spacingToken
        self.weight = weight
    }
}
