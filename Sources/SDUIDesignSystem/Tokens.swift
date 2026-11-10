//
//  Tokens.swift
//
//
//  Created by Aritra on 10/11/26.
//

import Foundation

/// A typed reference to a named design token. `Category` exists
/// purely to prevent mixing token kinds at compile time
/// Ex - ** Token<ColorCategory> ** and a ** Token<FontCategory> ** are different
/// types even though both just wrap a `String` underneath
/// the resolution-layer mirror of `SDUISchema.StyleRef`: the schema
/// deliberately keeps token references as plain, open-vocabulary
/// strings on the wire (new tokens ship without a client release)
/// THIS layer is where that open string becomes something the
/// compiler can help you use correctly once you're past decode time.

/// ** Why its build this way **
/// - One generic Token<Category> instead of four separate structs. Same behavior (hashable, string-backed, literal-convertible) for every token kind, defined once. adding a fifth token category later (say, BorderWidthToken) is a one-line typealias
/// - Hashable is there deliberately, ahead of need — the next piece (the Theme resolver) wants a dictionary lookup cache keyed by token, and Hashable is what makes that free.
/// - Zero dependencies coz design system should be usable standalone, even by a team not using the rest of the SDK.
public struct Token<Category>: Hashable, RawRepresentable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// - ExpressibleByStringLiteral means call sites read exactly like the raw-string version (ColorToken("surfacePrimary") or even let token: ColorToken = "surfacePrimary")
extension Token: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
          self.rawValue = value
    }
}

extension Token: CustomStringConvertible {
    public var description: String { rawValue }
}

public enum ColorCategory {}
public enum FontCategory {}
public enum SpacingCategory {}
public enum RadiusCategory {}

public typealias ColorToken = Token<ColorCategory>
public typealias FontToken = Token<FontCategory>
public typealias SpacingToken = Token<SpacingCategory>
public typealias RadiusToken = Token<RadiusCategory>
