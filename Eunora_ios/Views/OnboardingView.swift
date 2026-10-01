import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0
    @State private var destination = "Kyoto"
    private let destinations = ["Kyoto", "Santorini", "Paris", "Bali", "Reykjavík"]

    var body: some View {
        ZStack {
            StorybookBackground()
            VStack(spacing: 24) {
                Text("EUNOIA").font(.caption.weight(.semibold)).tracking(3).foregroundStyle(EunoiaColor.deepOcean).padding(.top, 8)
                TabView(selection: $page) { welcome.tag(0); destinationPicker.tag(1); explanation.tag(2) }
                    .tabViewStyle(.page(indexDisplayMode: .always)).animation(.easeInOut, value: page)
                Button(page == 2 ? "Set sail" : page == 0 ? "Begin my voyage" : "Continue") {
                    if page < 2 { page += 1 } else { UserDefaults.standard.set(destination, forKey: "selectedDestination"); onComplete() }
                }.buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 28).padding(.bottom, 20)
            }
        }
    }

    private var welcome: some View {
        VStack(spacing: 22) {
            OceanScene(progress: 0.18, weather: .calm).padding(.horizontal, 24)
            Text("Welcome aboard.").font(.largeTitle.bold()).foregroundStyle(EunoiaColor.ink)
            Text("Recovery isn’t a race.\nIt’s a voyage made of many small steps.").font(.title3).multilineTextAlignment(.center).foregroundStyle(.secondary).lineSpacing(5)
        }
    }

    private var destinationPicker: some View {
        VStack(spacing: 22) {
            Image(systemName: "map.fill").font(.system(size: 72)).foregroundStyle(EunoiaColor.gold)
            Text("Where would you like to sail?").font(.title.bold()).multilineTextAlignment(.center).foregroundStyle(EunoiaColor.ink)
            Text("A destination is a direction, never a deadline.").foregroundStyle(.secondary)
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                ForEach(destinations, id: \.self) { item in
                    Button { destination = item } label: {
                        Label(item, systemImage: destination == item ? "checkmark.circle.fill" : "circle").frame(maxWidth: .infinity, minHeight: 50)
                            .background(destination == item ? EunoiaColor.sky : .white.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
                    }.foregroundStyle(EunoiaColor.deepOcean)
                }
            }.padding(.horizontal, 28)
        }
    }

    private var explanation: some View {
        VStack(spacing: 24) {
            ZStack { Circle().fill(EunoiaColor.sky.opacity(0.65)).frame(width: 190, height: 190); Image(systemName: "anchor.circle.fill").font(.system(size: 100)).foregroundStyle(EunoiaColor.gold, EunoiaColor.cream) }
            Text("Small steps move\nyour ship forward.").font(.largeTitle.bold()).multilineTextAlignment(.center).foregroundStyle(EunoiaColor.ink)
            Text("Complete gentle daily quests. Earn Anchors. Watch your voyage unfold and discover little treasures along the way.").font(.title3).multilineTextAlignment(.center).foregroundStyle(.secondary).lineSpacing(4).padding(.horizontal, 30)
        }
    }
}
