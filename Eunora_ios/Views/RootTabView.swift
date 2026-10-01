import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack { VoyageView() }.tabItem { Label("Voyage", systemImage: "sailboat.fill") }
            NavigationStack { QuestsView() }.tabItem { Label("Quests", systemImage: "checkmark.circle") }
            NavigationStack { VoyageMapView() }.tabItem { Label("Map", systemImage: "map.fill") }
            NavigationStack { CabinView() }.tabItem { Label("Cabin", systemImage: "lamp.table.fill") }
            NavigationStack { YouView() }.tabItem { Label("You", systemImage: "person.crop.circle") }
        }
    }
}
