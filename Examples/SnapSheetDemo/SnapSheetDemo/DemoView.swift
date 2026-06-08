import MapKit
import SnapSheet
import SwiftUI

struct DemoView: View {
    @State private var sheetModel = SheetStateModel()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )

    private let places: [DemoPlace] = [
        DemoPlace(name: "Golden Gate Bridge", category: "Landmark", distance: "2.4 mi", coordinate: CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783), symbol: "camera.fill"),
        DemoPlace(name: "Ferry Building", category: "Food & Drink", distance: "0.8 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7955, longitude: -122.3937), symbol: "fork.knife"),
        DemoPlace(name: "Crissy Field", category: "Park", distance: "1.6 mi", coordinate: CLLocationCoordinate2D(latitude: 37.8021, longitude: -122.4662), symbol: "tree.fill"),
        DemoPlace(name: "Coit Tower", category: "Landmark", distance: "3.1 mi", coordinate: CLLocationCoordinate2D(latitude: 37.8024, longitude: -122.4058), symbol: "building.columns.fill"),
        DemoPlace(name: "Pier 39", category: "Shopping", distance: "1.2 mi", coordinate: CLLocationCoordinate2D(latitude: 37.8087, longitude: -122.4098), symbol: "bag.fill"),
        DemoPlace(name: "Lands End", category: "Trail", distance: "4.5 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7847, longitude: -122.5050), symbol: "figure.hiking"),
        DemoPlace(name: "Mission Dolores Park", category: "Park", distance: "5.0 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7596, longitude: -122.4269), symbol: "leaf.fill"),
        DemoPlace(name: "Twin Peaks", category: "Viewpoint", distance: "3.8 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7544, longitude: -122.4477), symbol: "binoculars.fill"),
        DemoPlace(name: "Alcatraz Island", category: "Landmark", distance: "1.5 mi", coordinate: CLLocationCoordinate2D(latitude: 37.8267, longitude: -122.4230), symbol: "ferry.fill"),
        DemoPlace(name: "Palace of Fine Arts", category: "Landmark", distance: "2.0 mi", coordinate: CLLocationCoordinate2D(latitude: 37.8029, longitude: -122.4486), symbol: "theatermasks.fill"),
        DemoPlace(name: "Chinatown Gate", category: "Neighborhood", distance: "1.0 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7909, longitude: -122.4052), symbol: "building.2.fill"),
        DemoPlace(name: "SFMOMA", category: "Museum", distance: "0.6 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7857, longitude: -122.4011), symbol: "paintpalette.fill"),
        DemoPlace(name: "Oracle Park", category: "Stadium", distance: "1.4 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7786, longitude: -122.3893), symbol: "sportscourt.fill"),
        DemoPlace(name: "Painted Ladies", category: "Landmark", distance: "1.8 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7766, longitude: -122.4330), symbol: "house.fill"),
        DemoPlace(name: "Baker Beach", category: "Beach", distance: "3.2 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7936, longitude: -122.4836), symbol: "beach.umbrella.fill"),
        DemoPlace(name: "Japantown", category: "Neighborhood", distance: "1.7 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7851, longitude: -122.4300), symbol: "storefront.fill"),
        DemoPlace(name: "Castro Theatre", category: "Theater", distance: "2.2 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7609, longitude: -122.4350), symbol: "film.fill"),
        DemoPlace(name: "Legion of Honor", category: "Museum", distance: "4.0 mi", coordinate: CLLocationCoordinate2D(latitude: 37.7845, longitude: -122.5008), symbol: "photo.artframe"),
        DemoPlace(name: "Exploratorium", category: "Museum", distance: "1.3 mi", coordinate: CLLocationCoordinate2D(latitude: 37.8017, longitude: -122.3975), symbol: "atom"),
        DemoPlace(name: "Wave Organ", category: "Art", distance: "2.6 mi", coordinate: CLLocationCoordinate2D(latitude: 37.8065, longitude: -122.4404), symbol: "waveform"),
    ]

    var body: some View {
        BackgroundSheetScene(sheetModel: sheetModel) {
            mapBackground
        } sheetContent: {
            sheetContent
        }
    }

    private var mapBackground: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .rotate]) {
            ForEach(places) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    mapAnnotation(for: place)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .top) {
            HStack {
                Label("San Francisco", systemImage: "location.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                Spacer()
                snapStateBadge
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
        }
    }

    private func mapAnnotation(for place: DemoPlace) -> some View {
        Image(systemName: place.symbol)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(8)
            .background(Color.orange.gradient, in: Circle())
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    private var snapStateBadge: some View {
        Text(sheetModel.snapState.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .animation(.bouncy(duration: 0.25), value: sheetModel.snapState)
    }

    private var sheetContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Nearby Places")
                    .font(.title2.bold())
                Text("Drag the handle or swipe the sheet to snap between detents.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ForEach(SheetSnapState.allCases, id: \.self) { state in
                    detentChip(for: state)
                }
            }

            Divider()

            ForEach(places) { place in
                Button {
                    withAnimation {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: place.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            )
                        )
                    }
                } label: {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: place.symbol)
                                    .foregroundStyle(Color.accentColor)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(place.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(place.distance)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func detentChip(for state: SheetSnapState) -> some View {
        let isActive = sheetModel.snapState == state
        return Button {
            withAnimation(.bouncy(duration: 0.45, extraBounce: 0.18)) {
                sheetModel.snapState = state
            }
        } label: {
            Text(state.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isActive ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isActive ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.secondary.opacity(0.12)),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .animation(.bouncy(duration: 0.25), value: sheetModel.snapState)
    }
}

private struct DemoPlace: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let distance: String
    let coordinate: CLLocationCoordinate2D
    let symbol: String
}

private extension SheetSnapState {
    var label: String {
        switch self {
        case .collapsed: "Collapsed"
        case .half: "Half"
        case .expanded: "Expanded"
        }
    }
}

#Preview {
    DemoView()
}
