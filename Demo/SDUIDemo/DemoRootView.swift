import SwiftUI
import UIKit
import Foundation
import SDUISchema
import SDUIDesignSystem
import SDUIRendering

private enum DemoEnvironment: String, CaseIterable, Identifiable {
    case production
    case debug

    var id: String { rawValue }
    var title: String { self == .production ? "Production" : "Debug" }
    var showsDiagnostics: Bool { self == .debug }

    static var initial: DemoEnvironment {
        #if DEBUG
        .debug
        #else
        .production
        #endif
    }
}

struct DemoRootView: View {
    @State private var selection: ComponentSample.ID? = SampleCatalog.all.first?.id
    @State private var jsonText = SampleCatalog.all.first?.json ?? ""
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var environment = DemoEnvironment.initial
    @State private var showingActionAlert = false
    @State private var buttonActionMessage = ""
    @State private var cartItemCount = 0

    private let theme = DemoCompositionRoot.makeTheme()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SampleListColumn(sections: SampleCatalog.sections, selection: $selection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } content: {
            PreviewColumn(
                sample: SampleCatalog.sample(id: selection),
                json: $jsonText,
                theme: theme,
                environment: $environment,
                registry: DemoCompositionRoot.makeRegistry(
                    showsDiagnostics: environment.showsDiagnostics,
                    onButtonAction: handleButtonAction
                )
            )
                .navigationSplitViewColumnWidth(min: 320, ideal: 420, max: 600)
        } detail: {
            JSONColumn(json: $jsonText, sampleID: selection)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selection) { newSelection in
            jsonText = SampleCatalog.sample(id: newSelection)?.json ?? ""
        }
        .alert("Demo action", isPresented: $showingActionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(buttonActionMessage)
        }
    }

    private func handleButtonAction(_ actionID: String) {
        switch DemoButtonAction(rawValue: actionID) {
        case .some(.checkout):
            buttonActionMessage = "Checkout requested. No payment is processed in this demo."
        case .some(.addToCart):
            cartItemCount += 1
            let itemLabel = cartItemCount == 1 ? "item" : "items"
            buttonActionMessage = "Added to cart. Cart now contains \(cartItemCount) \(itemLabel)."
        case .some(.showMessage):
            buttonActionMessage = "The demo action ran successfully."
        case .none:
            buttonActionMessage = "The demo received the custom action: \(actionID)."
        }
        showingActionAlert = true
    }
}

private struct SampleListColumn: View {
    let sections: [SampleSection]
    @Binding var selection: ComponentSample.ID?

    var body: some View {
        List(selection: $selection) {
            ForEach(sections) { section in
                Section(section.title) {
                    ForEach(section.samples) { sample in
                        Text(sample.title).tag(sample.id)
                    }
                }
            }
        }
        .navigationTitle("Components")
    }
}

private struct PreviewColumn: View {
    let sample: ComponentSample?
    @Binding var json: String
    let theme: Theme
    @Binding var environment: DemoEnvironment
    let registry: RendererRegistry

