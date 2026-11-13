import Foundation
import Observation

@MainActor
@Observable
final class SailorCustomizationStore {
    static let shared = SailorCustomizationStore()
    private static let key = "sailorCustomization"

    private(set) var avatar: WebSailor.Avatar
    private(set) var placedItems: [String]
    private let writer = DispatchQueue(label: "Eunora.SailorCustomization", qos: .utility)

    private init() {
        let data = UserDefaults.standard.data(forKey: Self.key)
        let initial = data.flatMap { try? JSONDecoder().decode(WebSailor.Customization.self, from: $0) } ?? .init()
        avatar = initial.avatar
        placedItems = initial.placedItems
    }

    func update(_ edit: (inout WebSailor.Customization) -> Void) {
        var next = WebSailor.Customization(avatar: avatar, placedItems: placedItems)
        edit(&next)
        guard next.avatar != avatar || next.placedItems != placedItems else { return }
        if next.avatar != avatar { avatar = next.avatar }
        if next.placedItems != placedItems { placedItems = next.placedItems }

        // Keep writes ordered even when the view closes or selections arrive in quick succession.
        let key = Self.key
        writer.async {
            guard let data = try? JSONEncoder().encode(next) else { return }
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
