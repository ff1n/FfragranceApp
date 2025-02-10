import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

@Model
final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var red: Double = 0.0
    var green: Double = 0.0
    var blue: Double = 0.0
    var alpha: Double = 1.0
    
    @Relationship var chemicals: [AromaChemical]? = []
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    init(name: String = "", color: Color = .blue) {
        self.name = name
        
        let resolved = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
        self.chemicals = []
    }
}