    @State private var isShowingPropertiesEditor = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Environment")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Environment", selection: $environment) {
                    ForEach(DemoEnvironment.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Preview environment")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                Group {
                    switch previewState {
                    case .noSelection:
                        Text("Select a sample to preview.")
                            .foregroundStyle(.secondary)
                    case .invalid(let diagnostic):
                        if environment.showsDiagnostics {
                            diagnosticView([diagnostic])
                        } else {
                            productionPlaceholder
                        }
                    case .ready(let screen, let issues):
                        VStack(alignment: .leading, spacing: 12) {
                            if !issues.isEmpty {
                                issueSummary(issues)
                            }
                            SDUIView(screen: screen, theme: theme, registry: registry)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Preview")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit Properties") {
                    isShowingPropertiesEditor = true
                }
                .disabled(!canEditProperties)
            }
        }
        .sheet(isPresented: $isShowingPropertiesEditor) {
            if let screen = decode(json) {
                DemoPropertiesEditor.make(for: screen.root.type, json: json) { updatedJSON in
                    json = updatedJSON
                }
            }
        }
    }

    private var previewState: DemoPreviewState {
        guard sample != nil else { return .noSelection }

        let reporter = DemoDecodeFailureCollector()
        let decoder = JSONDecoder()
        decoder.userInfo[.decodeFailureReporter] = reporter

        do {
            let screen = try decoder.decode(Screen.self, from: Data(json.utf8))
            let scan = Self.renderingDiagnostics(in: screen.root, json: json, registry: registry)
            let decodeIssues = reporter.failures.compactMap { failure -> DemoDiagnostic? in
                guard !scan.failedNodeDecodes.contains(failure) else { return nil }
                let basePath = failure.nodeID.flatMap { scan.nodePaths[$0] } ?? "$.root"
                let field = Self.fieldName(in: failure.reason)
                let location = field.map { "\(basePath).\($0)" } ?? basePath
                if scan.issues.contains(where: {
                    $0.location == location || $0.location.hasPrefix(location + ".")
                }) {
                    return nil
                }
                return DemoDiagnostic(
                    category: "Invalid node data",
                    location: location,
                    nodeID: failure.nodeID,
                    nodeType: failure.nodeType,
                    cause: failure.reason,
                    resolution: Self.resolution(forDecodedField: field)
                )
            }
            let issues = Self.unique(scan.issues + decodeIssues)
            return .ready(screen, issues)
        } catch {
            return .invalid(Self.describe(error))
        }
    }

    private var canEditProperties: Bool {
        guard let screen = decode(json) else { return false }
        return DemoPropertiesEditor.supports(screen.root.type)
    }

    private func decode(_ json: String) -> Screen? {
        try? JSONDecoder().decode(Screen.self, from: Data(json.utf8))
    }

    @ViewBuilder
    private var productionPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
            Text("This UI is unavailable.")
                .font(.headline)
            Text("Check the screen configuration and try again.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    @ViewBuilder
    private func issueSummary(_ issues: [DemoDiagnostic]) -> some View {
        if environment.showsDiagnostics {
            diagnosticView(issues)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                Text("Some content is unavailable.")
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func diagnosticView(_ issues: [DemoDiagnostic]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("UI diagnostics (\(issues.count))", systemImage: "ladybug")
                .font(.headline)
            ForEach(issues) { issue in
                VStack(alignment: .leading, spacing: 8) {
                    Text(issue.category)
                        .font(.subheadline.weight(.semibold))
                    diagnosticField("JSON location", issue.location)
                    if let nodeID = issue.nodeID {
                        diagnosticField("Node", "\(nodeTypeLabel(issue.nodeType)) · \(nodeID)")
                    }
                    diagnosticField("Why this happened", issue.cause)
                    diagnosticField("Resolution", issue.resolution)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .padding()
    }

    private func diagnosticField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func nodeTypeLabel(_ nodeType: String?) -> String {
        nodeType ?? "unknown type"
    }

    private static func renderingDiagnostics(
        in root: Node,
        json: String,
        registry: RendererRegistry
    ) -> DiagnosticScan {
        var issues: [DemoDiagnostic] = []
        var nodePaths: [String: String] = [:]
        var failedNodeDecodes: [DecodeFailure] = []

        func add(
            _ category: String,
            _ location: String,
            _ node: Node,
            _ cause: String,
            _ resolution: String
        ) {
            issues.append(
                DemoDiagnostic(
                    category: category,
                    location: location,
                    nodeID: node.id,
                    nodeType: node.type,
                    cause: cause,
                    resolution: resolution
                )
            )
        }

        func rawFieldDiagnostics(in json: String) -> [DemoDiagnostic] {
            guard let data = json.data(using: .utf8),
                  let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let root = object["root"] as? [String: Any] else {
                return []
            }

            var issues: [DemoDiagnostic] = []

            func add(
                _ category: String,
                _ location: String,
                _ node: [String: Any],
                _ cause: String,
                _ resolution: String
            ) {
                issues.append(
                    DemoDiagnostic(
                        category: category,
                        location: location,
                        nodeID: node["id"] as? String,
                        nodeType: node["type"] as? String,
                        cause: cause,
                        resolution: resolution
                    )
                )
            }

            func inspect(_ value: Any, at location: String) {
                guard let node = value as? [String: Any] else { return }

                if let rawActionID = node["actionId"], !(rawActionID is String) {
                    add(
                        "Action ID has the wrong type",
                        "\(location).actionId",
                        node,
                        "Node decoding silently drops actionId because it is not a string, so the intended action cannot run.",
                        "Set actionId to a string such as \"checkout\", \"addToCart\", or \"showMessage\"."
                    )
                }

                if let rawBinding = node["dataBinding"], !(rawBinding is String) {
                    add(
                        "Data binding has the wrong type",
                        "\(location).dataBinding",
                        node,
                        "Node decoding silently drops dataBinding because it is not a string.",
                        "Set dataBinding to a string path, or remove it. Note that this demo does not yet resolve data-binding paths."
                    )
                }

                if let rawLayout = node["layout"] {
                    if let layout = rawLayout as? [String: Any] {
                        if let rawDirection = layout["direction"] {
                            if let direction = rawDirection as? String {
                                if !["vertical", "horizontal", "overlay"].contains(direction) {
                                    add(
                                        "Layout direction is unsupported",
                                        "\(location).layout.direction",
                                        node,
                                        "The schema accepts only vertical, horizontal, and overlay. An invalid direction causes the entire optional layout to be discarded.",
                                        "Replace '\(direction)' with \"vertical\", \"horizontal\", or \"overlay\"."
                                    )
                                }
                            } else {
                                add(
                                    "Layout direction has the wrong type",
                                    "\(location).layout.direction",
                                    node,
                                    "Layout.direction must be a string; otherwise the decoder discards the entire layout.",
                                    "Use a quoted string: \"vertical\", \"horizontal\", or \"overlay\"."
                                )
                            }
                        } else {
                            add(
                                "Layout direction is missing",
                                "\(location).layout.direction",
                                node,
                                "Direction is required whenever a layout object is present. The decoder discards the entire layout when it is missing.",
                                "Add direction with exactly one of: \"vertical\", \"horizontal\", or \"overlay\"."
                            )
                        }

                        if let rawAlignment = layout["alignment"] {
                            if let alignment = rawAlignment as? String {
                                if !["leading", "center", "trailing", "top", "bottom"].contains(alignment) {
                                    add(
                                        "Layout alignment is unsupported",
                                        "\(location).layout.alignment",
                                        node,
                                        "The schema does not recognize '\(alignment)', so it discards the entire layout.",
                                        "Use one of: \"leading\", \"center\", \"trailing\", \"top\", or \"bottom\"."
                                    )
                                }
                            } else {
                                add(
                                    "Layout alignment has the wrong type",
                                    "\(location).layout.alignment",
                                    node,
                                    "Layout.alignment must be a string enum value.",
                                    "Use a quoted alignment value: \"leading\", \"center\", \"trailing\", \"top\", or \"bottom\"."
                                )
                            }
                        }

                        if let rawSpacing = layout["spacingToken"], !(rawSpacing is String) {
                            add(
                                "Spacing token has the wrong type",
                                "\(location).layout.spacingToken",
                                node,
                                "spacingToken is a string reference; a non-string value makes the entire layout fail decoding.",
                                "Use a quoted token name such as \"spacingMd\", or remove spacingToken."
                            )
                        }
                    } else {
                        add(
                            "Layout must be an object",
                            "\(location).layout",
                            node,
                            "Layout decoding fails as a whole when its value is not an object.",
                            "Replace layout with an object containing a direction, for example { \"direction\": \"vertical\" }."
                        )
                    }
                }

                if let rawStyle = node["style"] {
                    if let style = rawStyle as? [String: Any] {
                        let styleFields = [
                            "backgroundColorToken", "textColorToken", "fontToken",
                            "paddingToken", "radiusToken", "borderColorToken", "borderWidthToken"
                        ]
                        for field in styleFields {
                            if let value = style[field], !(value is String) {
                                add(
                                    "Style token has the wrong type",
                                    "\(location).style.\(field)",
                                    node,
                                    "\(field) must be a string token reference. A non-string value causes the whole style object to be discarded.",
                                    "Replace this value with a quoted token name from the demo theme, or remove the property."
                                )
                            }
                        }
                    } else {
                        add(
                            "Style must be an object",
                            "\(location).style",
                            node,
                            "Style decoding fails as a whole when its value is not an object.",
                            "Replace style with an object whose values are design-token strings, or remove style."
                        )
                    }
                }

                if let children = node["children"] as? [Any] {
                    for (index, child) in children.enumerated() {
                        inspect(child, at: "\(location).children[\(index)]")
                    }
                }
            }

            inspect(root, at: "$.root")
            return issues
        }

        func visit(_ node: Node, at location: String) {
            nodePaths[node.id] = location

            if !registry.isRegistered(node.type) {
                let registeredTypes = DemoComponentType.allCases
                    .map(\.rawValue)
                    .sorted()
                    .joined(separator: ", ")
                add(
                    "No renderer is registered",
                    "\(location).type",
                    node,
                    "The schema decoded successfully, but the demo registry has no renderer for '\(node.type)'. This node renders as an unsupported placeholder in Debug and disappears in Production.",
                    "Register a renderer for '\(node.type)' in DemoComponentType.register, or change this value to a supported type: \(registeredTypes)."
                )
            }

            if node.type == "text", node.props?["content"]?.stringValue == nil {
                add(
                    "Text has no content",
                    "\(location).props.content",
                    node,
                    "TextNodeRenderer returns EmptyView when props.content is missing or is not a string.",
                    "Add a string value, for example \"props\": { \"content\": \"Your text\" }. Keep numberOfLines optional."
                )
            }

            if node.type == "text", let props = node.props,
               let rawLineLimit = props["numberOfLines"] {
                let lineLimit = rawLineLimit.numberValue
                let isValidLineLimit = lineLimit.map {
                    $0.isFinite && $0 >= 1 && $0.rounded(.towardZero) == $0
                } ?? false
                if !isValidLineLimit {
                    add(
                        "Text line limit is invalid",
                        "\(location).props.numberOfLines",
                        node,
                        "TextNodeRenderer accepts only positive whole-number line limits; this value is ignored.",
                        "Set numberOfLines to a positive integer such as 1 or 2, or remove the property to allow unlimited lines."
                    )
                }
            }

            if node.type == "image" {
                let rawURL = node.props?["url"]?.stringValue
                let components = rawURL.flatMap(URLComponents.init(string:))
                let scheme = components?.scheme?.lowercased()
                if components?.host == nil || (scheme != "http" && scheme != "https") {
                    add(
                        "Image URL is invalid",
                        "\(location).props.url",
                        node,
                        "ImageNodeRenderer returns EmptyView unless url parses as an absolute URL. The demo image provider expects an http or https URL with a host.",
                        "Set props.url to a reachable absolute URL such as \"https://example.com/image.jpg\". If the URL is valid but the image still fails, verify network access and that the server returns image data."
                    )
                }
                if let contentMode = node.props?["contentMode"]?.stringValue,
                   contentMode != "fit", contentMode != "fill" {
                    add(
                        "Image content mode is unsupported",
                        "\(location).props.contentMode",
                        node,
                        "The image renderer recognizes only 'fit' and 'fill'; an unknown value silently falls back to fit.",
                        "Use \"fit\" to show the full image or \"fill\" to crop it to the available bounds."
                    )
                }
            }

            if node.type == "button", node.actionID == nil {
                add(
                    "Button has no action",
                    "\(location).actionId",
                    node,
                    "Without actionId, the demo renders the button label as a non-interactive view.",
                    "Add an actionId handled by the demo, such as \"checkout\", \"addToCart\", or \"showMessage\". Custom IDs are also accepted and shown as demo feedback."
                )
            }

            if let layout = node.layout {
                if let alignment = layout.alignment {
                    let isAxisCompatible: Bool
                    switch layout.direction {
                    case .vertical:
                        isAxisCompatible = alignment == .leading || alignment == .center || alignment == .trailing
                    case .horizontal:
                        isAxisCompatible = alignment == .top || alignment == .center || alignment == .bottom
                    case .overlay:
                        isAxisCompatible = true
                    }
                    if !isAxisCompatible {
                        let allowed = layout.direction == .vertical
                            ? "leading, center, trailing"
                            : "top, center, bottom"
                        add(
                            "Alignment does not match stack direction",
                            "\(location).layout.alignment",
                            node,
                            "The renderer maps '\(alignment.rawValue)' to center for a \(layout.direction.rawValue) stack, so the requested alignment is not applied.",
                            "For a \(layout.direction.rawValue) stack, choose one of: \(allowed)."
                        )
                    }
                }

                if layout.weight != nil {
                    add(
                        "Layout weight is not applied",
                        "\(location).layout.weight",
                        node,
                        "The schema decodes weight, but StackNodeRenderer currently lays out children without consuming it.",
                        "Remove layout.weight or implement weight-aware sizing in the renderer before relying on it."
                    )
                }

                if let token = layout.spacingToken {
                    if let issue = Self.addTokenIssue(
                        token,
                        field: "spacingToken",
                        location: "\(location).layout.spacingToken",
                        node: node,
                        supported: Self.spacingTokens,
                        fallback: "spacing resolves to 0"
                    ) {
                        issues.append(issue)
                    }
                }
            }

            if let style = node.style {
                let tokenIssues: [(String, String?, Set<String>, String)] = [
                    ("backgroundColorToken", style.backgroundColorToken, Self.colorTokens, "background resolves to clear"),
                    ("textColorToken", style.textColorToken, Self.colorTokens, "text color resolves to clear"),
                    ("borderColorToken", style.borderColorToken, Self.colorTokens, "border color resolves to clear"),
                    ("fontToken", style.fontToken, Self.fontTokens, "font falls back to body"),
                    ("paddingToken", style.paddingToken, Self.spacingTokens, "padding resolves to 0"),
                    ("radiusToken", style.radiusToken, Self.radiusTokens, "corner radius resolves to 0"),
                    ("borderWidthToken", style.borderWidthToken, Self.borderWidthTokens, "border width resolves to 0")
                ]
                for (field, token, supported, fallback) in tokenIssues {
                    guard let token else { continue }
                    if let issue = Self.addTokenIssue(
                        token,
                        field: field,
                        location: "\(location).style.\(field)",
                        node: node,
                        supported: supported,
                        fallback: fallback
                    ) {
                        issues.append(issue)
                    }
                }
            }

            if node.dataBinding != nil {
                add(
                    "Data binding is not resolved by the demo",
                    "\(location).dataBinding",
                    node,
                    "The schema stores dataBinding, but the current demo rendering context does not resolve data paths.",
                    "Provide concrete values in props for this demo, or add a data-binding resolver before using this field."
                )
            }

            if node.accessibility != nil {
                add(
                    "Accessibility metadata is not applied",
                    "\(location).accessibility",
                    node,
                    "The schema decodes accessibility metadata, but the current rendering pipeline does not yet apply it as SwiftUI accessibility modifiers.",
                    "Do not rely on this metadata for VoiceOver behavior until an accessibility decorator is wired into NodeViewFactory."
                )
            }

            if node.analytics != nil {
                add(
                    "Analytics metadata is not applied",
                    "\(location).analytics",
                    node,
                    "The schema decodes analytics metadata, but no analytics decorator is currently wired into the demo renderer.",
                    "Use the demo's explicit action callback for observable interactions, or add an analytics decorator before relying on this field."
                )
            }

            var childIDLocations: [String: String] = [:]
            for (index, child) in node.children.enumerated() {
                let childLocation = "\(location).children[\(index)]"
                switch child {
                case .node(let childNode):
                    if let previousLocation = childIDLocations.updateValue(childLocation, forKey: childNode.id) {
                        issues.append(
                            DemoDiagnostic(
                                category: "Sibling node IDs are duplicated",
                                location: "\(childLocation).id",
                                nodeID: childNode.id,
                                nodeType: childNode.type,
                                cause: "This ID is already used by a sibling at \(previousLocation). The stack renderer uses child IDs as SwiftUI identity, so duplicates can cause the wrong view to be reused or updated.",
                                resolution: "Give this node a unique id within its parent's children array, then update any references to that id."
                            )
                        )
                    }
                    visit(childNode, at: childLocation)
                case .failed(let failure):
                    failedNodeDecodes.append(failure)
                    issues.append(
                        DemoDiagnostic(
                            category: "Child node was quarantined",
                            location: childLocation,
                            nodeID: failure.nodeID,
                            nodeType: failure.nodeType,
                            cause: failure.reason,
                            resolution: "Correct this child object at \(childLocation). A node must have string id and type fields; ensure optional style, layout, props, and metadata fields match their schemas. The decoder skipped this child but kept its siblings."
                        )
                    )
                }
            }
        }

        visit(root, at: "$.root")
        return DiagnosticScan(
            issues: Self.unique(rawFieldDiagnostics(in: json) + issues),
            nodePaths: nodePaths,
            failedNodeDecodes: failedNodeDecodes
        )
    }

    private static let colorTokens: Set<String> = [
        "accent", "surfacePrimary", "surfaceSecondary", "textPrimary", "textSecondary"
    ]
    private static let fontTokens: Set<String> = ["titleLarge", "body", "caption"]
    private static let spacingTokens: Set<String> = ["spacingSm", "spacingMd", "spacingLg"]
    private static let radiusTokens: Set<String> = ["radiusSm", "radiusMd", "radiusLg"]
    private static let borderWidthTokens: Set<String> = ["borderThin", "borderThick"]

    private static func addTokenIssue(
        _ token: String,
        field: String,
        location: String,
        node: Node,
        supported: Set<String>,
        fallback: String
    ) -> DemoDiagnostic? {
        guard !supported.contains(token) else { return nil }
        let validTokens = supported.sorted().map { "\"\($0)\"" }.joined(separator: ", ")
        return DemoDiagnostic(
            category: "Design token is not in the demo theme",
            location: location,
            nodeID: node.id,
            nodeType: node.type,
            cause: "\(field) references '\(token)', which is not defined by the demo theme; \(fallback).",
            resolution: "Replace '\(token)' with one of \(validTokens), or define it in the theme returned by DemoCompositionRoot.makeTheme() (currently StaticTheme.placeholder)."
        )
    }

    private static func describe(_ error: Error) -> DemoDiagnostic {
        guard let error = error as? DecodingError else {
            return DemoDiagnostic(
                category: "Screen could not be decoded",
                location: "$",
                cause: error.localizedDescription,
                resolution: "Verify that the edited JSON is valid and that the top-level object contains screenId, structureVersion, and root."
            )
        }

        switch error {
        case .keyNotFound(let key, let context):
            let location = path(context.codingPath + [key])
            return DemoDiagnostic(
                category: "Required JSON field is missing",
                location: location,
                cause: context.debugDescription,
                resolution: resolutionForMissingKey(key.stringValue, location: location)
            )
        case .typeMismatch(let type, let context):
            let location = path(context.codingPath)
            return DemoDiagnostic(
                category: "JSON value has the wrong type",
                location: location,
                cause: "\(context.debugDescription) Expected \(type).",
                resolution: "Change the value at \(location) to the expected JSON type. IDs, component types, screenId, actionId, and token references must be strings; structureVersion must be an integer."
            )
        case .valueNotFound(let type, let context):
            let location = path(context.codingPath)
            return DemoDiagnostic(
                category: "Required JSON value is missing",
                location: location,
                cause: "\(context.debugDescription) Expected \(type).",
                resolution: "Provide a non-null value at \(location). For node objects, include string id and type fields."
            )
        case .dataCorrupted(let context):
            let location = path(context.codingPath)
            return DemoDiagnostic(
                category: "JSON value is invalid",
                location: location,
                cause: context.debugDescription,
                resolution: resolutionForCorruptedValue(at: location)
            )
        @unknown default:
            return DemoDiagnostic(
                category: "Screen could not be decoded",
                location: path(codingPath(error)),
                cause: error.localizedDescription,
                resolution: "Check the value and type at this location against the SDUI screen schema."
            )
        }
    }

    private static func codingPath(_ error: DecodingError) -> [CodingKey] {
        switch error {
        case .keyNotFound(_, let context),
             .typeMismatch(_, let context),
             .valueNotFound(_, let context),
             .dataCorrupted(let context):
            return context.codingPath
        @unknown default:
            return []
        }
    }

    private static func resolutionForMissingKey(_ key: String, location: String) -> String {
        switch key {
        case "screenId":
            return "Add a string screenId at the top level."
        case "structureVersion":
            return "Add an integer structureVersion. This demo's sample screens use version 1."
        case "root":
            return "Add a root node object with string id and type fields."
        case "id":
            return "Add a unique string id to this node so the renderer can preserve its identity."
        case "type":
            return "Add a string type matching a registered demo component: \(DemoComponentType.allCases.map(\.rawValue).sorted().joined(separator: ", "))."
        default:
            return "Add the required value at \(location) with the type required by the SDUI schema."
        }
    }

    private static func resolutionForCorruptedValue(at location: String) -> String {
        if location.hasSuffix(".layout.direction") {
            return "Use exactly \"vertical\", \"horizontal\", or \"overlay\" for layout.direction."
        }
        if location.hasSuffix(".layout.alignment") {
            return "Use one of \"leading\", \"center\", \"trailing\", \"top\", or \"bottom\" for layout.alignment."
        }
        return "Correct the JSON syntax or use a supported enum value at \(location)."
    }

    private static func resolution(forDecodedField field: String?) -> String {
        switch field {
        case "style":
            return "Make style an object whose supported token properties are strings, or remove style from this node."
        case "layout":
            return "Make layout an object. Use direction vertical, horizontal, or overlay; use a compatible alignment and a string spacingToken."
        case "props":
            return "Make props a valid JSON value and use the property names and types required by this node's renderer."
        case "accessibility":
            return "Make accessibility an object with string label/hint and boolean isHeader/hidden values, or remove it."
        case "analytics":
            return "Make analytics an object with a string eventName and JSON-valued properties, or remove it."
        case "children":
            return "Make children an array of node objects. Each child needs string id and type fields."
        default:
            return "Check the field's JSON type and spelling against the node schema; remove malformed optional fields if they are not needed."
        }
    }

    private static func fieldName(in reason: String) -> String? {
        guard let separator = reason.firstIndex(of: ":") else { return nil }
        let candidate = String(reason[..<separator])
        let knownFields: Set<String> = [
            "style", "layout", "props", "accessibility", "analytics", "children"
        ]
        return knownFields.contains(candidate) ? candidate : nil
    }

    private static func path(_ codingPath: [CodingKey]) -> String {
        codingPath.reduce("$") { result, key in
            if let index = key.intValue {
                return "\(result)[\(index)]"
            }
            return "\(result).\(key.stringValue)"
        }
    }

    private static func unique(_ issues: [DemoDiagnostic]) -> [DemoDiagnostic] {
        var seen = Set<String>()
        return issues.filter { seen.insert($0.location).inserted }
    }
}

private enum DemoPreviewState {
    case noSelection
    case invalid(DemoDiagnostic)
    case ready(Screen, [DemoDiagnostic])
}

private struct DemoDiagnostic: Identifiable {
    let category: String
    let location: String
    let nodeID: String?
    let nodeType: String?
    let cause: String
    let resolution: String

    var id: String { "\(location)|\(category)|\(cause)" }

    init(
        category: String,
        location: String,
        nodeID: String? = nil,
        nodeType: String? = nil,
        cause: String,
        resolution: String
    ) {
        self.category = category
        self.location = location
        self.nodeID = nodeID
        self.nodeType = nodeType
        self.cause = cause
        self.resolution = resolution
    }
}

private struct DiagnosticScan {
    let issues: [DemoDiagnostic]
    let nodePaths: [String: String]
    let failedNodeDecodes: [DecodeFailure]
}

private final class DemoDecodeFailureCollector: DecodeFailureReporting {
    private(set) var failures: [DecodeFailure] = []

    func report(_ failure: DecodeFailure) {
        failures.append(failure)
    }
}

private enum DemoPropertiesEditor {
    static func supports(_ componentType: String) -> Bool {
        DemoComponentType(rawValue: componentType) != nil
    }

    @ViewBuilder
    static func make(
        for componentType: String,
        json: String,
        onSave: @escaping (String) -> Void
    ) -> some View {
        switch DemoComponentType(rawValue: componentType) {
        case .some(.text):
            TextPropertiesEditor(json: json, onSave: onSave)
        case .some(.stack):
            if CardPropertiesDraft.cardOptions(in: json).isEmpty {
                StackPropertiesEditor(json: json, onSave: onSave)
            } else {
                CardPropertiesEditor(json: json, onSave: onSave)
            }
        case .some(.image):
            ImagePropertiesEditor(json: json, onSave: onSave)
        case .some(.button):
            ButtonPropertiesEditor(json: json, onSave: onSave)
        case .some(.card):
            CardPropertiesEditor(json: json, onSave: onSave)
        case .none:
            Text("Property editing is not available for this component.")
        }
    }
}

private struct StackPropertiesEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: StackPropertiesDraft

    private let json: String
    private let onSave: (String) -> Void

    init(json: String, onSave: @escaping (String) -> Void) {
        self.json = json
        self.onSave = onSave
        _draft = State(initialValue: StackPropertiesDraft(json: json))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Choose how this stack arranges its children. The preview changes after you save.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Layout") {
                    Picker("Direction", selection: $draft.direction) {
                        ForEach(PropertyTokenOption.directions) { option in
                            Text(option.title).tag(option.value)
                        }
                    }

                    Picker("Alignment", selection: $draft.alignment) {
                        ForEach(PropertyTokenOption.alignments(for: draft.direction)) { option in
                            Text(option.title).tag(option.value)
                        }
                    }

                    Picker("Spacing", selection: $draft.spacingToken) {
                        ForEach(PropertyTokenOption.spacing) { option in
                            Text(option.title).tag(option.value)
                        }
                    }
                }
            }
            .navigationTitle("Edit Stack Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.regularMaterial)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onChange(of: draft.direction) { newDirection in
            let options = PropertyTokenOption.alignments(for: newDirection)
            if !options.contains(where: { $0.value == draft.alignment }) {
                draft.alignment = ""
            }
        }
    }

    private func save() {
        guard let updatedJSON = draft.applying(to: json) else { return }
        onSave(updatedJSON)
        dismiss()
    }
}

private struct CardPropertiesEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCardID: String
    @State private var drafts: [String: CardPropertiesDraft]
    @State private var dirtyCardIDs: Set<String> = []
    @State private var saveErrorMessage: String?

    private let json: String
    private let cardOptions: [CardOption]
    private let onSave: (String) -> Void

    init(json: String, onSave: @escaping (String) -> Void) {
        self.json = json
        self.onSave = onSave
        let cardOptions = CardPropertiesDraft.cardOptions(in: json)
        var drafts: [String: CardPropertiesDraft] = [:]
        for option in cardOptions {
            drafts[option.id] = CardPropertiesDraft(json: json, cardID: option.id)
        }
        self.cardOptions = cardOptions
        _selectedCardID = State(initialValue: cardOptions.first?.id ?? "")
        _drafts = State(initialValue: drafts)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Set the card's layout, appearance, and tap action. Changes appear in the preview after saving.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Select card") {
                    Picker("Card", selection: $selectedCardID) {
                        ForEach(cardOptions) { option in
                            Text(option.label).tag(option.id)
                        }
                    }
                    .pickerStyle(.menu)

                    Text("Card ID: \(selectedCardID)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Action") {
                    TextField("Action ID", text: selectedDraft.actionID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Layout") {
                    Picker("Direction", selection: selectedDraft.layout.direction) {
                        ForEach(PropertyTokenOption.directions) { option in
                            Text(option.title).tag(option.value)
                        }
                    }

                    Picker("Alignment", selection: selectedDraft.layout.alignment) {
                        ForEach(PropertyTokenOption.alignments(for: selectedDraft.layout.direction.wrappedValue)) { option in
                            Text(option.title).tag(option.value)
                        }
                    }

                    Picker("Spacing", selection: selectedDraft.layout.spacingToken) {
                        ForEach(PropertyTokenOption.spacing) { option in
                            Text(option.title).tag(option.value)
                        }
                    }
                }

                Section("Appearance") {
                    tokenPicker("Background", selection: selectedDraft.backgroundColorToken, options: PropertyTokenOption.colors)
                    tokenPicker("Padding", selection: selectedDraft.paddingToken, options: PropertyTokenOption.spacing)
                    tokenPicker("Corner radius", selection: selectedDraft.radiusToken, options: PropertyTokenOption.radii)
                    tokenPicker("Border color", selection: selectedDraft.borderColorToken, options: PropertyTokenOption.colors)
                    tokenPicker("Border width", selection: selectedDraft.borderWidthToken, options: PropertyTokenOption.borderWidths)
                }

                if let saveErrorMessage {
                    Section {
                        Text(saveErrorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Card Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.regularMaterial)
            }
            .onChange(of: selectedDraft.layout.direction.wrappedValue) { newDirection in
                let options = PropertyTokenOption.alignments(for: newDirection)
                let currentAlignment = selectedDraft.layout.alignment.wrappedValue
                if !options.contains(where: { $0.value == currentAlignment }) {
                    selectedDraft.layout.alignment.wrappedValue = ""
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var selectedDraft: Binding<CardPropertiesDraft> {
        Binding(
            get: {
                drafts[selectedCardID] ?? CardPropertiesDraft(json: json, cardID: selectedCardID)
            },
            set: {
                drafts[selectedCardID] = $0
                dirtyCardIDs.insert(selectedCardID)
                saveErrorMessage = nil
            }
        )
    }

    private func tokenPicker(
        _ title: String,
        selection: Binding<String>,
        options: [PropertyTokenOption]
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(options) { option in
                Text(option.title).tag(option.value)
            }
        }
    }

    private func save() {
        guard !dirtyCardIDs.isEmpty else {
            dismiss()
            return
        }

        var updatedJSON = json
        for option in cardOptions where dirtyCardIDs.contains(option.id) {
            guard let draft = drafts[option.id],
                  let nextJSON = draft.applying(to: updatedJSON) else {
                saveErrorMessage = "Could not save changes for card \(option.id). No changes were applied."
                return
            }
            updatedJSON = nextJSON
        }

        onSave(updatedJSON)
        dismiss()
    }
}

private struct ImagePropertiesEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ImagePropertiesDraft

    private let json: String
    private let onSave: (String) -> Void

    init(json: String, onSave: @escaping (String) -> Void) {
        self.json = json
        self.onSave = onSave
        _draft = State(initialValue: ImagePropertiesDraft(json: json))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Choose an image address and how it should fit. The preview changes after you save.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Image") {
                    TextField("Image URL", text: $draft.url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("Content mode", selection: $draft.contentMode) {
                        Text("Fit — show the whole image").tag("fit")
                        Text("Fill — crop to fill").tag("fill")
                    }

                    if !draft.hasValidURL {
                        Text("Enter a valid HTTP or HTTPS image URL.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    tokenPicker("Background", selection: $draft.backgroundColorToken, options: PropertyTokenOption.colors)
                    tokenPicker("Padding", selection: $draft.paddingToken, options: PropertyTokenOption.spacing)
                    tokenPicker("Corner radius", selection: $draft.radiusToken, options: PropertyTokenOption.radii)
                    tokenPicker("Border color", selection: $draft.borderColorToken, options: PropertyTokenOption.colors)
                } header: {
                    Text("Box style")
                } footer: {
                    Text("These options use the demo theme’s available design tokens.")
                }
            }
            .navigationTitle("Edit Image Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.regularMaterial)
                .disabled(!draft.hasValidURL)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func tokenPicker(
        _ title: String,
        selection: Binding<String>,
        options: [PropertyTokenOption]
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(options) { option in
                Text(option.title).tag(option.value)
            }
        }
    }

    private func save() {
        guard draft.hasValidURL,
              let updatedJSON = draft.applying(to: json) else {
            return
        }
        onSave(updatedJSON)
        dismiss()
    }
}

private struct ButtonPropertiesEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ButtonPropertiesDraft
    @State private var selectedAction: String

    private let json: String
    private let onSave: (String) -> Void
    private static let customActionSelection = "custom"

    init(json: String, onSave: @escaping (String) -> Void) {
        let draft = ButtonPropertiesDraft(json: json)
        self.json = json
        self.onSave = onSave
        _draft = State(initialValue: draft)
        _selectedAction = State(
            initialValue: draft.actionID.isEmpty
                ? ""
                : (DemoButtonAction(rawValue: draft.actionID)?.rawValue ?? Self.customActionSelection)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Button label", text: $draft.title)

                    Picker("Icon", selection: $draft.systemImage) {
                        ForEach(PropertyTokenOption.buttonIcons) { option in
                            Text(option.title).tag(option.value)
                        }
                    }
                } header: {
                    Text("Label")
                }

                Section {
                    Picker("When tapped", selection: $selectedAction) {
                        Text("No action (static label)").tag("")
                        ForEach(DemoButtonAction.allCases) { action in
                            Text(action.title).tag(action.rawValue)
                        }
                        Text("Custom action ID").tag(Self.customActionSelection)
                    }

                    if selectedAction == Self.customActionSelection {
                        TextField("Action ID", text: $draft.actionID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Action")
                } footer: {
                    Text("Choose a demo action or enter a custom ID. The demo displays the selected action when tapped.")
                }
            }
            .onChange(of: selectedAction) { newAction in
                if newAction == Self.customActionSelection {
                    if DemoButtonAction(rawValue: draft.actionID) != nil {
                        draft.actionID = ""
                    }
                } else {
                    draft.actionID = newAction
                }
            }
            .navigationTitle("Edit Button Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.regularMaterial)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        guard let updatedJSON = draft.applying(to: json) else { return }
        onSave(updatedJSON)
        dismiss()
    }
}

private struct TextPropertiesEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: TextPropertiesDraft

    private let json: String
    private let onSave: (String) -> Void

    init(json: String, onSave: @escaping (String) -> Void) {
        self.json = json
        self.onSave = onSave
        _draft = State(initialValue: TextPropertiesDraft(json: json))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Update this Text component. The preview changes after you save.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    TextField("Text", text: $draft.content, axis: .vertical)
                        .lineLimit(2...5)

                    Toggle("Limit lines", isOn: $draft.hasLineLimit)

                    if draft.hasLineLimit {
                        Stepper(
                            "Maximum lines: \(draft.numberOfLines)",
                            value: $draft.numberOfLines,
                            in: 1...max(100, draft.numberOfLines)
                        )
                    }
                } header: {
                    Text("Content")
                }

                Section {
                    tokenPicker("Text color", selection: $draft.textColorToken, options: PropertyTokenOption.colors)
                    tokenPicker("Font", selection: $draft.fontToken, options: PropertyTokenOption.fonts)
                } header: {
                    Text("Typography")
                }

                Section {
                    tokenPicker("Background", selection: $draft.backgroundColorToken, options: PropertyTokenOption.colors)
                    tokenPicker("Padding", selection: $draft.paddingToken, options: PropertyTokenOption.spacing)
                    tokenPicker("Corner radius", selection: $draft.radiusToken, options: PropertyTokenOption.radii)
                    tokenPicker("Border color", selection: $draft.borderColorToken, options: PropertyTokenOption.colors)
                } header: {
                    Text("Box style")
                } footer: {
                    Text("These options use the demo theme’s available design tokens.")
                }
            }
            .navigationTitle("Edit Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.regularMaterial)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func tokenPicker(
        _ title: String,
        selection: Binding<String>,
        options: [PropertyTokenOption]
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(options) { option in
                Text(option.title).tag(option.value)
            }
        }
    }

    private func save() {
        guard let updatedJSON = draft.applying(to: json) else { return }
        onSave(updatedJSON)
        dismiss()
    }
}

private struct TextPropertiesDraft {
    var content: String
    var hasLineLimit: Bool
    var numberOfLines: Int
    var textColorToken: String
    var fontToken: String
    var backgroundColorToken: String
    var paddingToken: String
    var radiusToken: String
    var borderColorToken: String

    init(json: String) {
        let data = Data(json.utf8)
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let root = object?["root"] as? [String: Any]
        let props = root?["props"] as? [String: Any] ?? [:]
        let style = root?["style"] as? [String: Any] ?? [:]
        let lineCount = (props["numberOfLines"] as? NSNumber)?.intValue

        content = props["content"] as? String ?? ""
        hasLineLimit = (lineCount ?? 0) > 0
        numberOfLines = max(1, lineCount ?? 2)
        textColorToken = style["textColorToken"] as? String ?? ""
        fontToken = style["fontToken"] as? String ?? ""
        backgroundColorToken = style["backgroundColorToken"] as? String ?? ""
        paddingToken = style["paddingToken"] as? String ?? ""
        radiusToken = style["radiusToken"] as? String ?? ""
        borderColorToken = style["borderColorToken"] as? String ?? ""
    }

    func applying(to json: String) -> String? {
        guard let data = json.data(using: .utf8),
              var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              var root = object["root"] as? [String: Any],
              root["type"] as? String == "text" else {
            return nil
        }

        var props = root["props"] as? [String: Any] ?? [:]
        props["content"] = content
        if hasLineLimit {
            props["numberOfLines"] = numberOfLines
        } else {
            props.removeValue(forKey: "numberOfLines")
        }

        var style = root["style"] as? [String: Any] ?? [:]
        set(textColorToken, for: "textColorToken", in: &style)
        set(fontToken, for: "fontToken", in: &style)
        set(backgroundColorToken, for: "backgroundColorToken", in: &style)
        set(paddingToken, for: "paddingToken", in: &style)
        set(radiusToken, for: "radiusToken", in: &style)
        set(borderColorToken, for: "borderColorToken", in: &style)

        if style.isEmpty {
            root.removeValue(forKey: "style")
        } else {
            root["style"] = style
        }
        root["props"] = props
        object["root"] = root

        guard let updatedData = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return nil
        }
        return String(data: updatedData, encoding: .utf8)
    }

    private func set(_ value: String, for key: String, in object: inout [String: Any]) {
        if value.isEmpty {
            object.removeValue(forKey: key)
        } else {
            object[key] = value
        }
    }
}

private struct StackPropertiesDraft {
    var direction: String
    var alignment: String
    var spacingToken: String

    init(json: String) {
        let data = Data(json.utf8)
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let root = object?["root"] as? [String: Any]
        self.init(node: root ?? [:])
    }

    init(node: [String: Any]) {
        let layout = node["layout"] as? [String: Any] ?? [:]
        let candidateDirection = layout["direction"] as? String ?? "vertical"
        let direction = PropertyTokenOption.directions.contains { $0.value == candidateDirection }
            ? candidateDirection
            : "vertical"
        let alignment = layout["alignment"] as? String ?? ""
        let allowedAlignments = PropertyTokenOption.alignments(for: direction).map(\.value)

        self.direction = direction
        self.alignment = allowedAlignments.contains(alignment) ? alignment : ""
        spacingToken = layout["spacingToken"] as? String ?? ""
    }

    func applying(to json: String, componentType: String = "stack") -> String? {
        guard let data = json.data(using: .utf8),
              var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              var root = object["root"] as? [String: Any],
              root["type"] as? String == componentType,
              PropertyTokenOption.directions.contains(where: { $0.value == direction }) else {
            return nil
        }

        var layout = root["layout"] as? [String: Any] ?? [:]
        layout["direction"] = direction
        set(alignment, for: "alignment", in: &layout)
        set(spacingToken, for: "spacingToken", in: &layout)
        root["layout"] = layout
        object["root"] = root

        guard let updatedData = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return nil
        }
        return String(data: updatedData, encoding: .utf8)
    }

    private func set(_ value: String, for key: String, in object: inout [String: Any]) {
        if value.isEmpty {
            object.removeValue(forKey: key)
        } else {
            object[key] = value
        }
    }
}

private struct CardPropertiesDraft {
    private let cardID: String?
    var layout: StackPropertiesDraft
    var actionID: String
    var backgroundColorToken: String
    var paddingToken: String
    var radiusToken: String
    var borderColorToken: String
    var borderWidthToken: String

    init(json: String, cardID: String? = nil) {
        let data = Data(json.utf8)
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let root = object?["root"] as? [String: Any]
        let node: [String: Any]
        if let cardID, let selectedNode = DemoNodeJSON.findNode(withID: cardID, in: root ?? [:]) {
            node = selectedNode
        } else {
            node = root ?? [:]
        }
        let style = node["style"] as? [String: Any] ?? [:]

        self.cardID = cardID
        layout = StackPropertiesDraft(node: node)
        actionID = node["actionId"] as? String ?? ""
        backgroundColorToken = style["backgroundColorToken"] as? String ?? ""
        paddingToken = style["paddingToken"] as? String ?? ""
        radiusToken = style["radiusToken"] as? String ?? ""
        borderColorToken = style["borderColorToken"] as? String ?? ""
        borderWidthToken = style["borderWidthToken"] as? String ?? ""
    }

    func applying(to json: String) -> String? {
        guard PropertyTokenOption.directions.contains(where: { $0.value == layout.direction }),
              let data = json.data(using: .utf8),
              var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              var root = object["root"] as? [String: Any] else {
            return nil
        }

        let didUpdate: Bool
        if let cardID {
            didUpdate = DemoNodeJSON.updateNode(withID: cardID, in: &root) { node in
                apply(to: &node)
            }
        } else {
            didUpdate = apply(to: &root)
        }
        guard didUpdate else { return nil }
        object["root"] = root

        guard let updatedData = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return nil
        }
        return String(data: updatedData, encoding: .utf8)
    }

    static func cardOptions(in json: String) -> [CardOption] {
        guard let data = json.data(using: .utf8),
              let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let root = object["root"] as? [String: Any] else {
            return []
        }
        return DemoNodeJSON.cardOptions(in: root)
    }

    private func apply(to node: inout [String: Any]) -> Bool {
        guard node["type"] as? String == "card" else { return false }

        var layoutObject = node["layout"] as? [String: Any] ?? [:]
        layoutObject["direction"] = layout.direction
        set(layout.alignment, for: "alignment", in: &layoutObject)
        set(layout.spacingToken, for: "spacingToken", in: &layoutObject)
        node["layout"] = layoutObject

        set(actionID, for: "actionId", in: &node)
        var style = node["style"] as? [String: Any] ?? [:]
        set(backgroundColorToken, for: "backgroundColorToken", in: &style)
        set(paddingToken, for: "paddingToken", in: &style)
        set(radiusToken, for: "radiusToken", in: &style)
        set(borderColorToken, for: "borderColorToken", in: &style)
        set(borderWidthToken, for: "borderWidthToken", in: &style)
        if style.isEmpty {
            node.removeValue(forKey: "style")
        } else {
            node["style"] = style
        }
        return true
    }

    private func set(_ value: String, for key: String, in object: inout [String: Any]) {
        if value.isEmpty {
            object.removeValue(forKey: key)
        } else {
            object[key] = value
        }
    }
}

