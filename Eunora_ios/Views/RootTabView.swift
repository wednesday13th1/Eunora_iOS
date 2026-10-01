import SwiftUI

enum EunoiaTab: String, CaseIterable {
    case voyage = "Voyage", quests = "Quests", map = "Map", cabin = "Cabin", you = "You"
    var icon: String { switch self { case .voyage: "sailboat.fill"; case .quests: "checkmark.circle"; case .map: "map.fill"; case .cabin: "lamp.table.fill"; case .you: "person.crop.circle" } }
}

struct RootTabView: View {
    @State private var selection: EunoiaTab = .voyage
    @Namespace private var tabSelection
    var body: some View {
        Group {
            switch selection {
            case .voyage: NavigationStack { VoyageView() }
            case .quests: NavigationStack { QuestsView() }
            case .map: NavigationStack { VoyageMapView() }
            case .cabin: NavigationStack { CabinView() }
            case .you: NavigationStack { YouView() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 2) {
                ForEach(EunoiaTab.allCases, id: \.self) { tab in
                    Button { withAnimation(.easeInOut(duration: 0.24)) { selection = tab } } label: {
                        VStack(spacing: 3) { Image(systemName: tab.icon).font(.system(size: 23, weight: .medium)); Text(tab.rawValue).font(.system(size: 11, weight: .semibold)) }
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
