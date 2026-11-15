import SwiftUI
import UIKit
import SDUISchema
import SDUIDesignSystem
import SDUIRendering

struct DemoRootView: View {
    @State private var selection: ComponentSample.ID? = SampleCatalog.all.first?.id
    @State private var jsonText = SampleCatalog.all.first?.json ?? ""
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private let theme = DemoCompositionRoot.makeTheme()
    private let registry = DemoCompositionRoot.makeRegistry()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SampleListColumn(sections: SampleCatalog.sections, selection: $selection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } content: {
            PreviewColumn(
                sample: SampleCatalog.sample(id: selection),
                json: $jsonText,
                theme: theme,
                registry: registry
            )
                .navigationSplitViewColumnWidth(min: 320, ideal: 420, max: 600)
        } detail: {
            JSONColumn(json: $jsonText, sampleID: selection)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selection) { newSelection in
            jsonText = SampleCatalog.sample(id: newSelection)?.json ?? ""
        }
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
    let registry: RendererRegistry

    @State private var isShowingPropertiesEditor = false

    var body: some View {
        Group {
            if sample != nil, let screen = decode(json) {
                SDUIView(screen: screen, theme: theme, registry: registry)
            } else {
                Text("Nothing to preview").foregroundColor(.secondary)
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
            TextPropertiesEditor(json: json) { updatedJSON in
                json = updatedJSON
            }
        }
    }

    private var canEditProperties: Bool {
        guard let screen = decode(json) else { return false }
        return screen.root.type == "text"
    }

    // D1 only: D2 replaces this with a result type that carries errors.
    private func decode(_ json: String) -> Screen? {
        try? JSONDecoder().decode(Screen.self, from: Data(json.utf8))
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