private struct CardOption: Identifiable {
    let id: String
    let title: String

    var label: String { "\(id) - \(title)" }
}

private enum DemoNodeJSON {
    static func findNode(withID id: String, in root: [String: Any]) -> [String: Any]? {
        if root["id"] as? String == id { return root }
        for child in root["children"] as? [[String: Any]] ?? [] {
            if let match = findNode(withID: id, in: child) {
                return match
            }
        }
        return nil
    }

    static func updateNode(
        withID id: String,
        in node: inout [String: Any],
        update: (inout [String: Any]) -> Bool
    ) -> Bool {
        if node["id"] as? String == id {
            return update(&node)
        }
        guard var children = node["children"] as? [Any] else { return false }
        for index in children.indices {
            guard var child = children[index] as? [String: Any] else { continue }
            if updateNode(withID: id, in: &child, update: update) {
                children[index] = child
                node["children"] = children
                return true
            }
        }
        return false
    }

    static func cardOptions(in root: [String: Any]) -> [CardOption] {
        var options: [CardOption] = []
        var seenIDs = Set<String>()

        func firstText(in node: [String: Any]) -> String? {
            if node["type"] as? String == "text",
               let props = node["props"] as? [String: Any],
               let content = props["content"] as? String {
                return content
            }
            for child in node["children"] as? [[String: Any]] ?? [] {
                if let content = firstText(in: child) {
                    return content
                }
            }
            return nil
        }

        func collectCards(in node: [String: Any]) {
            if node["type"] as? String == "card",
               let id = node["id"] as? String,
               seenIDs.insert(id).inserted {
                options.append(CardOption(id: id, title: firstText(in: node) ?? "Card"))
            }
            for child in node["children"] as? [[String: Any]] ?? [] {
                collectCards(in: child)
            }
        }

        collectCards(in: root)
        return options
    }
}

