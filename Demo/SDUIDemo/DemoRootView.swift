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
                json: jsonText,
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
    let json: String
    let theme: Theme
    let registry: RendererRegistry

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
    }

    // D1 only: D2 replaces this with a result type that carries errors.
    private func decode(_ json: String) -> Screen? {
        try? JSONDecoder().decode(Screen.self, from: Data(json.utf8))
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
