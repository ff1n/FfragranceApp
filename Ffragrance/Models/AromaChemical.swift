// AromaChemical.swift
import SwiftUI
import SwiftData

@Model
final class AromaChemical {
    var id: UUID = UUID()
    var name: String = ""
    var casNumber: String = ""
    var ifraSafeLimit: Double?
    var notes: String = ""
    var pyramidNote: String = "top"
    var unit: String = "grams"
    var quantityGrams: Double?
    var quantityMl: Double?
    var dilutionPercentage: Double?
    var structureImageData: Data?
    
    @Relationship var category: Category?
    @Relationship var tags: [Tag]? = []
    @Relationship var formulaLines: [FormulaLine]? = []
    
    init(name: String = "", casNumber: String = "", ifraSafeLimit: Double? = nil, notes: String = "",
         pyramidNote: String = "top", unit: String = "grams", quantityGrams: Double? = nil,
         quantityMl: Double? = nil, dilutionPercentage: Double? = nil, category: Category? = nil) {
        self.name = name
        self.casNumber = casNumber
        self.ifraSafeLimit = ifraSafeLimit
        self.notes = notes
        self.pyramidNote = pyramidNote
        self.unit = unit
        self.quantityGrams = quantityGrams
        self.quantityMl = quantityMl
        self.dilutionPercentage = dilutionPercentage
        self.category = category
        self.tags = []
        self.formulaLines = []
    }
    
    func addTag(_ tag: Tag) {
        guard let tags = tags else {
            self.tags = [tag]
            return
        }
        if !tags.contains(where: { $0.id == tag.id }) {
            self.tags?.append(tag)
        }
    }
    
    func removeTag(_ tag: Tag) {
        tags?.removeAll(where: { $0.id == tag.id })
    }
}