private struct ImagePropertiesDraft {
    var url: String
    var contentMode: String
    var backgroundColorToken: String
    var paddingToken: String
    var radiusToken: String
    var borderColorToken: String

    private var trimmedURL: String {
        url.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasValidURL: Bool {
        guard let components = URLComponents(string: trimmedURL),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty else {
            return false
        }
        return true
    }

    init(json: String) {
        let data = Data(json.utf8)
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let root = object?["root"] as? [String: Any]
        let props = root?["props"] as? [String: Any] ?? [:]
        let style = root?["style"] as? [String: Any] ?? [:]
        let contentMode = props["contentMode"] as? String

        url = props["url"] as? String ?? ""
        self.contentMode = contentMode == "fill" ? "fill" : "fit"
        backgroundColorToken = style["backgroundColorToken"] as? String ?? ""
        paddingToken = style["paddingToken"] as? String ?? ""
        radiusToken = style["radiusToken"] as? String ?? ""
        borderColorToken = style["borderColorToken"] as? String ?? ""
    }

    func applying(to json: String) -> String? {
        guard hasValidURL,
              let data = json.data(using: .utf8),
              var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              var root = object["root"] as? [String: Any],
              root["type"] as? String == "image" else {
            return nil
        }

        var props = root["props"] as? [String: Any] ?? [:]
        props["url"] = trimmedURL
        props["contentMode"] = contentMode
        root["props"] = props

        var style = root["style"] as? [String: Any] ?? [:]
        set(backgroundColorToken, for: "backgroundColorToken", in: &style)
        set(paddingToken, for: "paddingToken", in: &style)
        set(radiusToken, for: "radiusToken", in: &style)
        set(borderColorToken, for: "borderColorToken", in: &style)
        if style.isEmpty {
            root.removeValue(forKey: "style")
        } else {
            root["style"] = style
        }

        object["root"] = root
        guard let updatedData = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return nil
        }
        return String(data: updatedData, encoding: .utf8)
    }

