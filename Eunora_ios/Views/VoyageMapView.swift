import SwiftUI
import SwiftData

struct WebDestination: Identifiable {
    let id: String
    let name: String
    let longitude: Double
    let latitude: Double
    let tagline: String
    let accent: UInt
    let seas: String
    let distance: String
    let duration: String
    let vibe: String

    var asset: String { "WebMap-" + id }
    var normalizedPoint: CGPoint {
        CGPoint(x: (longitude + 180) / 360, y: (90 - latitude) / 180)
    }

    static let all: [Self] = [
        .init(id: "paris", name: "Paris", longitude: 2.3, latitude: 48.9,
              tagline: "Where you rediscover the joy of being alive", accent: 0x7a8fa8, seas: "North Atlantic",
              distance: "3,628 nm", duration: "23 days", vibe: "Cafés and golden light"),
        .init(id: "kyoto", name: "Kyoto", longitude: 135.8, latitude: 35.0,
              tagline: "Ancient gardens where stillness becomes strength", accent: 0x9a8070, seas: "Pacific Ocean",
              distance: "11,204 nm", duration: "71 days", vibe: "Cherry blossoms & peace"),
        .init(id: "santorini", name: "Santorini", longitude: 25.4, latitude: 36.4,
              tagline: "White cliffs, blue domes — sea meets sky", accent: 0x6a8aaa, seas: "Mediterranean",
              distance: "2,185 nm", duration: "14 days", vibe: "Sunsets and open sky"),
        .init(id: "bali", name: "Bali", longitude: 115.2, latitude: -8.7,
              tagline: "Island of healing where nature restores", accent: 0x6a9070, seas: "Indian Ocean",
              distance: "8,432 nm", duration: "54 days", vibe: "Rice terraces & warmth"),
        .init(id: "canada", name: "Canada", longitude: -21.8, latitude: 64.1,
              tagline: "Where the dark sky dances with color", accent: 0x8080a8, seas: "North Atlantic",
              distance: "1,680 nm", duration: "11 days", vibe: "Northern lights & hot springs"),
        .init(id: "maldives", name: "Maldives", longitude: 73.0, latitude: 3.2,
              tagline: "Crystal waters where peace lives", accent: 0x5a8a98, seas: "Indian Ocean",
              distance: "7,910 nm", duration: "50 days", vibe: "Turquoise & tranquility"),
        .init(id: "machupicchu", name: "Machu Picchu", longitude: -72.5, latitude: -13.2,
              tagline: "Above the clouds — see how far you have come", accent: 0x8a7a50, seas: "South Atlantic",
              distance: "6,240 nm", duration: "40 days", vibe: "Mist, mountains & wonder"),
        .init(id: "hawaii", name: "Hawaii", longitude: 18.4, latitude: -33.9,
              tagline: "Where two oceans meet and stories begin again", accent: 0x9a6868, seas: "South Atlantic",
              distance: "6,820 nm", duration: "44 days", vibe: "Winelands & wild coast"),
        .init(id: "rome", name: "Rome", longitude: 18.4, latitude: -33.9,
              tagline: "Where you travel back in time", accent: 0x9a6868, seas: "South Atlantic",
              distance: "6,820 nm", duration: "44 days", vibe: "Winelands & wild coast"),
        .init(id: "antarctica", name: "Antarctica", longitude: 18.4, latitude: -33.9,
              tagline: "Where the wisps of snow tickle your face", accent: 0x9a6868, seas: "South Atlantic",
              distance: "6,820 nm", duration: "44 days", vibe: "Winelands & wild coast"),
    ]
}

