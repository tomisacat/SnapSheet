import CoreGraphics
import Testing
@testable import SnapSheet

// MARK: - Helpers

private let standardHeight: CGFloat = 844
private let standardBottomInset: CGFloat = 34

private func expectEqual(
    _ lhs: CGFloat,
    _ rhs: CGFloat,
    accuracy: CGFloat = 0.001,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(abs(lhs - rhs) <= accuracy, sourceLocation: sourceLocation)
}

// MARK: - SheetSnapState

struct SheetSnapStateTests {
    @Test func halfOffsetIsProportionalToHeight() {
        expectEqual(SheetSnapState.half.yOffset(in: 800, bottomInset: 0), 384)
        expectEqual(SheetSnapState.half.yOffset(in: 600, bottomInset: 20), 288)
    }

    @Test func expandedOffsetUsesMinimumFloor() {
        expectEqual(SheetSnapState.expanded.yOffset(in: 400, bottomInset: 0), 70)
        expectEqual(SheetSnapState.expanded.yOffset(in: 800, bottomInset: 0), 96)
    }

    @Test func collapsedOffsetUsesLargerOfRatioAndPeekHeight() {
        expectEqual(SheetSnapState.collapsed.yOffset(in: 800, bottomInset: 0), 620)
        expectEqual(SheetSnapState.collapsed.yOffset(in: 800, bottomInset: 34), 608)
        expectEqual(SheetSnapState.collapsed.yOffset(in: 300, bottomInset: 0), 228)
    }

    @Test func collapsedOffsetAccountsForBottomInsetOnTallScreens() {
        expectEqual(SheetSnapState.collapsed.yOffset(in: 1_000, bottomInset: 0), 820)
        expectEqual(SheetSnapState.collapsed.yOffset(in: 1_000, bottomInset: 34), 786)
    }

    @Test func snapStatesIncreaseFromExpandedToCollapsed() {
        let expanded = SheetSnapState.expanded.yOffset(in: standardHeight, bottomInset: standardBottomInset)
        let half = SheetSnapState.half.yOffset(in: standardHeight, bottomInset: standardBottomInset)
        let collapsed = SheetSnapState.collapsed.yOffset(in: standardHeight, bottomInset: standardBottomInset)

        #expect(expanded < half)
        #expect(half < collapsed)
    }
}

// MARK: - SheetSnapEngine

struct SheetSnapEngineTests {
    private let engine = SheetSnapEngine()

    @Test func resolvesNearestSnapStateToProjectedOffset() {
        let height = standardHeight
        let inset = standardBottomInset
        let expanded = SheetSnapState.expanded.yOffset(in: height, bottomInset: inset)
        let half = SheetSnapState.half.yOffset(in: height, bottomInset: inset)
        let collapsed = SheetSnapState.collapsed.yOffset(in: height, bottomInset: inset)

        #expect(engine.resolveTargetState(
            projectedOffset: expanded + 5,
            currentOffset: half,
            containerHeight: height,
            bottomInset: inset
        ) == .expanded)

        #expect(engine.resolveTargetState(
            projectedOffset: half,
            currentOffset: expanded,
            containerHeight: height,
            bottomInset: inset
        ) == .half)

        #expect(engine.resolveTargetState(
            projectedOffset: collapsed - 10,
            currentOffset: half,
            containerHeight: height,
            bottomInset: inset
        ) == .collapsed)
    }

    @Test func usesCurrentOffsetWhenProjectedOffsetIsNonFinite() {
        let height = standardHeight
        let inset = standardBottomInset
        let half = SheetSnapState.half.yOffset(in: height, bottomInset: inset)

        #expect(engine.resolveTargetState(
            projectedOffset: .infinity,
            currentOffset: half,
            containerHeight: height,
            bottomInset: inset
        ) == .half)

        #expect(engine.resolveTargetState(
            projectedOffset: .nan,
            currentOffset: SheetSnapState.expanded.yOffset(in: height, bottomInset: inset),
            containerHeight: height,
            bottomInset: inset
        ) == .expanded)
    }

    @Test func midpointBetweenHalfAndCollapsedSnapsToCloserState() {
        let height = standardHeight
        let inset = standardBottomInset
        let half = SheetSnapState.half.yOffset(in: height, bottomInset: inset)
        let collapsed = SheetSnapState.collapsed.yOffset(in: height, bottomInset: inset)
        let midpoint = (half + collapsed) / 2

        let belowMidpoint = engine.resolveTargetState(
            projectedOffset: midpoint - 1,
            currentOffset: half,
            containerHeight: height,
            bottomInset: inset
        )
        let aboveMidpoint = engine.resolveTargetState(
            projectedOffset: midpoint + 1,
            currentOffset: half,
            containerHeight: height,
            bottomInset: inset
        )

        #expect(belowMidpoint == .half)
        #expect(aboveMidpoint == .collapsed)
    }
}