    private func set(_ value: String, for key: String, in object: inout [String: Any]) {
        if value.isEmpty {
            object.removeValue(forKey: key)
        } else {
            object[key] = value
        }
    }
}

private struct ButtonPropertiesDraft {
    var title: String
    var systemImage: String
    var actionID: String

    init(json: String) {
        let data = Data(json.utf8)
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let root = object?["root"] as? [String: Any]
        let props = root?["props"] as? [String: Any] ?? [:]

        title = props["title"] as? String ?? ""
        systemImage = props["systemImage"] as? String ?? ""
        actionID = root?["actionId"] as? String ?? ""
    }

    func applying(to json: String) -> String? {
        guard let data = json.data(using: .utf8),
              var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              var root = object["root"] as? [String: Any],
              root["type"] as? String == "button" else {
            return nil
        }

        var props = root["props"] as? [String: Any] ?? [:]
        set(title, for: "title", in: &props)
        set(systemImage, for: "systemImage", in: &props)
        if props.isEmpty {
            root.removeValue(forKey: "props")
        } else {
            root["props"] = props
        }
        set(actionID, for: "actionId", in: &root)
        object["root"] = root

        guard let updatedData = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return nil
        }
        return String(data: updatedData, encoding: .utf8)
    }

    private func set(_ value: String, for key: String, in object: inout [String: Any]) {
        if value.isEmpty {
            object.removeValue(forKey: key)
        } else {
            object[key] = value
        }
    }
}

