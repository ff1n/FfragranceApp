import SwiftUI
import SwiftData

struct ChemicalSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\AromaChemical.name, order: .forward)])
    private var chemicals: [AromaChemical]
    
    @State private var searchText = ""
    @State private var sortByPyramidNote = true
    private let pyramidNoteOrder = ["top", "topmid", "mid", "midbase", "base"]
    
    let onSelect: (AromaChemical) -> Void
    
    var filteredChemicals: [AromaChemical] {
        guard !searchText.isEmpty else { return chemicals }
        return chemicals.filter { chemical in
            chemical.name.localizedCaseInsensitiveContains(searchText) ||
            chemical.casNumber.localizedCaseInsensitiveContains(searchText) ||
            chemical.category?.name.localizedCaseInsensitiveContains(searchText) == true ||
            (chemical.tags ?? []).contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) })
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List {
                    if sortByPyramidNote {
                        ForEach(sortedPyramidNotes, id: \.self) { pyramidNote in
                            Section(header: Text(pyramidNote.capitalized)) {
                                ForEach(groupedChemicalsByPyramid[pyramidNote] ?? []) { chemical in
                                    ChemicalSelectRow(chemical: chemical)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            onSelect(chemical)
                                            dismiss()
                                        }
                                }
                            }
                        }
                    } else {
                        ForEach(filteredChemicals.sorted(by: { $0.name < $1.name })) { chemical in
                            Button {
                                onSelect(chemical)
                                dismiss()
                            } label: {
                                ChemicalSelectRow(chemical: chemical)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Chemical")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { sortByPyramidNote.toggle() }) {
                        Label("Sort: \(sortByPyramidNote ? "Pyramid Note" : "Name")",
                              systemImage: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var groupedChemicalsByPyramid: [String: [AromaChemical]] {
        Dictionary(grouping: filteredChemicals, by: { $0.pyramidNote })
    }
    
    private var sortedPyramidNotes: [String] {
        pyramidNoteOrder.filter { groupedChemicalsByPyramid.keys.contains($0) }
    }
}

struct ChemicalSelectRow: View {
    let chemical: AromaChemical
    
    var body: some View {
        ZStack {
            // Background to ensure the entire area is tappable
            Rectangle()
                .fill(Color.clear)
            
            HStack {
                if let category = chemical.category {
                    Rectangle()
                        .fill(category.color)
                        .frame(width: 4)
                        .cornerRadius(2)
                        .frame(height: 40)
                }
                
                VStack(alignment: .leading) {
                    Text(chemical.name)
                        .font(.headline)
                    
                    HStack {
                        Text("CAS: \(chemical.casNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let tags = chemical.tags, !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(tags) { tag in
                                        TagView(tag: tag)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.leading, 4)
                
                Spacer() // Add spacer to make HStack take full width
            }
        }
        .contentShape(Rectangle())  // This is crucial for tap detection
    }
}
