import Observation
import SwiftUI

/// Observable state machine that drives sheet position, snapping, and gesture coordination.
///
/// ``DraggableSheet`` reads this model to position the sheet and manage drag/scroll handoff.
/// Create a single instance and pass it to ``BackgroundSheetScene`` or ``DraggableSheet``
/// to observe ``snapState`` from your own UI.
///
/// ```swift
/// @State private var sheetModel = SheetStateModel()
///
/// BackgroundSheetScene(sheetModel: sheetModel) {
///     mapView
/// } sheetContent: {
///     detailView
/// }
/// ```
@MainActor
@Observable
public final class SheetStateModel {
    /// The detent the sheet rests on when not being dragged.
    public var snapState: SheetSnapState

    /// Current in-progress vertical drag translation. Zero when idle.
    public var dragTranslation: CGFloat = 0

    /// Vertical velocity inferred from the last completed drag's predicted translation.
    public var lastDragVelocityY: CGFloat = 0

    /// Which interaction currently owns gesture handling.
    public var gestureOwner: GestureOwner = .background

    /// Vertical scroll offset of the sheet's inner content.
    public var contentOffsetY: CGFloat = 0

    private var dragOriginOffset: CGFloat = 0
    private let snapEngine = SheetSnapEngine()

    /// Creates a model with the given initial resting detent.
    ///
    /// - Parameter initialSnapState: Starting detent. Defaults to ``SheetSnapState/half``.
    public init(initialSnapState: SheetSnapState = .half) {
        snapState = initialSnapState
    }

    /// Begins a sheet drag from the current detent's resting offset.
    ///
    /// Sets ``gestureOwner`` to ``GestureOwner/sheetDrag`` and records the origin offset
    /// so subsequent ``updateDrag(translationY:)`` calls are relative to this position.
    public func startDrag(containerHeight: CGFloat, bottomInset: CGFloat) {
        gestureOwner = .sheetDrag
        dragOriginOffset = snapState.yOffset(in: containerHeight, bottomInset: bottomInset)
    }

    /// Updates the in-progress drag translation.
    public func updateDrag(translationY: CGFloat) {
        dragTranslation = translationY
    }

    /// Ends a drag, snaps to the nearest detent, and resets gesture state.
    ///
    /// Uses the predicted end translation to resolve the target detent so quick flicks
    /// snap naturally. Stores the inferred velocity in ``lastDragVelocityY``.
    ///
    /// - Parameters:
    ///   - translationY: Final drag translation.
    ///   - predictedEndTranslationY: Predicted end translation from the drag gesture.
    ///   - containerHeight: Height of the sheet container.
    ///   - bottomInset: Bottom safe-area inset.
    public func finishDrag(
        translationY: CGFloat,
        predictedEndTranslationY: CGFloat,
        containerHeight: CGFloat,
        bottomInset: CGFloat
    ) {
        let projectedEndOffset = dragOriginOffset + predictedEndTranslationY
        let currentOffset = dragOriginOffset + translationY
        lastDragVelocityY = predictedEndTranslationY - translationY
        dragTranslation = 0

        let target = snapEngine.resolveTargetState(
            projectedOffset: projectedEndOffset,
            currentOffset: currentOffset,
            containerHeight: containerHeight,
            bottomInset: bottomInset
        )
        snapState = target
        gestureOwner = .background
    }

    /// The y-offset for the current ``snapState`` without any in-progress drag.
    public func restingOffset(containerHeight: CGFloat, bottomInset: CGFloat) -> CGFloat {
        snapState.yOffset(in: containerHeight, bottomInset: bottomInset)
    }

    /// The y-offset including in-progress drag, clamped between expanded and collapsed bounds.
    public func activeOffset(containerHeight: CGFloat, bottomInset: CGFloat) -> CGFloat {
        let offset = restingOffset(containerHeight: containerHeight, bottomInset: bottomInset) + dragTranslation
        let minY = SheetSnapState.expanded.yOffset(in: containerHeight, bottomInset: bottomInset)
        let maxY = SheetSnapState.collapsed.yOffset(in: containerHeight, bottomInset: bottomInset)
        return min(max(offset, minY), maxY)
    }

    /// Records the vertical scroll offset of the sheet's inner content.
    public func updateScrollOffset(_ value: CGFloat) {
        contentOffsetY = value
    }

    /// Marks the sheet content scroll gesture as active.
    ///
    /// Does not override an in-progress sheet drag.
    public func startScrollGesture() {
        if gestureOwner != .sheetDrag {
            gestureOwner = .sheetScroll
        }
    }

    /// Ends the sheet content scroll gesture if it is currently active.
    public func endScrollGesture() {
        if gestureOwner == .sheetScroll {
            gestureOwner = .background
        }
    }

    /// Whether a vertical drag in the content area should move the sheet instead of scrolling.
    ///
    /// When not expanded, all content drags hand off to the sheet. When expanded, only
    /// downward drags at scroll top (`contentOffsetY ≤ 1`) hand off to the sheet.
    ///
    /// - Parameter dragTranslationY: Vertical translation of the content drag gesture.
    /// - Returns: `true` if the drag should collapse/move the sheet; `false` if scrolling should proceed.
    public func shouldHandoffScrollToSheet(dragTranslationY: CGFloat) -> Bool {
        guard snapState == .expanded else {
            return true
        }
        return contentOffsetY <= 1 && dragTranslationY > 0
    }
}