private struct PropertyTokenOption: Identifiable {
    let title: String
    let value: String

    var id: String { value }

    static let colors = [
        PropertyTokenOption(title: "Default", value: ""),
        PropertyTokenOption(title: "Accent", value: "accent"),
        PropertyTokenOption(title: "Primary surface", value: "surfacePrimary"),
        PropertyTokenOption(title: "Secondary surface", value: "surfaceSecondary"),
        PropertyTokenOption(title: "Primary text", value: "textPrimary"),
        PropertyTokenOption(title: "Secondary text", value: "textSecondary")
    ]

    static let fonts = [
        PropertyTokenOption(title: "Default", value: ""),
        PropertyTokenOption(title: "Title large", value: "titleLarge"),
        PropertyTokenOption(title: "Body", value: "body"),
        PropertyTokenOption(title: "Caption", value: "caption")
    ]

    static let spacing = [
        PropertyTokenOption(title: "None", value: ""),
        PropertyTokenOption(title: "Small", value: "spacingSm"),
        PropertyTokenOption(title: "Medium", value: "spacingMd"),
        PropertyTokenOption(title: "Large", value: "spacingLg")
    ]

    static let radii = [
        PropertyTokenOption(title: "None", value: ""),
        PropertyTokenOption(title: "Small", value: "radiusSm"),
        PropertyTokenOption(title: "Medium", value: "radiusMd"),
        PropertyTokenOption(title: "Large", value: "radiusLg")
    ]

