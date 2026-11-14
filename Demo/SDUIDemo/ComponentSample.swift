import Foundation

/// One entry in the left column: a component name and the wire JSON
/// that demonstrates it.
struct ComponentSample: Identifiable, Hashable {
    let id: String
    let title: String
    let json: String
}

struct SampleSection: Identifiable {
    let id: String
    let title: String
    let samples: [ComponentSample]
}
