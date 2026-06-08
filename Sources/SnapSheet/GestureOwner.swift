/// Identifies which user interaction currently owns gesture handling for the sheet scene.
///
/// SnapSheet uses this to coordinate drag, scroll, and background interactions so they
/// do not conflict. The value is tracked on ``SheetStateModel/gestureOwner``.
public enum GestureOwner: Equatable, Sendable {
    /// No sheet gesture is active; the background or other UI may receive touches.
    case background

    /// The user is dragging the sheet via the handle or a scroll-to-sheet handoff.
    case sheetDrag

    /// The user is scrolling content inside the expanded sheet.
    case sheetScroll
}
