import SwiftData
import Foundation

@Model
class FormulaLine {
    var id: UUID = UUID()
    var amountGrams: Double = 0.0
    var dilutionPercentage: Double = 100.0
    
    var chemical: AromaChemical?
    var formula: Formula?
    
    init(
        chemical: AromaChemical? = nil,
        amountGrams: Double = 0.0,
        dilutionPercentage: Double = 100.0
    ) {
        self.chemical = chemical
        self.amountGrams = amountGrams
        self.dilutionPercentage = dilutionPercentage
    }
}

@Model
class Formula {
    var id: UUID = UUID()
    var name: String = ""
    var smellDescription: String?
    var diluentType: String?
    var diluentWeight: Double = 0.0
    
    var lines: [FormulaLine]? = []
    
    init(
        name: String = "",
        smellDescription: String? = nil,
        diluentType: String? = nil,
        diluentWeight: Double = 0.0
    ) {
        self.name = name
        self.smellDescription = smellDescription
        self.diluentType = diluentType
        self.diluentWeight = diluentWeight
        self.lines = []
    }
    
    var totalLineWeight: Double {
        lines?.reduce(0.0) { $0 + $1.amountGrams } ?? 0.0
    }
    
    var totalFormulaWeight: Double {
        totalLineWeight + diluentWeight
    }
    
    var dilutedComponents: [DilutedComponent]? {
        guard let lines = lines else { return nil }
        return lines.compactMap { line in
            guard let chemical = line.chemical else { return nil }
            
            let lineActualMass = line.amountGrams * (line.dilutionPercentage / 100.0)
            let finalConcentration = totalFormulaWeight > 0
                ? (lineActualMass / totalFormulaWeight) * 100
                : 0.0
            
            let isOverLimit = chemical.ifraSafeLimit.map { finalConcentration > $0 } ?? false
            
            return DilutedComponent(
                chemical: chemical,
                lineID: line.id,
                originalAmount: line.amountGrams,
                dilutionPercentage: line.dilutionPercentage,
                finalConcentration: finalConcentration,
                isOverLimit: isOverLimit
            )
        }
    }
}

struct DilutedComponent: Identifiable {
    var id: UUID { lineID }
    let chemical: AromaChemical
    let lineID: UUID
    let originalAmount: Double
    let dilutionPercentage: Double
    let finalConcentration: Double
    let isOverLimit: Bool
}
