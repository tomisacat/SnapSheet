import SwiftUI

/// Visual configuration for a ``DraggableSheet``'s chrome and content layout.
///
/// Use ``standard`` for the default appearance, or create a custom instance to tune
/// corner radius, handle dimensions, and content padding.
///
/// ```swift
/// DraggableSheet(
///     model: model,
///     containerHeight: height,
///     bottomInset: inset,
///     style: SheetStyle(cornerRadius: 16, handleWidth: 36)
/// ) {
///     sheetContent
/// }
/// ```
public struct SheetStyle: Sendable {
    /// Corner radius applied to the sheet's rounded rectangle clip and border.
    public var cornerRadius: CGFloat

    /// Width of the capsule drag handle.
    public var handleWidth: CGFloat

    /// Height of the capsule drag handle.
    public var handleHeight: CGFloat

    /// Horizontal padding applied inside the sheet's scroll content.
    public var contentHorizontalPadding: CGFloat

    /// Bottom padding applied inside the sheet's scroll content.
    ///
    /// The device's bottom safe-area inset is added automatically by ``DraggableSheet``.
    public var contentBottomPadding: CGFloat

    /// Creates a sheet style with the given dimensions.
    ///
    /// - Parameters:
    ///   - cornerRadius: Corner radius for the sheet container. Default is `24`.
    ///   - handleWidth: Width of the drag handle. Default is `44`.
    ///   - handleHeight: Height of the drag handle. Default is `5`.
    ///   - contentHorizontalPadding: Inner horizontal padding. Default is `20`.
    ///   - contentBottomPadding: Inner bottom padding. Default is `40`.
    public init(
        cornerRadius: CGFloat = 24,
        handleWidth: CGFloat = 44,
        handleHeight: CGFloat = 5,
        contentHorizontalPadding: CGFloat = 20,
        contentBottomPadding: CGFloat = 40
    ) {
        self.cornerRadius = cornerRadius
        self.handleWidth = handleWidth
        self.handleHeight = handleHeight
        self.contentHorizontalPadding = contentHorizontalPadding
        self.contentBottomPadding = contentBottomPadding
    }

    /// The default sheet style used when no custom style is provided.
    public static let standard = SheetStyle()
}
