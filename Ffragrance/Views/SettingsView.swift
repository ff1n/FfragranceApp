import SwiftUI
import MessageUI
import UniformTypeIdentifiers
import SwiftData

// Column mapping configuration
struct ColumnMapping: Identifiable {
    let id = UUID()
    let sourceHeader: String
    var targetField: String
    var isMatched: Bool
}

// View for manual column mapping
struct ColumnMapperView: View {
    @Binding var mappings: [ColumnMapping]
    @Environment(\.dismiss) private var dismiss
    let csvLines: [String]
    let onComplete: ([String], [ColumnMapping]) -> Void
    
    let availableFields = [
        "name", "casNumber", "ifraSafeLimit", "notes",
        "pyramidNote", "unit", "quantityGrams", "quantityMl",
        "dilutionPercentage", "category"
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach($mappings) { mapping in
                    HStack {
                        Text(mapping.wrappedValue.sourceHeader)
                        Spacer()
                        Picker("Map to", selection: Binding(
                            get: { mapping.wrappedValue.targetField },
                            set: { newValue in
                                if let index = mappings.firstIndex(where: { $0.id == mapping.wrappedValue.id }) {
                                    mappings[index].targetField = newValue
                                    mappings[index].isMatched = true
                                }
                            }
                        )) {
                            Text("Ignore").tag("")
                            ForEach(availableFields, id: \.self) { field in
                                Text(field).tag(field)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Map Columns")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onComplete(csvLines, mappings)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<AromaChemical> { _ in true },
           sort: [SortDescriptor(\.name, order: .forward)]) private var chemicals: [AromaChemical]
    @Query(filter: #Predicate<Formula> { _ in true },
           sort: [SortDescriptor(\.name, order: .forward)]) private var formulas: [Formula]
    @Query(filter: #Predicate<Category> { _ in true },
           sort: [SortDescriptor(\.name, order: .forward)]) private var categories: [Category]
    @Query(filter: #Predicate<Tag> { _ in true },
           sort: [SortDescriptor(\.name, order: .forward)]) private var tags: [Tag]

    @State private var showAboutAlert = false
    @State private var showMailComposer = false
    @State private var mailErrorAlert = false
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var importedData: [[String]] = []
    @State private var showColumnMapper = false
    @State private var columnMappings: [ColumnMapping] = []
    @State private var csvLines: [String] = []
    @StateObject private var syncMonitor = SyncMonitor()
    
    // Common field name mappings
    private var fieldMappings: [String: [String]] {
        [
            "name": ["name", "chemical name", "substance", "material", "title"],
            "casNumber": ["cas", "cas number", "cas#", "cas no", "cas no."],
            "ifraSafeLimit": ["ifra", "ifra limit", "ifra restriction", "restriction", "ifraLimit"],
            "notes": ["notes", "description", "details", "content"],
            "pyramidNote": ["note", "pyramid note", "odor type"],
            "unit": ["unit", "units"],
            "quantityGrams": ["grams", "weight", "amount", "quantity (g)"],
            "quantityMl": ["ml", "volume", "quantity (ml)"],
            "dilutionPercentage": ["dilution", "concentration", "strength", "defaultDilution", "dilutions/0/percentage"],
            "category": ["category", "type", "group", "profileId"]
        ]
    }
    
    // Detect field from header
        private func detectField(from header: String) -> String? {
            let normalizedHeader = header.lowercased().trimmingCharacters(in: .whitespaces)
            
            for (field, alternatives) in fieldMappings {
                if alternatives.contains(normalizedHeader) {
                    return field
                }
            }
            return nil
        }

    var body: some View {
        NavigationStack {
            Form {
                // About Section
                Section {
                    Button(action: { showAboutAlert = true }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("About")
                        }
                    }
                    .alert("About Ffragrance", isPresented: $showAboutAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("""
                        Ffragrance
                        Version: 1.4
                        By Ffinian Elliott
                        For iOS 17.6 and above
                        Compatible on iPhone, iPad and iMac
                        """)
                    }
                    
                }
                
                Section("iCloud Sync") {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(statusColor)
                        Text(syncMonitor.syncStatus)
                    }
                    
                    if syncMonitor.syncStatus.contains("error") ||
                       syncMonitor.syncStatus.contains("No iCloud Account") {
                        Button("Check iCloud Status") {
                            // This will trigger a recheck of the CloudKit status
                            NotificationCenter.default.post(
                                name: .CKAccountChanged,
                                object: nil
                            )
                        }
                    }
                }
                
                Section {
                    Link(destination: URL(string: "https://ffragrance-app.tiiny.site")!) {
                        HStack {
                            Image(systemName: "lock.shield")
                            Text("Privacy Policy")
                        }
                    }
                }
                
                // Bug Report Section
                Section {
                    Button(action: {
                        if MFMailComposeViewController.canSendMail() {
                            showMailComposer = true
                        } else {
                            mailErrorAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("Report a Bug")
                        }
                    }
                    .alert("Cannot Send Mail", isPresented: $mailErrorAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Please configure a Mail account to send bug reports.")
                    }
                    .sheet(isPresented: $showMailComposer) {
                        MailComposerView(subject: "Bug Report for Ffragrance", body: bugReportTemplate)
                    }
                }
                
                // Import/Export Section
                Section {
                    Button(action: { showExportSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                        }
                    }
                    .fileExporter(
                        isPresented: $showExportSheet,
                        document: CSVDocument(data: exportCSVData),
                        contentType: .commaSeparatedText,
                        defaultFilename: "Ffragrance_Export"
                    ) { result in
                        handleExportResult(result)
                    }
                    
                    Button(action: { showImportSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Data")
                        }
                    }
                    .fileImporter(
                        isPresented: $showImportSheet,
                        allowedContentTypes: [.commaSeparatedText]
                    ) { result in
                        handleImportResult(result)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showColumnMapper) {
            ColumnMapperView(
                mappings: $columnMappings,
                csvLines: csvLines,
                onComplete: { lines, mappings in
                    processImportedData(lines, mappings: mappings)
                }
            )
            .presentationDetents([.large])
        }
    }
    
    private var bugReportTemplate: String {
        """
        Hi,

        I encountered an issue with the Ffragrance app. Here are the details:

        - App Version: 1.3
        - Device: \(UIDevice.current.model)
        - iOS Version: \(UIDevice.current.systemVersion)

        Issue Description:
        [Please describe the issue here]

        Steps to Reproduce:
        1. [List steps here]
        2. ...

        Expected Behavior:
        [What did you expect?]

        Actual Behavior:
        [What actually happened?]

        Thank you!
        """
    }

    private func generateCSVExport() -> String {
        var export = ""
        
        // Categories Table
        export += "--- CATEGORIES ---\n"
        export += "id,name,color_hex\n"
        for category in categories {
            export += "\(category.id),\(escapeCsvField(category.name)),\(category.colorHex)\n"
        }
        export += "\n"
        
        // Tags Table
        export += "--- TAGS ---\n"
        export += "id,name,red,green,blue,alpha\n"
        for tag in tags {
            export += "\(tag.id),\(escapeCsvField(tag.name)),\(tag.red),\(tag.green),\(tag.blue),\(tag.alpha)\n"
        }
        export += "\n"
        
        // Chemicals Table
        export += "--- CHEMICALS ---\n"
        export += "id,name,cas_number,ifra_limit,notes,pyramid_note,unit,quantity_grams,quantity_ml,dilution_percentage,category_id\n"
        for chemical in chemicals {
            export += "\(chemical.id),"
            export += "\(escapeCsvField(chemical.name)),"
            export += "\(escapeCsvField(chemical.casNumber)),"
            export += "\(chemical.ifraSafeLimit?.description ?? ""),"
            export += "\(escapeCsvField(chemical.notes)),"
            export += "\(escapeCsvField(chemical.pyramidNote)),"
            export += "\(escapeCsvField(chemical.unit)),"
            export += "\(chemical.quantityGrams?.description ?? ""),"
            export += "\(chemical.quantityMl?.description ?? ""),"
            export += "\(chemical.dilutionPercentage?.description ?? ""),"
            export += "\(chemical.category?.id.uuidString ?? "")\n"
        }
        export += "\n"

        // Chemical-Tags Relations
        export += "--- CHEMICAL_TAGS ---\n"
        export += "chemical_id,tag_id\n"
        for chemical in chemicals {
            if let tags = chemical.tags {
                for tag in tags {
                    export += "\(chemical.id),\(tag.id)\n"
                }
            }
        }
        export += "\n"
        
        // Formulas Table
        export += "--- FORMULAS ---\n"
        export += "id,name,smell_description,diluent_type,diluent_weight,total_weight\n"
        for formula in formulas {
            export += "\(formula.id),"
            export += "\(escapeCsvField(formula.name)),"
            export += "\(escapeCsvField(formula.smellDescription ?? "")),"
            export += "\(escapeCsvField(formula.diluentType ?? "")),"
            export += "\(formula.diluentWeight),"
            export += "\(formula.totalFormulaWeight)\n"
        }
        export += "\n"
        
        // Formula Lines Table
        export += "--- FORMULA_LINES ---\n"
        export += "id,formula_id,chemical_id,amount_grams,dilution_percentage,final_concentration\n"
        for formula in formulas {
            if let components = formula.dilutedComponents {
                for component in components {
                    export += "\(component.lineID),"
                    export += "\(formula.id),"
                    export += "\(component.chemical.id),"
                    export += "\(component.originalAmount),"
                    export += "\(component.dilutionPercentage),"
                    export += "\(component.finalConcentration)\n"
                }
            }
        }
        
        return export
    }
    
    private var statusColor: Color {
        switch syncMonitor.syncStatus {
        case "iCloud Account Available":
            return .green
        case "Changes synced":
            return .green
        case "Syncing changes...":
            return .blue
        case _ where syncMonitor.syncStatus.contains("error"):
            return .red
        default:
            return .orange
        }
    }

    
    private func escapeCsvField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    private var exportCSVData: String {
        generateCSVExport()
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Export successful! File saved to: \(url.path)")
        case .failure(let error):
            print("Export failed: \(error.localizedDescription)")
        }
    }

    // Updated import handling
    private func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security scoped resource")
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let csvString = try String(contentsOf: url)
                self.csvLines = csvString.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                guard let headerLine = csvLines.first else { return }
                let headers = headerLine.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                
                // Create initial mappings
                var columnMappings = headers.map { header in
                    ColumnMapping(
                        sourceHeader: header,
                        targetField: detectField(from: header) ?? "",
                        isMatched: false
                    )
                }
                
                // Show column mapper if needed
                let unmappedColumns = columnMappings.filter { !$0.isMatched }
                if !unmappedColumns.isEmpty {
                    showColumnMapper = true
                    self.columnMappings = columnMappings
                } else {
                    processImportedData(csvLines, mappings: columnMappings)
                }
                
            } catch {
                print("Failed to read CSV: \(error.localizedDescription)")
            }
        case .failure(let error):
            print("Import failed: \(error.localizedDescription)")
        }
    }
    
    private func processImportedData(_ lines: [String], mappings: [ColumnMapping]) {
        guard lines.count > 1 else { return }
        
        // Create a dictionary to store profiles/categories we encounter
        var profileCategories: [String: Category] = [:]
        
        // Process data rows
        for line in lines.dropFirst() {
            let fields = line.components(separatedBy: ",")
            guard fields.count == mappings.count else { continue }
            
            // Create chemical with mapped fields
            var chemicalData: [String: Any] = [:]
            
            for (index, mapping) in mappings.enumerated() {
                guard !mapping.targetField.isEmpty else { continue }
                let value = fields[index].trimmingCharacters(in: .whitespaces)
                chemicalData[mapping.targetField] = value
            }
            
            // Handle category/profile first
            if let profileId = chemicalData["category"] as? String {
                if !profileCategories.keys.contains(profileId) {
                    // Create new category if we haven't seen this profile before
                    let category = Category(name: profileId, color: Color.random)
                    modelContext.insert(category)
                    profileCategories[profileId] = category
                }
            }
            
            // Create chemical
            let chemical = AromaChemical(
                name: chemicalData["name"] as? String ?? "Unknown",
                casNumber: chemicalData["casNumber"] as? String ?? "",
                ifraSafeLimit: Double(chemicalData["ifraSafeLimit"] as? String ?? ""),
                notes: chemicalData["notes"] as? String ?? "",
                pyramidNote: chemicalData["pyramidNote"] as? String ?? "",
                unit: chemicalData["unit"] as? String ?? "g"
            )
            
            if let quantityStr = chemicalData["quantityGrams"] as? String {
                chemical.quantityGrams = Double(quantityStr)
            }
            if let quantityStr = chemicalData["quantityMl"] as? String {
                chemical.quantityMl = Double(quantityStr)
            }
            if let dilutionStr = chemicalData["dilutionPercentage"] as? String {
                chemical.dilutionPercentage = Double(dilutionStr)
            }
            
            // Link to category
            if let profileId = chemicalData["category"] as? String,
               let category = profileCategories[profileId] {
                chemical.category = category
            }
            
            modelContext.insert(chemical)
        }
        
        try? modelContext.save()
    }

    private func importCategories(_ lines: ArraySlice<String>) {
        for line in lines where !line.isEmpty {
            let fields = line.components(separatedBy: ",")
            guard fields.count >= 3 else { continue }
            
            let category = Category(name: fields[1], color: Color(hex: fields[2]) ?? .gray)
            modelContext.insert(category)
        }
    }
    
    private func importTags(_ lines: ArraySlice<String>) {
        for line in lines where !line.isEmpty {
            let fields = line.components(separatedBy: ",")
            guard fields.count >= 6 else { continue }
            
            let tag = Tag(name: fields[1])
            tag.red = Double(fields[2]) ?? 0
            tag.green = Double(fields[3]) ?? 0
            tag.blue = Double(fields[4]) ?? 0
            tag.alpha = Double(fields[5]) ?? 1
            modelContext.insert(tag)
        }
    }
    
    private func importChemicals(_ lines: ArraySlice<String>) {
        for line in lines where !line.isEmpty {
            let fields = line.components(separatedBy: ",")
            guard fields.count >= 11 else { continue }
            
            let chemical = AromaChemical(
                name: fields[1],
                casNumber: fields[2],
                ifraSafeLimit: Double(fields[3]),
                notes: fields[4],
                pyramidNote: fields[5],
                unit: fields[6]
            )
            chemical.quantityGrams = Double(fields[7])
            chemical.quantityMl = Double(fields[8])
            chemical.dilutionPercentage = Double(fields[9])
            
            // Category will be linked later
            modelContext.insert(chemical)
        }
    }
    
    private func importChemicalTags(_ lines: ArraySlice<String>) {
        // Implementation depends on how you want to handle existing relationships
        // This would need careful consideration of existing data
    }
    
    private func importFormulas(_ lines: ArraySlice<String>) {
        for line in lines where !line.isEmpty {
            let fields = line.components(separatedBy: ",")
            guard fields.count >= 6 else { continue }
            
            let formula = Formula(
                name: fields[1],
                smellDescription: fields[2],
                diluentType: fields[3],
                diluentWeight: Double(fields[4]) ?? 0
            )
            modelContext.insert(formula)
        }
    }
    
    private func importFormulaLines(_ lines: ArraySlice<String>) {
        // Implementation depends on how you want to handle existing relationships
        // This would need careful consideration of existing data
    }
}

// Mail Composer View
struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let body: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.setSubject(subject)
        mail.setMessageBody(body, isHTML: false)
        mail.setToRecipients(["ffin@pm.me"])
        mail.mailComposeDelegate = context.coordinator
        return mail
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

// CSV Document for Export
struct CSVDocument: FileDocument {
    var data: String
    
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    init(data: String) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = self.data.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

extension Color {
    static var random: Color {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}