    static let borderWidths = [
        PropertyTokenOption(title: "Default", value: ""),
        PropertyTokenOption(title: "Thin", value: "borderThin"),
        PropertyTokenOption(title: "Thick", value: "borderThick")
    ]

    static let buttonIcons = [
        PropertyTokenOption(title: "No icon", value: ""),
        PropertyTokenOption(title: "Cart", value: "cart"),
        PropertyTokenOption(title: "Filled cart", value: "cart.fill"),
        PropertyTokenOption(title: "Heart", value: "heart"),
        PropertyTokenOption(title: "Filled heart", value: "heart.fill"),
        PropertyTokenOption(title: "Star", value: "star"),
        PropertyTokenOption(title: "Plus", value: "plus")
    ]

    static let directions = [
        PropertyTokenOption(title: "Vertical", value: "vertical"),
        PropertyTokenOption(title: "Horizontal", value: "horizontal"),
        PropertyTokenOption(title: "Overlay", value: "overlay")
    ]

    static func alignments(for direction: String) -> [PropertyTokenOption] {
        let alignments: [PropertyTokenOption]
        switch direction {
        case "vertical":
            alignments = [
                PropertyTokenOption(title: "Leading", value: "leading"),
                PropertyTokenOption(title: "Center", value: "center"),
                PropertyTokenOption(title: "Trailing", value: "trailing")
            ]
        case "horizontal":
            alignments = [
                PropertyTokenOption(title: "Top", value: "top"),
                PropertyTokenOption(title: "Center", value: "center"),
                PropertyTokenOption(title: "Bottom", value: "bottom")
            ]
        default:
            alignments = [
                PropertyTokenOption(title: "Leading", value: "leading"),
                PropertyTokenOption(title: "Center", value: "center"),
                PropertyTokenOption(title: "Trailing", value: "trailing"),
                PropertyTokenOption(title: "Top", value: "top"),
                PropertyTokenOption(title: "Bottom", value: "bottom")
            ]
        }
        return [PropertyTokenOption(title: "Default", value: "")] + alignments
    }
}

