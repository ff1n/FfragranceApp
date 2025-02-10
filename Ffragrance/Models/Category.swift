//
//  Category.swift
//  Ffragrance
//
//  Created by Ffinian Elliott on 13/01/2025.
//

import SwiftData
import SwiftUI
import Foundation

@Model
class Category {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#808080"

    @Relationship var chemicals: [AromaChemical]? = []

    var color: Color {
        get {
            Color(hex: colorHex) ?? .gray
        }
        set {
            colorHex = newValue.toHex() ?? "#808080"
        }
    }

    init(name: String, color: Color) {
        self.name = name
        self.colorHex = color.toHex() ?? "#808080"
        self.chemicals = []
    }
}