struct VoyageMapView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var profiles: [VoyageProfile]
    @State private var routeProgress: CGFloat = 1

    private var destinationName: String {
        profiles.first?.destination ?? UserDefaults.standard.string(forKey: "selectedDestination") ?? "Kyoto"
    }
    private var destination: WebDestination? { WebDestination.all.first { $0.name == destinationName } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EunoiaSpacing.md) {
                EditorialHeading(text: "Chart your course")
                    .accessibilityAddTraits(.isHeader)
                Text("A destination is a direction, never a deadline.")
                    .foregroundStyle(EunoiaColor.secondaryText)
                worldMap
                if let destination {
                    EunoiaCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(destination.name).font(.title2).accessibilityAddTraits(.isHeader)
                            Text(destination.tagline)
                            Text("\(destination.distance) · \(destination.duration) · \(destination.seas)")
                                .font(.subheadline)
                            Text(destination.vibe).font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text("Sailing to \(destinationName)").font(.headline)
                }
                ForEach(WebDestination.all) { stop in
                    Button { select(stop) } label: {
                        HStack(spacing: 12) {
                            Image(stop.asset).resizable().scaledToFit().frame(width: 44, height: 44)
                                .accessibilityHidden(true)
                            Text(stop.name).font(.headline)
                            Spacer()
                            if stop.id == destination?.id {
                                Image(systemName: "checkmark.circle.fill").accessibilityHidden(true)
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(minHeight: 52)
                        .background(EunoiaColor.card, in: RoundedRectangle(cornerRadius: 12))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(stop.id == destination?.id ? .isSelected : [])
                }
            }
            .padding(.vertical, EunoiaSpacing.md)
            .eunoiaReadableContent()
            .foregroundStyle(EunoiaColor.deepOcean)
        }
        .background { StorybookBackground() }
        .navigationTitle("Voyage Map")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var worldMap: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 900
            let home = CGPoint(x: 350 * scale, y: 128 * scale)
            let mapPoint: (WebDestination) -> CGPoint = { stop in
                CGPoint(
                    x: stop.normalizedPoint.x * geometry.size.width,
                    y: stop.normalizedPoint.y * geometry.size.height
                )
            }
            ZStack {
                LinearGradient(colors: [EunoiaColor.sky, EunoiaColor.dustyBlue], startPoint: .top, endPoint: .bottom)
                Canvas { graphics, _ in
                    var grid = Path()
                    for y in [72, 145, 218, 290, 362] {
                        grid.move(to: CGPoint(x: 0, y: CGFloat(y) * scale))
                        grid.addLine(to: CGPoint(x: geometry.size.width, y: CGFloat(y) * scale))
                    }
                    for x in stride(from: 150, through: 825, by: 75) {
                        grid.move(to: CGPoint(x: CGFloat(x) * scale, y: 0))
                        grid.addLine(to: CGPoint(x: CGFloat(x) * scale, y: geometry.size.height))
                    }
                    graphics.stroke(grid, with: .color(.white.opacity(0.3)), lineWidth: 0.5)
                    for continent in Self.continents {
                        let land = Path { path in
                            path.addLines(continent.map { CGPoint(x: $0.x * scale, y: $0.y * scale) })
                            path.closeSubpath()
                        }
                        graphics.fill(land, with: .color(EunoiaColor.foam.opacity(0.76)))
                        graphics.stroke(land, with: .color(.white.opacity(0.45)), lineWidth: 0.5)
                    }
                }
                if let destination {
                    let point = mapPoint(destination)
                    Path { path in
                        path.move(to: home)
                        path.addQuadCurve(
                            to: point,
                            control: CGPoint(x: (home.x + point.x) / 2, y: (home.y + point.y) / 2 - 48 * scale)
                        )
                    }
                    .trim(from: 0, to: routeProgress)
                    .stroke(Color(hex: 0x9A7060), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                ForEach(WebDestination.all) { stop in
                    Circle().fill(Color(hex: stop.accent))
                        .frame(width: stop.id == destination?.id ? 10 : 5)
                        .position(mapPoint(stop))
                }
                Image("WebMap-boat").resizable().scaledToFit()
                    .frame(width: 18, height: 18)
                    .background(.white.opacity(0.85), in: Circle())
                    .position(home)
            }
        }
        .aspectRatio(900.0 / 460, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: EunoiaRadius.card))
        .accessibilityHidden(true)
    }

    private func select(_ stop: WebDestination) {
        guard stop.name != destinationName else { return }
        if let profile = profiles.first {
            profile.destination = stop.name
        } else {
            context.insert(VoyageProfile(destination: stop.name))
        }
        if !reduceMotion {
            routeProgress = 0
            withAnimation(.easeOut(duration: 2.2)) { routeProgress = 1 }
        }
    }

    private static let continents: [[CGPoint]] = [
        [.init(x: 55, y: 42), .init(x: 120, y: 32), .init(x: 175, y: 38), .init(x: 225, y: 55), .init(x: 260, y: 78), .init(x: 290, y: 95), .init(x: 300, y: 125), .init(x: 290, y: 155), .init(x: 275, y: 185), .init(x: 255, y: 210), .init(x: 225, y: 240), .init(x: 185, y: 255), .init(x: 155, y: 248), .init(x: 115, y: 228), .init(x: 80, y: 205), .init(x: 58, y: 175), .init(x: 42, y: 145), .init(x: 40, y: 105), .init(x: 45, y: 72)],
        [.init(x: 215, y: 18), .init(x: 268, y: 14), .init(x: 290, y: 28), .init(x: 288, y: 48), .init(x: 262, y: 56), .init(x: 228, y: 54), .init(x: 210, y: 40)],
        [.init(x: 160, y: 252), .init(x: 200, y: 246), .init(x: 242, y: 255), .init(x: 265, y: 280), .init(x: 280, y: 320), .init(x: 278, y: 370), .init(x: 258, y: 415), .init(x: 222, y: 428), .init(x: 182, y: 415), .init(x: 162, y: 380), .init(x: 150, y: 340), .init(x: 148, y: 295), .init(x: 152, y: 268)],
        [.init(x: 375, y: 65), .init(x: 390, y: 58), .init(x: 415, y: 55), .init(x: 442, y: 60), .init(x: 462, y: 72), .init(x: 468, y: 90), .init(x: 460, y: 108), .init(x: 440, y: 118), .init(x: 415, y: 122), .init(x: 392, y: 115), .init(x: 375, y: 100), .init(x: 368, y: 82)],
        [.init(x: 375, y: 130), .init(x: 450, y: 120), .init(x: 498, y: 135), .init(x: 515, y: 162), .init(x: 512, y: 205), .init(x: 500, y: 260), .init(x: 480, y: 308), .init(x: 455, y: 342), .init(x: 420, y: 358), .init(x: 385, y: 348), .init(x: 362, y: 318), .init(x: 350, y: 278), .init(x: 352, y: 232), .init(x: 360, y: 185), .init(x: 366, y: 155)],
        [.init(x: 450, y: 62), .init(x: 520, y: 50), .init(x: 625, y: 42), .init(x: 725, y: 48), .init(x: 808, y: 65), .init(x: 840, y: 90), .init(x: 838, y: 120), .init(x: 820, y: 145), .init(x: 790, y: 162), .init(x: 740, y: 172), .init(x: 680, y: 178), .init(x: 618, y: 182), .init(x: 555, y: 178), .init(x: 498, y: 168), .init(x: 472, y: 148), .init(x: 458, y: 120), .init(x: 448, y: 90)],
        [.init(x: 618, y: 182), .init(x: 660, y: 185), .init(x: 700, y: 195), .init(x: 740, y: 210), .init(x: 720, y: 228), .init(x: 680, y: 225), .init(x: 630, y: 212), .init(x: 608, y: 198)],
        [.init(x: 650, y: 268), .init(x: 728, y: 258), .init(x: 782, y: 268), .init(x: 800, y: 298), .init(x: 798, y: 335), .init(x: 775, y: 358), .init(x: 738, y: 365), .init(x: 695, y: 362), .init(x: 658, y: 345), .init(x: 638, y: 310), .init(x: 640, y: 282)],
        [.init(x: 0, y: 432), .init(x: 900, y: 432), .init(x: 900, y: 460), .init(x: 0, y: 460)],
    ]
}


#Preview("Map") {
    NavigationStack { VoyageMapView() }
        .modelContainer(for: VoyageProfile.self, inMemory: true)
}
