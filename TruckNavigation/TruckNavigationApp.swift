import Combine
import CoreLocation
import SwiftUI
import TomTomSDKCommon
import TomTomSDKMapDisplay
import TomTomSDKRoute
import TomTomSDKRoutePlanner
import TomTomSDKRoutePlannerOnline
import TomTomSDKRoutingCommon

@main
struct TruckNavigationApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                TomTomMapView(navigationController: navigationController)
            }
            .ignoresSafeArea(edges: [.top, .bottom])

            Button("Plan Route") {
                navigationController.planRoute()
            }.padding()
        }
    }

    let navigationController = NavigationController()
}

final class MapCoordinator {
    init(
        mapView: TomTomSDKMapDisplay.MapView,
        navigationController: NavigationController
    ) {
        self.mapView = mapView
        self.navigationController = navigationController
        observe(navigationController: navigationController)
    }

    private let mapView: TomTomSDKMapDisplay.MapView
    private var map: TomTomSDKMapDisplay.TomTomMap?
    private let navigationController: NavigationController
    private var cancellableBag = Set<AnyCancellable>()
}

struct TomTomMapView {
    var mapView = TomTomSDKMapDisplay.MapView(
        mapOptions: MapOptions(
            mapStyle: .restrictionsStyle,
            apiKey: Keys.ttAPIKey
        )
    )

    let navigationController: NavigationController
}

extension TomTomMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> TomTomSDKMapDisplay.MapView {
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_: TomTomSDKMapDisplay.MapView, context _: Context) {}

    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(
            mapView: mapView,
            navigationController: navigationController
        )
    }
}

enum VehicleProvider {
    static let myTruck = Truck(
        dimensions: try? VehicleDimensions(
            weight: Measurement.tt.kilograms(8000),
            axleWeight: Measurement.tt.kilograms(4000),
            length: Measurement.tt.millimeters(8340),
            width: Measurement.tt.millimeters(4650),
            height: Measurement.tt.millimeters(3445),
            numberOfAxles: 3
        )
    )
}

extension MapCoordinator: TomTomSDKMapDisplay.MapViewDelegate {
    func mapView(_: MapView, onMapReady map: TomTomMap) {
        do {
            self.map = map
            try map.showVehicleRestrictions(vehicle: VehicleProvider.myTruck)
        } catch {
            print("Failed to show vehicle restrictions: \(error)")
        }
    }

    func mapView(
        _: MapView,
        onStyleLoad result: Result<StyleContainer, Error>
    ) {
        switch result {
        case .failure:
            print("Style loading failure")
        case .success:
            print("Style loaded")
        }
    }
}

class RouteService {
    init(routePlanner: OnlineRoutePlanner) {
        self.routePlanner = routePlanner
    }

    let routePlanner: OnlineRoutePlanner
}

extension RouteService {
    enum RoutePlanError: Error {
        case unableToPlanRoute
    }

    func createRoutePlanningOptions(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) throws -> TomTomSDKRoutePlanner.RoutePlanningOptions {
        let itinerary = Itinerary(
            origin: ItineraryPoint(coordinate: origin),
            destination: ItineraryPoint(coordinate: destination)
        )

        return try RoutePlanningOptions(
            itinerary: itinerary,
            vehicle: VehicleProvider.myTruck
        )
    }

    func planRoute(routePlanningOptions: RoutePlanningOptions) async throws -> TomTomSDKRoute.Route {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TomTomSDKRoute.Route, Error>) in
            routePlanner.planRoute(options: routePlanningOptions, onRouteReady: nil) { result in
                switch result {
                case let .failure(error):
                    continuation.resume(throwing: error)
                case let .success(response):
                    guard let route = response.routes?.first else {
                        continuation.resume(throwing: RoutePlanError.unableToPlanRoute)
                        return
                    }
                    continuation.resume(returning: route)
                }
            }
        }
    }
}

class NavigationController {
    convenience init() {
        let routeService = RouteService(routePlanner: OnlineRoutePlanner(apiKey: Keys.ttAPIKey))
        self.init(routeService: routeService)
    }

    init(routeService: RouteService) {
        self.routeService = routeService
    }

    let routeService: RouteService
    let displayedRouteSubject = PassthroughSubject<TomTomSDKRoute.Route, Never>()
}

extension NavigationController {
    func planRoute() {
        let origin = CLLocationCoordinate2D(latitude: 52.26734, longitude: 4.78437)
        let destionation = CLLocationCoordinate2D(latitude: 52.2707, longitude: 4.79428)

        let options: RoutePlanningOptions
        do {
            options = try routeService.createRoutePlanningOptions(from: origin, to: destionation)
        } catch {
            print("Invalid planning options: \(error.localizedDescription)")
            return
        }

        Task {
            var route: TomTomSDKRoute.Route

            do {
                route = try await routeService.planRoute(routePlanningOptions: options)
                displayedRouteSubject.send(route)
            } catch {
                print("Failure on planning route: \(error.localizedDescription)")
                return
            }
        }
    }
}

extension MapCoordinator {
    func observe(navigationController: NavigationController) {
        navigationController.displayedRouteSubject.sink { [weak self] route in
            guard let self = self else { return }
            do {
                if let _ = try map?.addRoute(RouteOptions(coordinates: route.geometry)) {
                    map?.zoomToRoutes(padding: 32)
                }
            } catch {
                print("Failure on adding route to map: \(error.localizedDescription)")
                return
            }
        }.store(in: &cancellableBag)
    }
}
