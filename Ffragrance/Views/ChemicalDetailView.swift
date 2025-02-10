import SwiftUI
import SwiftData

struct ChemicalDetailView: View {
    @Bindable var chemical: AromaChemical
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Category.name, order: .forward)])
    private var categories: [Category]
    
    @Query(sort: [SortDescriptor(\Tag.name, order: .forward)])
    private var availableTags: [Tag]
    
    @State private var selectedTag: Tag?
    var pyramidNotes = ["top", "topmid", "mid", "midbase", "base"]
    
    var body: some View {
            Form {
                basicsSection
                stockInfoSection
                pyramidNoteSection
                tagsSection
                categorySection
                notesSection
            }
            .navigationTitle(chemical.name.isEmpty ? "New Chemical" : chemical.name)
        }

        // MARK: - Subviews

        private var basicsSection: some View {
            Section("Basics") {
                TextField("Chemical Name", text: $chemical.name)
                    .autocapitalization(.words)
                
                TextField("CAS Number", text: $chemical.casNumber)
                    .keyboardType(.numbersAndPunctuation)
                
                TextField("IFRA Safe Limit (%)", value: $chemical.ifraSafeLimit, format: .number)
                    .keyboardType(.decimalPad)
            }
        }

        private var stockInfoSection: some View {
            Section("Stock Info") {
                Picker("Unit", selection: $chemical.unit) {
                    Text("Grams").tag("grams")
                    Text("Milliliters").tag("ml")
                }
                .pickerStyle(.segmented)
                
                if chemical.unit == "grams" {
                    TextField("Quantity (grams)", value: $chemical.quantityGrams, format: .number)
                        .keyboardType(.decimalPad)
                } else {
                    TextField("Quantity (ml)", value: $chemical.quantityMl, format: .number)
                        .keyboardType(.decimalPad)
                    
                    TextField("Dilution (%)", value: $chemical.dilutionPercentage, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
        }

        private var pyramidNoteSection: some View {
            Section("Pyramid Note") {
                Picker("Pyramid Note", selection: $chemical.pyramidNote) {
                    ForEach(pyramidNotes, id: \.self) { note in
                        Text(note.capitalized).tag(note)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        
    private var tagsSection: some View {
        Section("Tags") {
            // Current tags view
            if let tags = chemical.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(tags) { tag in
                            TagChip(tag: tag) {
                                chemical.removeTag(tag)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Tag picker
            TagPicker(
                tags: availableTags.filter { tag in
                    !(chemical.tags?.contains(tag) ?? false)
                },
                selectedTag: $selectedTag,
                onSelect: { tag in
                    chemical.addTag(tag)
                    selectedTag = nil
                }
            )
        }
    }

    // Separate view for individual tag chips
    private struct TagChip: View {
        let tag: Tag
        let onRemove: () -> Void
        
        var body: some View {
            HStack {
                Circle()
                    .fill(tag.color)
                    .frame(width: 12, height: 12)
                Text(tag.name)
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
    }

    // Separate view for tag picker
    private struct TagPicker: View {
        let tags: [Tag]
        @Binding var selectedTag: Tag?
        let onSelect: (Tag) -> Void
        
        var body: some View {
            Picker("Add Tag", selection: $selectedTag) {
                Text("Select a tag").tag(Optional<Tag>.none)
                ForEach(tags) { tag in
                    HStack {
                        Circle()
                            .fill(tag.color)
                            .frame(width: 20, height: 20)
                        Text(tag.name)
                    }.tag(Optional(tag))
                }
            }
            .onChange(of: selectedTag) { oldValue, newValue in
                if let tag = newValue {
                    onSelect(tag)
                }
            }
        }
    }
        private var categorySection: some View {
            Section("Category") {
                Picker("Category", selection: $chemical.category) {
                    Text("None").tag(Optional<Category>.none)
                    ForEach(categories) { category in
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 20, height: 20)
                            Text(category.name)
                        }.tag(Optional(category))
                    }
                }
            }
        }

        private var notesSection: some View {
            Section("Notes") {
                TextEditor(text: $chemical.notes)
                    .frame(minHeight: 100)
            }
        }
}
