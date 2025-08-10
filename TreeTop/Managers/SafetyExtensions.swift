import Foundation
import SwiftUI

// Extension to safely handle Double values and prevent NaN from reaching CoreGraphics
extension Double {
    var safeValue: Double {
        if self.isNaN || self.isInfinite {
            return 0.0
        }
        return self
    }
    
    func safeClamped(to range: ClosedRange<Double>) -> Double {
        let safe = self.safeValue
        return min(max(safe, range.lowerBound), range.upperBound)
    }
}

// Extension for CGFloat to prevent NaN values
extension CGFloat {
    var safeValue: CGFloat {
        if self.isNaN || self.isInfinite {
            return 0.0
        }
        return self
    }
}

// Extension for safe progress calculations
extension ProgressView where CurrentValueLabel == EmptyView, Label == EmptyView {
    static func safeBounded(value: Double, total: Double) -> ProgressView {
        let safeValue = value.safeValue.safeClamped(to: 0...total.safeValue)
        let safeTotal = max(1.0, total.safeValue)
        return ProgressView(value: safeValue, total: safeTotal)
    }
}
