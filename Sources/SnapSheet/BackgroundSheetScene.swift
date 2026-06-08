import SwiftUI

/// Composes a full-screen background view with a draggable floating sheet overlay.
///
/// This is the primary entry point for SnapSheet. It reads container geometry and
/// safe-area insets, then overlays a ``DraggableSheet`` on top of your background.
///
/// ```swift
/// BackgroundSheetScene {
///     Map()
/// } sheetContent: {
///     PlaceDetailView()
/// }
/// ```
///
/// Pass a shared ``SheetStateModel`` to observe or control the snap detent from
/// your background UI:
///
/// ```swift
/// @State private var sheetModel = SheetStateModel()
///
/// BackgroundSheetScene(sheetModel: sheetModel) {
///     background
/// } sheetContent: {
///     content
/// }
/// ```
public struct BackgroundSheetScene<Background: View, SheetContent: View>: View {
    /// Observable model passed to the overlaid ``DraggableSheet`` for snap state and gestures.
    @State private var sheetModel: SheetStateModel

    /// Visual configuration applied to the overlaid sheet.
    private let style: SheetStyle

    /// Full-screen host content rendered behind the sheet.
    private let background: Background

    /// Scrollable content rendered inside the floating sheet.
    private let sheetContent: SheetContent

    /// Creates a background + sheet scene.
    ///
    /// - Parameters:
    ///   - sheetModel: Observable model for snap state and gestures. A new instance is
    ///     created by default. Pass a shared model to read ``SheetStateModel/snapState``
    ///     from outside the scene.
    ///   - style: Visual configuration for the sheet. Defaults to ``SheetStyle/standard``.
    ///   - background: Full-screen content placed behind the sheet (map, image, etc.).
    ///   - sheetContent: Scrollable content inside the floating sheet.
    public init(
        sheetModel: SheetStateModel = SheetStateModel(),
        style: SheetStyle = .standard,
        @ViewBuilder background: () -> Background,
        @ViewBuilder sheetContent: () -> SheetContent
    ) {
        _sheetModel = State(initialValue: sheetModel)
        self.style = style
        self.background = background()
        self.sheetContent = sheetContent()
    }

    public var body: some View {
        GeometryReader { proxy in
            let safeBottom = proxy.safeAreaInsets.bottom
            let height = proxy.size.height

            ZStack(alignment: .top) {
                background
                    .ignoresSafeArea()

                DraggableSheet(
                    model: sheetModel,
                    containerHeight: height,
                    bottomInset: safeBottom,
                    style: style
                ) {
                    sheetContent
                }
            }
        }
    }
}
