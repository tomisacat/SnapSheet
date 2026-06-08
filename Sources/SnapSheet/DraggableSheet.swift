import SwiftUI

/// A floating bottom sheet with a drag handle, snap-to-detent behavior, and scroll handoff.
///
/// The sheet is positioned via ``SheetStateModel/activeOffset(containerHeight:bottomInset:)``
/// and animates between detents on snap. Use ``BackgroundSheetScene`` for a higher-level
/// composition that handles geometry automatically.
///
/// ### Gestures
///
/// - **Handle drag** — always moves the sheet.
/// - **Content drag** — scrolls when expanded; otherwise moves the sheet. At scroll top,
///   downward drags hand off to sheet dragging (see ``SheetStateModel/shouldHandoffScrollToSheet(dragTranslationY:)``).
///
/// ```swift
/// DraggableSheet(
///     model: sheetModel,
///     containerHeight: height,
///     bottomInset: safeBottom
/// ) {
///     Text("Sheet content")
/// }
/// ```
public struct DraggableSheet<SheetContent: View>: View {
    /// Observable state driving sheet offset, snapping, and gesture coordination.
    @Bindable private var model: SheetStateModel

    /// Total height of the layout container, typically the screen height from a `GeometryReader`.
    private let containerHeight: CGFloat

    /// Bottom safe-area inset from the container, used for detent math and ``View/safeAreaPadding(_:)``.
    private let bottomInset: CGFloat

    /// Visual configuration for the sheet's corner radius, handle, and content padding.
    private let style: SheetStyle

    /// Content placed inside the sheet's scroll area.
    private let sheetContent: SheetContent

    /// Whether the scroll gesture is active.
    @State private var isScrollGestureActive = false

    /// Creates a draggable sheet bound to the given state model.
    ///
    /// - Parameters:
    ///   - model: Observable model driving position and gestures.
    ///   - containerHeight: Total height of the layout container (screen height).
    ///   - bottomInset: System bottom safe-area inset from a `GeometryReader` (e.g. `proxy.safeAreaInsets.bottom`).
    ///   - style: Visual configuration. Defaults to ``SheetStyle/standard``.
    ///   - sheetContent: Content placed inside the sheet's scroll area.
    public init(
        model: SheetStateModel,
        containerHeight: CGFloat,
        bottomInset: CGFloat,
        style: SheetStyle = .standard,
        @ViewBuilder sheetContent: () -> SheetContent
    ) {
        _model = Bindable(model)
        self.containerHeight = containerHeight
        self.bottomInset = bottomInset
        self.style = style
        self.sheetContent = sheetContent()
    }

    public var body: some View {
        VStack(spacing: 14) {
            handleArea
            contentArea
        }
        .safeAreaPadding(EdgeInsets(top: 0, leading: 0, bottom: bottomInset, trailing: 0))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 16, y: -1)
        .offset(y: model.activeOffset(containerHeight: containerHeight, bottomInset: bottomInset))
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: model.snapState)
        .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.9), value: model.dragTranslation)
        .accessibilityElement(children: .contain)
    }

    private var handleArea: some View {
        Capsule()
            .fill(.secondary)
            .frame(width: style.handleWidth, height: style.handleHeight)
            .padding(.top, 10)
            .accessibilityLabel("Drag handle")
            .padding(.bottom, 6)
            .contentShape(Rectangle())
            .gesture(sheetDragGesture)
    }

    private var contentArea: some View {
        ScrollView(.vertical, showsIndicators: true) {
            sheetContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, style.contentHorizontalPadding)
                .padding(.bottom, style.contentBottomPadding)
        }
        .scrollDisabled(model.snapState != .expanded || model.gestureOwner == .sheetDrag)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newValue in
            model.updateScrollOffset(newValue)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    if model.shouldHandoffScrollToSheet(dragTranslationY: value.translation.height) {
                        isScrollGestureActive = false
                        if model.dragTranslation == 0 {
                            model.startDrag(containerHeight: containerHeight, bottomInset: bottomInset)
                        }
                        model.updateDrag(translationY: value.translation.height)
                    } else if !isScrollGestureActive {
                        isScrollGestureActive = true
                        model.startScrollGesture()
                    }
                }
                .onEnded { value in
                    if model.gestureOwner == .sheetDrag {
                        model.finishDrag(
                            translationY: value.translation.height,
                            predictedEndTranslationY: value.predictedEndTranslation.height,
                            containerHeight: containerHeight,
                            bottomInset: bottomInset
                        )
                    } else {
                        model.endScrollGesture()
                    }
                    isScrollGestureActive = false
                }
        )
    }

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if model.dragTranslation == 0 {
                    model.startDrag(containerHeight: containerHeight, bottomInset: bottomInset)
                }
                model.updateDrag(translationY: value.translation.height)
            }
            .onEnded { value in
                model.finishDrag(
                    translationY: value.translation.height,
                    predictedEndTranslationY: value.predictedEndTranslation.height,
                    containerHeight: containerHeight,
                    bottomInset: bottomInset
                )
            }
    }
}
