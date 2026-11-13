import Foundation
import Observation

@MainActor
@Observable
final class SailorCustomizationStore {
    static let shared = SailorCustomizationStore()
    private static let key = "sailorCustomization"

    private(set) var avatar: WebSailor.Avatar
    private(set) var placedItems: [String]

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

        // Publish the small snapshot immediately. UserDefaults manages the disk write.
        if let data = try? JSONEncoder().encode(next) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
