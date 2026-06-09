# SnapSheet

**A pure SwiftUI bottom sheet for iOS 18+.**

SnapSheet composes a full-screen background view with a draggable, snap-to-detent floating panel — the map + sheet pattern you see in Apple Maps — built entirely with SwiftUI. No UIKit bridges, no `UIViewControllerRepresentable`, and no system sheet presentation controllers.

## Demo

<p align="center">
  <a href="docs/media/SnapSheet-Demo.mov">
    <img src="docs/media/SnapSheet-Demo-poster.png" alt="SnapSheet demo — drag the sheet between snap detents" height="600">
  </a>
</p>

<p align="center">
  <a href="docs/media/SnapSheet-Demo.mov">▶ Watch full demo (23s)</a>
</p>

Snap, scroll, and detent controls in the [demo app](Examples/SnapSheetDemo/) — drag the sheet handle, flick between detents, tap detent chips, and scroll the place list when expanded.

## Features

- **Pure SwiftUI** — no UIKit integration required; works naturally with your existing SwiftUI app
- **Three snap detents** — collapsed, half, and expanded resting positions
- **Velocity-aware snapping** — uses `DragGesture` predicted end translation so flicks feel natural
- **Scroll handoff** — `ScrollView` scrolls when expanded; downward drags at scroll top collapse the sheet
- **Composable API** — use the all-in-one `BackgroundSheetScene` or assemble `DraggableSheet` yourself
- **Customizable styling** — corner radius, handle size, and content padding via `SheetStyle`
- **Observable state** — share a `SheetStateModel` to read snap state from your UI

## Requirements

| | |
|---|---|
| **Platforms** | iOS 18+ |
| **Swift** | 6.2+ |

## Installation

### Swift Package Manager

Add SnapSheet as a dependency in Xcode (**File → Add Package Dependencies…**) or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tomisacat/SnapSheet.git", from: "1.0.0"),
],
targets: [
    .target(
        name: "<YourAppTarget>",
        dependencies: ["SnapSheet"]
    ),
]
```

For local development, point to the package directory:

```swift
.package(path: "../SnapSheet")
```

## Quick Start

The fastest integration uses `BackgroundSheetScene`, which wires up geometry, safe-area insets, and the sheet for you:

```swift
import SnapSheet
import SwiftUI

struct ContentView: View {
    var body: some View {
        BackgroundSheetScene {
            // Full-screen background (map, image, custom view, etc.)
            Map()
        } sheetContent: {
            VStack(alignment: .leading, spacing: 16) {
                Text("Details")
                    .font(.title2.bold())
                Text("Drag the handle to snap between detents.")
            }
        }
    }
}
```

### Observing snap state

Pass a shared `SheetStateModel` to react to detent changes in your background UI:

```swift
@State private var sheetModel = SheetStateModel(initialSnapState: .half)

var body: some View {
    BackgroundSheetScene(sheetModel: sheetModel) {
        background
    } sheetContent: {
        sheetContent
    }
}

