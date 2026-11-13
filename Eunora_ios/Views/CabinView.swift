import CoreText
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CabinView: View {
    @Query(filter: #Predicate<DailyQuest> { $0.isCompleted }) private var quests: [DailyQuest]
    private let customization = SailorCustomizationStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var category = WebSailor.Category.hat

    var body: some View {
        let anchors = WebDailyQuests.totalXP(for: quests)
        ScrollView {
            LazyVStack(spacing: 20) {
                HStack {
                    NavigationLink("My Bottles") { BottleShelfView() }
                    Spacer()
                    NavigationLink("Settings") { SettingsView() }
                }
                .font(SailorStyle.font(13, .bold))
                .foregroundStyle(SailorStyle.muted)
                .frame(minHeight: 44)

                header.padding(.bottom, 12)
                avatarCard(anchors: anchors)
                cabinCard(anchors: anchors)
                SailorRewardsView(anchors: anchors)
                    .modifier(SailorCard())
            }
            .frame(maxWidth: 760)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .background {
            LinearGradient(colors: [Color(hex: 0xF8F3EE), Color(hex: 0xF2EDE8), Color(hex: 0xEDE8E2)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 14) {
            Text("YOUR SAILOR & SHIP")
                .font(SailorStyle.font(12, .bold))
                .tracking(2.4)
                .foregroundStyle(SailorStyle.gold)
            Text("\(Text("Customize Your").font(SailorStyle.display(28))) \(Text("Journey").font(SailorStyle.display(28, italic: true)))")
                .foregroundStyle(SailorStyle.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Unlock rewards, decorate your cabin, and collect companions as you progress. Everything is safe and cozy! ♡")
                .font(SailorStyle.font(16))
                .foregroundStyle(SailorStyle.muted)
                .lineSpacing(4)
        }
        .multilineTextAlignment(.center)
    }

    private func avatarCard(anchors: Int) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            cardHeading("Sailor Avatar", badge: "Edit", color: Color(hex: 0x8A6020), tint: SailorStyle.gold)
            if textSize.isAccessibilitySize {
                VStack(spacing: 14) {
                    avatarPreview.frame(maxWidth: 180)
                    wardrobe(anchors: anchors)
                }
                .frame(maxWidth: .infinity)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    avatarPreview
                        .containerRelativeFrame(.horizontal) { width, _ in min(180, width * 0.29) }
                    wardrobe(anchors: anchors)
                }
            }
        }
        .modifier(SailorCard())
    }

    private var avatarPreview: some View {
        SailorCanvas(size: CGSize(width: 160, height: 195), layers: avatarLayers)
            .equatable()
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
            .background {
                LinearGradient(colors: [Color(hex: 0xC6DDED).opacity(0.25), Color(hex: 0xE0D8D0).opacity(0.30)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            .clipShape(.rect(cornerRadius: 16))
            .accessibilityLabel("Sailor preview")
    }

    private var avatarLayers: [String] {
        let avatar = customization.avatar
        return [
            "aura-\(avatar.aura)", "shadow", "jacket-\(avatar.jacket)", "head",
            "hat-\(avatar.hat)", "accessory-\(avatar.accessory)", "companion-\(avatar.companion)"
        ]
        .filter { !$0.hasSuffix("-none") }
        .map { "Sailor-avatar-\($0)" }
    }

    private func wardrobe(anchors: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SailorTabLayout {
                ForEach(WebSailor.Category.allCases) { tab in
                    let selected = category == tab
                    Button {
                        animate { category = tab }
                    } label: {
                        Text(tab.label)
                            .font(SailorStyle.font(12, .bold))
                            .foregroundStyle(selected ? SailorStyle.activeText : SailorStyle.muted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selected ? SailorStyle.blue.opacity(0.18) : .clear, in: Capsule())
                            .overlay { Capsule().strokeBorder(SailorStyle.blue.opacity(selected ? 1 : 0.25), lineWidth: 1.5) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(WebSailor.items(in: category)) { item in
                    let key = category.selection
                    let selected = customization.avatar[keyPath: key] == item.id
                    itemButton(item, selected: selected, isDecor: false, unlocked: anchors >= item.cost) {
                        update { $0.avatar[keyPath: key] = item.id }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cabinCard(anchors: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeading("Boat Cabin Interior", badge: "Decorate", color: SailorStyle.activeText, tint: SailorStyle.blue)
            SailorCanvas(size: CGSize(width: 460, height: 200), layers: cabinLayers,
                         caption: customization.placedItems.isEmpty ? "Decorate your cabin — unlock items below!" : nil)
                .equatable()
                .clipShape(.rect(cornerRadius: 12))
                .accessibilityLabel("Cabin preview")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(WebSailor.decor) { item in
                    itemButton(item, selected: customization.placedItems.contains(item.id), isDecor: true, unlocked: anchors >= item.cost) {
                        update { $0.toggle(item.id) }
                    }
                }
            }
        }
        .modifier(SailorCard())
    }

    private var cabinLayers: [String] {
        let placed = customization.placedItems
        // The source paints in this order, independent of the order items were placed.
        let decor = ["map", "shelf", "couch", "teaset", "plant", "lantern"].filter { placed.contains($0) }
        return (["base", placed.contains("lights") ? "lights" : "lightsOff"] + decor + ["floorShade"])
            .map { "Sailor-cabin-\($0)" }
    }

    private func cardHeading(_ title: String, badge: String, color: Color, tint: Color) -> some View {
        HStack {
            Text(title)
                .font(SailorStyle.font(16, .bold))
                .foregroundStyle(SailorStyle.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            Text(badge)
                .font(SailorStyle.font(12, .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(tint.opacity(0.15), in: Capsule())
                .overlay { Capsule().strokeBorder(tint.opacity(0.30)) }
                .accessibilityHidden(true)
        }
    }

    private func itemButton(_ item: WebSailor.Item, selected: Bool, isDecor: Bool, unlocked: Bool, action: @escaping () -> Void) -> some View {
        let status = selected ? (isDecor ? "Placed ✓" : "Equipped") : nil
        return Button(action: action) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: isDecor ? 10 : 6) {
                    itemIcon(item)
                    itemLabel(item, status: status, unlocked: unlocked, selected: selected, isDecor: isDecor)
                        .fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: 3) {
                    itemIcon(item)
                    itemLabel(item, status: status, unlocked: unlocked, selected: selected, isDecor: isDecor)
                }
            }
            .padding(.horizontal, isDecor ? 14 : 8)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? SailorStyle.blue.opacity(isDecor ? 0.15 : 0.18) :
                            unlocked ? .white.opacity(isDecor ? 0.80 : 0.70) : Color(hex: 0xF0EBE6).opacity(0.60))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(SailorStyle.blue.opacity(selected ? 1 : unlocked ? 0.20 : 0.12), lineWidth: 1.5)
            }
            .opacity(unlocked ? 1 : isDecor ? 0.65 : 0.70)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityLabel(item.label)
        .accessibilityValue(status ?? (unlocked ? "" : "Locked, \(item.cost) Gold Anchors"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private func itemIcon(_ item: WebSailor.Item) -> some View {
        if let icon = item.icon {
            SailorIcon(icon, width: item.width ?? 18, height: item.height ?? 18)
        } else if item.color != nil {
            Circle().fill(item.swatch.map { Color(hex: $0) } ?? .clear)
                .overlay { Circle().strokeBorder(.black.opacity(0.08), lineWidth: 1.5) }
                .frame(width: 18, height: 18)
        } else {
            Text("✦").font(SailorStyle.font(14)).foregroundStyle(SailorStyle.ink)
        }
    }

    private func itemLabel(_ item: WebSailor.Item, status: String?, unlocked: Bool, selected: Bool, isDecor: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.label)
                .font(SailorStyle.font(isDecor ? 13 : 12, .bold))
                .foregroundStyle(selected ? SailorStyle.ink : Color(hex: 0x4A6A82))
                .fixedSize(horizontal: false, vertical: true)
            if !unlocked {
                HStack(spacing: 3) {
                    SailorIcon("Lock", width: 12, height: 12)
                    Text(item.cost, format: .number)
                    SailorIcon(isDecor ? "GoldAnchor" : "Anchor", width: 12, height: 12)
                }
                .font(SailorStyle.font(10, .semibold))
                .foregroundStyle(SailorStyle.gold)
                .fixedSize()
            }
            if let status {
                Text(status)
                    .font(SailorStyle.font(10, .semibold))
                    .foregroundStyle(Color(hex: 0x7A9AB0))
            }
        }
    }

    private func update(_ edit: (inout WebSailor.Customization) -> Void) {
        animate { customization.update(edit) }
    }

    private func animate(_ changes: () -> Void) {
        withAnimation(reduceMotion ? nil : .timingCurve(0.25, 0.1, 0.25, 1, duration: 0.2), changes)
    }
}

private struct SailorCanvas: View, Equatable {
    let size: CGSize
    let layers: [String]
    var caption: String?

    var body: some View {
        Color.clear
            .aspectRatio(size, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    let scale = proxy.size.width / size.width
                    ZStack(alignment: .topLeading) {
                        Color.clear
                        ForEach(layers, id: \.self) { name in
                            SailorLayer(name: name, canvasSize: size, scale: scale)
                                .equatable()
                        }
                        if let caption {
                            Text(caption)
                                .font(SailorStyle.font(14 * scale, relativeTo: nil))
                                .foregroundStyle(Color(hex: 0x8C6432).opacity(0.32))
                                .position(x: 230 * scale, y: 100 * scale)
                        }
                    }
                    .transaction { $0.animation = nil }
                }
            }
            .accessibilityElement(children: .ignore)
    }
}

private struct SailorLayer: View, Equatable {
    let name: String
    let canvasSize: CGSize
    let scale: CGFloat

    private static let bounds: [String: [CGFloat]] = {
        guard let url = Bundle.main.url(forResource: "SailorLayerBounds", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bounds = try? JSONDecoder().decode([String: [CGFloat]].self, from: data) else { return [:] }
        return bounds
    }()

    var body: some View {
        let frame = Self.bounds[name] ?? [0, 0, canvasSize.width, canvasSize.height]
        SailorLayerImages.image(named: name)
            .resizable()
            .frame(width: frame[2] * scale, height: frame[3] * scale)
            .offset(x: frame[0] * scale, y: frame[1] * scale)
    }
}

private enum SailorLayerImages {
    #if canImport(UIKit)
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 8 * 1024 * 1024
        cache.countLimit = 30
        return cache
    }()
    #endif

    static func image(named name: String) -> Image {
        #if canImport(UIKit)
        let key = name as NSString
        if let image = cache.object(forKey: key) { return Image(uiImage: image) }
        if let image = UIImage(named: name) {
            let cost = Int(image.size.width * image.size.height * image.scale * image.scale) * 4
            cache.setObject(image, forKey: key, cost: cost)
            return Image(uiImage: image)
        }
        #endif
        return Image(name)
    }
}

private struct SailorIcon: View {
    let name: String
    let width: CGFloat
    let height: CGFloat

    init(_ name: String, width: CGFloat, height: CGFloat) {
        self.name = name
        self.width = width
        self.height = height
    }

    var body: some View {
        Image("Sailor-icon-\(name)").resizable().frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

private struct SailorTabLayout: Layout {
    private let spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = arrangement(width: bounds.width, subviews: subviews)
        for (view, origin) in zip(subviews, layout.origins) {
            view.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                       anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func arrangement(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        let origins = subviews.map { view in
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            let origin = CGPoint(x: x, y: y)
            maxWidth = max(maxWidth, x + size.width)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            return origin
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}

private struct SailorCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.82), in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(SailorStyle.blue.opacity(0.20), lineWidth: 1.5)
            }
            .shadow(color: SailorStyle.ink.opacity(0.07), radius: 12, y: 4)
    }
}

private enum SailorStyle {
    static let ink = EunoiaColor.ink
    static let blue = EunoiaColor.softSeaBlue
    static let gold = EunoiaColor.gold
    static let muted = Color(hex: 0x6A8A98)
    static let activeText = EunoiaColor.oceanBlue

    enum Weight: String { case regular = "Regular", semibold = "SemiBold", bold = "Bold", extraBold = "ExtraBold" }

    private static let registered: Void = {
        for name in ["Nunito-Regular", "Nunito-SemiBold", "Nunito-Bold", "Nunito-ExtraBold", "Fraunces-Regular", "Fraunces-Italic"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }()

    static func font(_ size: CGFloat, _ weight: Weight = .regular, relativeTo: Font.TextStyle? = .body) -> Font {
        _ = registered
        let name = "Nunito-\(weight.rawValue)"
        if let relativeTo { return .custom(name, size: size, relativeTo: relativeTo) }
        return .custom(name, fixedSize: size)
    }

    static func display(_ size: CGFloat, italic: Bool = false) -> Font {
        _ = registered
        return .custom(italic ? "Fraunces-Italic" : "Fraunces-Regular", size: size, relativeTo: .title)
    }
}

private struct SailorRewardsView: View {
    let anchors: Int

    private var unlocked: [(item: WebSailor.Item, type: String)] {
        let items = WebSailor.items(in: .aura).map { ($0, "Aura") }
            + WebSailor.items(in: .companion).map { ($0, "Companion") }
            + WebSailor.decor.map { ($0, "Cabin Decor") }
        return Array(items.filter { $0.0.cost > 0 && $0.0.cost <= anchors }.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rewards & Inventory")
                .font(SailorStyle.font(15, .bold))
                .foregroundStyle(SailorStyle.ink)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 10) {
                stat("Currency", subtitle: "Gold Anchors") {
                    Text(anchors, format: .number)
                        .font(SailorStyle.font(22, .extraBold))
                        .foregroundStyle(SailorStyle.ink)
                }
                stat("Level", subtitle: WebDailyQuests.rank(for: anchors)) {
                    SailorIcon(rankIcon, width: 60, height: 60)
                }
            }
            if unlocked.isEmpty {
                Text("Complete quests to earn Gold Anchors and unlock items!")
                    .font(SailorStyle.font(13))
                    .foregroundStyle(Color(hex: 0x8A9AA8))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("UNLOCKED ITEMS")
                        .font(SailorStyle.font(12, .bold))
                        .tracking(0.72)
                        .foregroundStyle(SailorStyle.muted)
                    ForEach(unlocked, id: \.item.id) { entry in
                        HStack(spacing: 10) {
                            SailorIcon(entry.item.icon ?? "Shimmer", width: 30, height: 24)
                                .frame(width: 32, height: 32)
                                .background(Color(hex: 0xC6DDED).opacity(0.30), in: .rect(cornerRadius: 8))
                            VStack(alignment: .leading) {
                                Text(entry.item.label).font(SailorStyle.font(13, .semibold))
                                    .foregroundStyle(SailorStyle.ink)
                                Text(entry.type).font(SailorStyle.font(11))
                                    .foregroundStyle(Color(hex: 0x8A9AA8))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(hex: 0xF8F3EE).opacity(0.70), in: .rect(cornerRadius: 10))
                    }
                }
            }

            if let reward = WebSailor.nextRewards.first(where: { $0.cost > anchors }) {
                nextReward(reward)
            } else {
                Label {
                    Text("All items unlocked — you are a Captain!")
                } icon: {
                    SailorIcon("Trophy", width: 16, height: 16)
                }
                .font(SailorStyle.font(13, .semibold))
                .foregroundStyle(Color(hex: 0x8A6020))
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(SailorStyle.gold.opacity(0.08), in: .rect(cornerRadius: 12))
            }
        }
    }

    private var rankIcon: String {
        switch anchors {
        case ..<50: "Bucket"
        case ..<110: "Compass"
        case ..<175: "wheel"
        default: "Hat"
        }
    }

    private func stat<Content: View>(_ title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
            content()
            Text(subtitle)
        }
        .font(SailorStyle.font(11))
        .foregroundStyle(Color(hex: 0x8A9AA8))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color(hex: 0xF8F3EE).opacity(0.8), in: .rect(cornerRadius: 12))
    }

    private func nextReward(_ reward: WebSailor.Reward) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Reward").font(SailorStyle.font(12, .bold))
                .foregroundStyle(SailorStyle.muted)
            Text("Earn \(reward.cost - anchors) more Gold Anchors to unlock “\(reward.label)”")
                .font(SailorStyle.font(13))
                .foregroundStyle(SailorStyle.ink)
            GeometryReader { proxy in
                Capsule().fill(SailorStyle.blue.opacity(0.20))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(LinearGradient(colors: [SailorStyle.gold, Color(hex: 0xF0D080)],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: proxy.size.width * CGFloat(anchors) / CGFloat(reward.cost))
                    }
            }
            .frame(height: 8)
            .accessibilityHidden(true)
        }
        .padding(14)
        .background(Color(hex: 0xF8F3EE).opacity(0.8), in: .rect(cornerRadius: 14))
    }
}
