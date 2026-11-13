import Foundation

// Catalog and logical IDs from Eunoia-Frontend a2bbd053, src/App.tsx.
enum WebSailor {
    enum Category: String, CaseIterable, Identifiable {
        case hat, jacket, accessory, aura, companion

        var id: String { rawValue }
        var label: String { rawValue.capitalized }

        var selection: WritableKeyPath<Avatar, String> {
            switch self {
            case .hat: \.hat
            case .jacket: \.jacket
            case .accessory: \.accessory
            case .aura: \.aura
            case .companion: \.companion
            }
        }
    }

    nonisolated struct Avatar: Codable, Equatable, Sendable {
        var hat = "sailor"
        var jacket = "stripes"
        var accessory = "none"
        var aura = "sparkle"
        var companion = "none"
    }

    nonisolated struct Customization: Codable, Sendable {
        var avatar = Avatar()
        var placedItems = ["couch", "shelf", "teaset"]

        mutating func toggle(_ id: String) {
            if placedItems.contains(id) {
                placedItems.removeAll { $0 == id }
            } else {
                placedItems.append(id)
            }
        }
    }

    struct Item: Decodable, Identifiable {
        let id: String
        let label: String
        let cost: Int
        let color: String?
        let icon: String?
        let width: Double?
        let height: Double?

        var swatch: UInt? {
            guard let color, color.hasPrefix("#") else { return nil }
            return UInt(color.dropFirst(), radix: 16)
        }
    }

    struct Reward {
        let cost: Int
        let label: String
    }

    static let catalog: [String: [Item]] = {
        guard let url = Bundle.main.url(forResource: "WebSailorCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode([String: [Item]].self, from: data) else {
            assertionFailure("Missing WebSailorCatalog.json")
            return [:]
        }
        return catalog
    }()

    static let decor = catalog["decor", default: []]

    static func items(in category: Category) -> [Item] {
        catalog[category.rawValue, default: []]
    }

    static let nextRewards: [Reward] = [
        .init(cost: 40, label: "Potted Plant"),
        .init(cost: 45, label: "String Lights"),
        .init(cost: 50, label: "Compass"),
        .init(cost: 55, label: "Map Poster"),
        .init(cost: 60, label: "Sea Kitten Companion"),
        .init(cost: 65, label: "Ship Lantern"),
        .init(cost: 70, label: "Mint Jacket"),
        .init(cost: 75, label: "Anchor Pendant"),
        .init(cost: 80, label: "Corgi Companion"),
        .init(cost: 85, label: "Ocean Aura"),
        .init(cost: 100, label: "Warm Glow Aura"),
        .init(cost: 100, label: "Sea Turtle Companion"),
        .init(cost: 120, label: "Baby Octopus Companion"),
        .init(cost: 120, label: "Navy Coat"),
        .init(cost: 130, label: "Captain's Hat")
    ]
}
