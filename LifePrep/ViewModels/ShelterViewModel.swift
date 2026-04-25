import SwiftData
import CoreLocation
import Combine

@MainActor
final class ShelterViewModel: NSObject, ObservableObject {
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var nearbyShelters: [Shelter] = []
    @Published var selectedShelter: Shelter?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    var context: ModelContext
    private let locationManager = CLLocationManager()
    private let nearbyRadius: Double = 5000 // metres

    init(context: ModelContext) {
        self.context = context
        self.lastUpdated = UserDefaults.standard.object(forKey: "shelterLastUpdated") as? Date
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authStatus = locationManager.authorizationStatus
    }

    // MARK: - Location

    func requestLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    // MARK: - Shelter data

    var hasShelterData: Bool {
        (try? context.fetchCount(FetchDescriptor<Shelter>())) ?? 0 > 0
    }

    func fetchShelters() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let count = try await ShelterService.shared.fetchAndStore(context: context)
                let now = Date()
                UserDefaults.standard.set(now, forKey: "shelterLastUpdated")
                self.lastUpdated = now
                self.isLoading = false
                if let loc = userLocation {
                    refreshNearbyShelters(from: CLLocation(latitude: loc.latitude, longitude: loc.longitude))
                }
                print("[Shelter] Loaded \(count) shelters")
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func distance(to shelter: Shelter) -> String {
        guard let userLoc = userLocation else { return "" }
        let from = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        let to = CLLocation(latitude: shelter.latitude, longitude: shelter.longitude)
        let m = from.distance(from: to)
        return m < 1000
            ? String(format: "%.0f 公尺", m)
            : String(format: "%.1f 公里", m / 1000)
    }

    // MARK: - Private

    private func refreshNearbyShelters(from location: CLLocation) {
        let all = (try? context.fetch(FetchDescriptor<Shelter>())) ?? []
        nearbyShelters = all
            .filter { CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                .distance(from: location) <= nearbyRadius }
            .sorted { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: location)
                < CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: location) }
            .prefix(30)
            .map { $0 }
    }
}

// MARK: - CLLocationManagerDelegate

extension ShelterViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.userLocation = loc.coordinate
            self.refreshNearbyShelters(from: loc)
            manager.stopUpdatingLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "無法取得位置：\(error.localizedDescription)"
        }
    }
}
