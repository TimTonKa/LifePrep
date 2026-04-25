import SwiftData
import CoreLocation

@Model
final class Shelter {
    @Attribute(.unique) var id: String
    var name: String
    var address: String
    var county: String
    var village: String
    var latitude: Double
    var longitude: Double
    var capacity: Int
    var disasterTypes: String
    var indoor: Bool
    var outdoor: Bool
    var suitableForVulnerable: Bool

    init(id: String, name: String, address: String, county: String, village: String,
         latitude: Double, longitude: Double, capacity: Int, disasterTypes: String,
         indoor: Bool, outdoor: Bool, suitableForVulnerable: Bool) {
        self.id = id
        self.name = name
        self.address = address
        self.county = county
        self.village = village
        self.latitude = latitude
        self.longitude = longitude
        self.capacity = capacity
        self.disasterTypes = disasterTypes
        self.indoor = indoor
        self.outdoor = outdoor
        self.suitableForVulnerable = suitableForVulnerable
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
