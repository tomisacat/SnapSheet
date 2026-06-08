import SwiftUI

/// Canonical resting heights for a draggable bottom sheet over a background view.
///
/// The sheet settles on one of these detents after a drag ends.
/// ``yOffset(in:bottomInset:)`` maps each case to a vertical offset from the top of the screen.
///
/// Detents are ordered from most expanded (smallest offset) to most collapsed (largest offset):
///
/// ```
/// expanded  →  half  →  collapsed
/// ```
public enum SheetSnapState: CaseIterable, Sendable {
    /// Minimal sheet height: background dominates; small preview strip at the bottom.
    case collapsed

    /// Default balance between background and sheet content.
    case half

    /// Sheet dominates the screen; background remains visible behind.
    case expanded

    /// Returns the resting y-offset from the top of the screen for this detent.
    ///
    /// - Parameters:
    ///   - height: Total height of the sheet container (typically the screen height).
    ///   - bottomInset: Bottom safe-area inset (home indicator, etc.).
    /// - Returns: A y-offset applied via ``View/offset(y:)`` to position the sheet.
    ///
    /// | Detent | Formula |
    /// |--------|---------|
    /// | `.collapsed` | `max(height × 0.76, height − 180 − bottomInset)` |
    /// | `.half` | `height × 0.48` |
    /// | `.expanded` | `max(70, height × 0.12)` |
    public func yOffset(in height: CGFloat, bottomInset: CGFloat) -> CGFloat {
        switch self {
        case .collapsed:
            return max(height * 0.76, height - 180 - bottomInset)
        case .half:
            return height * 0.48
        case .expanded:
            return max(70, height * 0.12)
        }
    }
}