// Read sheetModel.snapState anywhere in the view tree
```

### Custom styling

```swift
BackgroundSheetScene(
    style: SheetStyle(
        cornerRadius: 20,
        handleWidth: 36,
        handleHeight: 4,
        contentHorizontalPadding: 16,
        contentBottomPadding: 32
    )
) {
    background
} sheetContent: {
    sheetContent
}
```

## Architecture

See **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** for the full architecture guide, including:

- Component and view-hierarchy diagrams
- State model and snap-resolution flow
- Gesture coordination and scroll handoff rules
- File map and extension points

| Type | Role |
|------|------|
| [`BackgroundSheetScene`](Sources/SnapSheet/BackgroundSheetScene.swift) | Top-level scene combining background + sheet |
| [`DraggableSheet`](Sources/SnapSheet/DraggableSheet.swift) | The floating sheet view with handle and scroll area |
| [`SheetStateModel`](Sources/SnapSheet/SheetStateModel.swift) | `@Observable` state machine for drag, scroll, and snap |
| [`SheetSnapState`](Sources/SnapSheet/SheetSnapState.swift) | Collapsed / half / expanded detent definitions |
| [`SheetStyle`](Sources/SnapSheet/SheetStyle.swift) | Visual configuration for the sheet chrome |
| [`GestureOwner`](Sources/SnapSheet/GestureOwner.swift) | Tracks which gesture is active (background, drag, scroll) |
| `SheetSnapEngine` | Internal snap resolver (nearest detent to projected offset) |

## Snap Detents

`SheetSnapState` defines three resting positions. Each maps to a **y-offset from the top of the screen** via `yOffset(in:bottomInset:)`:

| Detent | Behavior | Offset formula |
|--------|----------|----------------|
| `.collapsed` | Background dominates; small sheet strip at bottom | `max(height × 0.76, height − 180 − bottomInset)` |
| `.half` | Balanced split (default) | `height × 0.48` |
| `.expanded` | Sheet dominates; background peeks above | `max(70, height × 0.12)` |

After a drag ends, `SheetSnapEngine` picks the detent **closest to the projected end offset** (origin + predicted translation). Non-finite projected values fall back to the current offset.

## Gesture Behavior

### Handle drag

The capsule handle always drives sheet dragging. Drag up to expand, drag down to collapse.

### Content-area drag (scroll handoff)

When the sheet is **not** fully expanded, any vertical drag in the content area moves the sheet.

When **expanded**:

- **ScrollView is enabled** and consumes upward drags normally.
- **Downward drag at scroll top** (`contentOffsetY ≤ 1`) hands off to sheet dragging, collapsing the sheet.
- **Downward drag while scrolled** scrolls content back toward the top.

`shouldHandoffScrollToSheet(dragTranslationY:)` encodes this logic:

```swift
guard snapState == .expanded else { return true }
return contentOffsetY <= 1 && dragTranslationY > 0
```

### Gesture ownership

`GestureOwner` tracks which interaction is active:

| Value | Meaning |
|-------|---------|
| `.background` | No sheet gesture active |
| `.sheetDrag` | User is dragging the sheet |
| `.sheetScroll` | User is scrolling sheet content |

Scroll is disabled while `gestureOwner == .sheetDrag` or `snapState != .expanded`.

## Advanced Usage

### Manual assembly

Use `DraggableSheet` directly when you already manage layout geometry:

```swift
GeometryReader { proxy in
    let height = proxy.size.height
    let bottomInset = proxy.safeAreaInsets.bottom

    ZStack(alignment: .top) {
        background.ignoresSafeArea()

        DraggableSheet(
            model: sheetModel,
            containerHeight: height,
            bottomInset: bottomInset
        ) {
            sheetContent
        }
    }
}
```

### Programmatic snap control

`SheetStateModel.snapState` is writable. Set it directly to jump to a detent (animations are handled by `DraggableSheet`):

```swift
sheetModel.snapState = .expanded
```

### Reading offsets

```swift
let resting = sheetModel.restingOffset(containerHeight: height, bottomInset: inset)
let active  = sheetModel.activeOffset(containerHeight: height, bottomInset: inset)
// active includes in-progress dragTranslation, clamped to expanded…collapsed range
```

## API Reference

### `BackgroundSheetScene`

```swift
public init(
    sheetModel: SheetStateModel = SheetStateModel(),
    style: SheetStyle = .standard,
    @ViewBuilder background: () -> Background,
    @ViewBuilder sheetContent: () -> SheetContent
)
```

Composes a `GeometryReader`, places the background full-screen, and overlays a `DraggableSheet` sized to the container.

### `DraggableSheet`

```swift
public init(
    model: SheetStateModel,
    containerHeight: CGFloat,
    bottomInset: CGFloat,
    style: SheetStyle = .standard,
    @ViewBuilder sheetContent: () -> SheetContent
)
```

Renders the material sheet with handle, applies y-offset from the model, and manages drag + scroll gestures.

### `SheetStateModel`

| Property | Type | Description |
|----------|------|-------------|
| `snapState` | `SheetSnapState` | Current resting detent |
| `dragTranslation` | `CGFloat` | In-progress drag offset (0 when idle) |
| `lastDragVelocityY` | `CGFloat` | Velocity from the last completed drag |
| `gestureOwner` | `GestureOwner` | Active gesture owner |
| `contentOffsetY` | `CGFloat` | Current scroll offset of sheet content |

| Method | Description |
|--------|-------------|
| `startDrag(containerHeight:bottomInset:)` | Begins a drag from the current detent offset |
| `updateDrag(translationY:)` | Updates in-progress drag translation |
| `finishDrag(translationY:predictedEndTranslationY:containerHeight:bottomInset:)` | Ends drag and snaps to nearest detent |
| `restingOffset(containerHeight:bottomInset:)` | Y-offset for the current detent |
| `activeOffset(containerHeight:bottomInset:)` | Resting offset + drag, clamped to detent range |
| `shouldHandoffScrollToSheet(dragTranslationY:)` | Whether a content drag should move the sheet |

### `SheetStyle`

| Property | Default | Description |
|----------|---------|-------------|
| `cornerRadius` | `24` | Sheet corner radius |
| `handleWidth` | `44` | Drag handle width |
| `handleHeight` | `5` | Drag handle height |
| `contentHorizontalPadding` | `20` | Horizontal padding inside scroll content |
| `contentBottomPadding` | `40` | Bottom padding inside scroll content (safe area applied via `safeAreaPadding`) |

`SheetStyle.standard` provides the default values.

## Demo App

An example iOS app lives in [`Examples/SnapSheetDemo`](Examples/SnapSheetDemo/). See the [demo screencast](docs/media/SnapSheet-Demo.mov) above, or run it locally. It demonstrates:

- A MapKit background with place annotations
- Live snap-state indicators and tappable detent chips
- Tapping sheet rows to recenter the map

**Open in Xcode:**

```bash
open Examples/SnapSheetDemo/SnapSheetDemo.xcodeproj
```

**Build from the command line:**

```bash
cd Examples/SnapSheetDemo
xcodebuild -project SnapSheetDemo.xcodeproj -scheme SnapSheetDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Testing

Unit tests cover snap offset math, snap resolution, drag lifecycle, offset clamping, scroll handoff, and gesture ownership.

```bash
xcodebuild test -scheme SnapSheet -destination 'platform=iOS Simulator,name=iPhone 17'
```

> `swift test` on macOS alone will not work — the package targets iOS 18 only. Use an iOS Simulator destination.

CI runs the same test and demo build workflows on every push and pull request to `main` (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

## Contributing

| Resource | Description |
|----------|-------------|
| [Architecture Guide](docs/ARCHITECTURE.md) | How the library is structured |
| [Bug Report](.github/ISSUE_TEMPLATE/bug_report.yml) | Report unexpected behavior |
| [Feature Request](.github/ISSUE_TEMPLATE/feature_request.yml) | Suggest new functionality |
| [Pull Request Template](.github/pull_request_template.md) | Checklist for submitting changes |

1. Fork the repository and create a branch from `main`.
2. Make your changes with tests where appropriate.
3. Open a pull request using the PR template.

## Accessibility

- The sheet container uses `.accessibilityElement(children: .contain)`.
- The drag handle exposes the accessibility label **"Drag handle"**.

## License

SnapSheet is released under the [MIT License](LICENSE).