private struct JSONColumn: View {
    @Binding var json: String
    let sampleID: ComponentSample.ID?

    @State private var draftJSON: String
    @State private var isEditing = false

    init(json: Binding<String>, sampleID: ComponentSample.ID?) {
        _json = json
        self.sampleID = sampleID
        _draftJSON = State(initialValue: json.wrappedValue)
    }

    var body: some View {
        Group {
            if isEditing {
                TextEditor(text: $draftJSON)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                ScrollView {
                    Text(json)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .font(.system(.footnote, design: .monospaced))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("JSON")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: copyJSON) {
                    Image(systemName: "doc.on.doc")
                }
                .accessibilityLabel("Copy JSON")

                if isEditing {
                    Button("Paste", action: pasteJSON)
                    Button("Done", action: saveJSON)
                } else {
                    Button("Edit") {
                        draftJSON = json
                        isEditing = true
                    }
                }
            }
        }
        .onChange(of: sampleID) { _ in
            draftJSON = json
            isEditing = false
        }
        .onChange(of: json) { newJSON in
            draftJSON = newJSON
            isEditing = false
        }
    }

    private func copyJSON() {
        UIPasteboard.general.string = isEditing ? draftJSON : json
    }

    private func pasteJSON() {
        guard let clipboardJSON = UIPasteboard.general.string else { return }
        draftJSON = clipboardJSON
    }

    private func saveJSON() {
        json = draftJSON
        isEditing = false
    }
}