// MARK: - SheetStateModel

@MainActor
struct SheetStateModelTests {
    @Test func initializesWithRequestedSnapState() {
        let model = SheetStateModel(initialSnapState: .expanded)
        #expect(model.snapState == .expanded)
        #expect(model.dragTranslation == 0)
        #expect(model.gestureOwner == .background)
        #expect(model.contentOffsetY == 0)
    }

    @Test func startDragCapturesOriginAndClaimsGestureOwnership() {
        let model = SheetStateModel(initialSnapState: .half)
        model.startDrag(containerHeight: standardHeight, bottomInset: standardBottomInset)

        #expect(model.gestureOwner == .sheetDrag)
        expectEqual(
            model.restingOffset(containerHeight: standardHeight, bottomInset: standardBottomInset),
            SheetSnapState.half.yOffset(in: standardHeight, bottomInset: standardBottomInset)
        )
    }

    @Test func updateDragChangesActiveOffsetWithoutChangingSnapState() {
        let model = SheetStateModel(initialSnapState: .half)
        model.startDrag(containerHeight: standardHeight, bottomInset: standardBottomInset)
        model.updateDrag(translationY: 40)

        #expect(model.dragTranslation == 40)
        #expect(model.snapState == .half)
        expectEqual(
            model.activeOffset(containerHeight: standardHeight, bottomInset: standardBottomInset),
            model.restingOffset(containerHeight: standardHeight, bottomInset: standardBottomInset) + 40
        )
    }

    @Test func activeOffsetClampsToExpandedAndCollapsedBounds() {
        let model = SheetStateModel(initialSnapState: .half)
        model.startDrag(containerHeight: standardHeight, bottomInset: standardBottomInset)

        let minY = SheetSnapState.expanded.yOffset(in: standardHeight, bottomInset: standardBottomInset)
        let maxY = SheetSnapState.collapsed.yOffset(in: standardHeight, bottomInset: standardBottomInset)

        model.updateDrag(translationY: -10_000)
        expectEqual(model.activeOffset(containerHeight: standardHeight, bottomInset: standardBottomInset), minY)

        model.updateDrag(translationY: 10_000)
        expectEqual(model.activeOffset(containerHeight: standardHeight, bottomInset: standardBottomInset), maxY)
    }

    @Test func finishDragSnapsToNearestStateAndResetsDrag() {
        let model = SheetStateModel(initialSnapState: .half)
        model.startDrag(containerHeight: standardHeight, bottomInset: standardBottomInset)

        let origin = SheetSnapState.half.yOffset(in: standardHeight, bottomInset: standardBottomInset)
        let expanded = SheetSnapState.expanded.yOffset(in: standardHeight, bottomInset: standardBottomInset)
        let translation: CGFloat = expanded - origin
        let predicted: CGFloat = translation + 20

        model.finishDrag(
            translationY: translation,
            predictedEndTranslationY: predicted,
            containerHeight: standardHeight,
            bottomInset: standardBottomInset
        )

        #expect(model.snapState == .expanded)
        #expect(model.dragTranslation == 0)
        #expect(model.gestureOwner == .background)
        #expect(model.lastDragVelocityY == predicted - translation)
    }

