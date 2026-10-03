import SwiftUI

enum EunoiaTab: String, CaseIterable {
    case home = "Home"
    case map = "Map"
    case quest = "Quest"
    case letters = "Letters"
    case getHelp = "Get Help"
    case cabin = "Cabin"

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .map: "map.fill"
        case .quest: "checkmark.circle.fill"
        case .letters: "envelope.fill"
        case .getHelp: "lifepreserver.fill"
        case .cabin: "lamp.table.fill"
        }
    }
}

struct RootTabView: View {
    @State private var selection: EunoiaTab = .home
    @Namespace private var tabSelection
    var body: some View {
        Group {
            switch selection {
            case .home: NavigationStack { VoyageView() }
            case .map: NavigationStack { VoyageMapView() }
            case .quest: NavigationStack { QuestsView() }
            case .letters: NavigationStack { BottleShelfView() }
            case .getHelp: NavigationStack { LighthouseView() }
            case .cabin: NavigationStack { CabinView() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 2) {
                ForEach(EunoiaTab.allCases, id: \.self) { tab in
                    Button { withAnimation(.easeInOut(duration: 0.24)) { selection = tab } } label: {
                        VStack(spacing: 3) { Image(systemName: tab.icon).font(.system(size: 21, weight: .medium)); Text(tab.rawValue).font(.system(size: 10, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.75) }
                            .foregroundStyle(selection == tab ? EunoiaColor.deepOcean : EunoiaColor.deepOcean.opacity(0.68)).frame(maxWidth: .infinity, minHeight: 56)
                            .background { if selection == tab { Capsule().fill(EunoiaColor.mistBlue.opacity(0.65)).matchedGeometryEffect(id: "selectedTab", in: tabSelection).padding(.horizontal, 2) } }
                    }.buttonStyle(.plain).accessibilityAddTraits(selection == tab ? .isSelected : [])
                }
            }
            .padding(.horizontal, 8).frame(height: 74).background(EunoiaColor.card.opacity(0.96), in: Capsule()).overlay(Capsule().stroke(EunoiaColor.deepOcean.opacity(0.10))).shadow(color: .black.opacity(0.05), radius: 10, y: -2)
            .padding(.horizontal, 19).padding(.top, 8).padding(.bottom, 4)
        }
    }
}
