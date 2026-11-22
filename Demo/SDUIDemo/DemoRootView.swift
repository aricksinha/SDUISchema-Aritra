import SwiftUI
import UIKit
import Foundation
import SDUISchema
import SDUIDesignSystem
import SDUIRendering

struct DemoRootView: View {
    @State private var selection: ComponentSample.ID? = SampleCatalog.all.first?.id
    @State private var jsonText = SampleCatalog.all.first?.json ?? ""
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
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
                registry: DemoCompositionRoot.makeRegistry { actionID in
                    handleButtonAction(actionID)
                }
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
    let registry: RendererRegistry

    @State private var isShowingPropertiesEditor = false

    var body: some View {
        ScrollView {
            Group {
                if sample != nil, let screen = decode(json) {
                    SDUIView(screen: screen, theme: theme, registry: registry)
                } else {
                    Text("Nothing to preview").foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
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

    private var canEditProperties: Bool {
        guard let screen = decode(json) else { return false }
        return DemoPropertiesEditor.supports(screen.root.type)
    }

    // D1 only: D2 replaces this with a result type that carries errors.
    private func decode(_ json: String) -> Screen? {
        try? JSONDecoder().decode(Screen.self, from: Data(json.utf8))
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