    @Test func finishDragFromCollapsedCanSnapToHalf() {
        let model = SheetStateModel(initialSnapState: .collapsed)
        model.startDrag(containerHeight: standardHeight, bottomInset: standardBottomInset)

        let origin = SheetSnapState.collapsed.yOffset(in: standardHeight, bottomInset: standardBottomInset)
        let half = SheetSnapState.half.yOffset(in: standardHeight, bottomInset: standardBottomInset)
        let translation = half - origin

        model.finishDrag(
            translationY: translation,
            predictedEndTranslationY: translation,
            containerHeight: standardHeight,
            bottomInset: standardBottomInset
        )

        #expect(model.snapState == .half)
    }

    @Test func scrollGestureLifecycleUpdatesGestureOwner() {
        let model = SheetStateModel()

        model.startScrollGesture()
        #expect(model.gestureOwner == .sheetScroll)

        model.endScrollGesture()
        #expect(model.gestureOwner == .background)
    }

    @Test func startScrollGestureDoesNotOverrideSheetDrag() {
        let model = SheetStateModel()
        model.startDrag(containerHeight: standardHeight, bottomInset: standardBottomInset)

        model.startScrollGesture()
        #expect(model.gestureOwner == .sheetDrag)
    }

    @Test func endScrollGestureOnlyClearsSheetScrollOwnership() {
        let model = SheetStateModel()
        model.startDrag(containerHeight: standardHeight, bottomInset: standardBottomInset)

        model.endScrollGesture()
        #expect(model.gestureOwner == .sheetDrag)
    }

    @Test func updateScrollOffsetStoresContentOffset() {
        let model = SheetStateModel()
        model.updateScrollOffset(120)
        #expect(model.contentOffsetY == 120)
    }

    @Test(arguments: [
        (SheetSnapState.collapsed, 0, 10, true),
        (SheetSnapState.half, 0, 10, true),
        (SheetSnapState.expanded, 0, 10, true),
        (SheetSnapState.expanded, 0, -10, false),
        (SheetSnapState.expanded, 5, 10, false),
        (SheetSnapState.expanded, 1, 10, true),
        (SheetSnapState.expanded, 0.5, 10, true),
        (SheetSnapState.expanded, 0, 0, false),
    ] as [(SheetSnapState, CGFloat, CGFloat, Bool)])
    func shouldHandoffScrollToSheet(
        snapState: SheetSnapState,
        contentOffset: CGFloat,
        dragTranslation: CGFloat,
        expected: Bool
    ) {
        let model = SheetStateModel(initialSnapState: snapState)
        model.updateScrollOffset(contentOffset)

        #expect(model.shouldHandoffScrollToSheet(dragTranslationY: dragTranslation) == expected)
    }
}

// MARK: - SheetStyle

struct SheetStyleTests {
    @Test func standardStyleUsesDocumentedDefaults() {
        let style = SheetStyle.standard
        #expect(style.cornerRadius == 24)
        #expect(style.handleWidth == 44)
        #expect(style.handleHeight == 5)
        #expect(style.contentHorizontalPadding == 20)
        #expect(style.contentBottomPadding == 40)
    }

    @Test func customInitializerStoresProvidedValues() {
        let style = SheetStyle(
            cornerRadius: 12,
            handleWidth: 30,
            handleHeight: 4,
            contentHorizontalPadding: 16,
            contentBottomPadding: 24
        )

        #expect(style.cornerRadius == 12)
        #expect(style.handleWidth == 30)
        #expect(style.handleHeight == 4)
        #expect(style.contentHorizontalPadding == 16)
        #expect(style.contentBottomPadding == 24)
    }
}

// MARK: - GestureOwner

struct GestureOwnerTests {
    @Test func casesAreDistinct() {
        #expect(GestureOwner.background != .sheetDrag)
        #expect(GestureOwner.sheetDrag != .sheetScroll)
        #expect(GestureOwner.background != .sheetScroll)
    }
}
