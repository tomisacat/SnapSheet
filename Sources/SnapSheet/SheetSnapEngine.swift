import CoreGraphics

struct SheetSnapEngine {
    func resolveTargetState(
        projectedOffset: CGFloat,
        currentOffset: CGFloat,
        containerHeight: CGFloat,
        bottomInset: CGFloat
    ) -> SheetSnapState {
        let targetOffset = projectedOffset.isFinite ? projectedOffset : currentOffset

        return SheetSnapState.allCases.min { lhs, rhs in
            let lhsDistance = abs(lhs.yOffset(in: containerHeight, bottomInset: bottomInset) - targetOffset)
            let rhsDistance = abs(rhs.yOffset(in: containerHeight, bottomInset: bottomInset) - targetOffset)
            return lhsDistance < rhsDistance
        } ?? .half
    }
}
