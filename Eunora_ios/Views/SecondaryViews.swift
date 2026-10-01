import SwiftUI
import SwiftData

struct QuestsView: View {
    @Environment(\.modelContext) private var context
    @Query private var quests: [DailyQuest]
    @Query private var profiles: [VoyageProfile]
    @State private var earnedAnchor = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [EunoiaColor.sand, EunoiaColor.cream], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView { VStack(alignment: .leading, spacing: 16) {
                Text("Captain’s Board").font(.story(31)).foregroundStyle(EunoiaColor.ink)
                Text("Stamp one small action when it feels right.").foregroundStyle(.secondary)
                ForEach(quests.filter { $0.dayKey == Date.now.eunoiaDayKey }) { quest in
                    QuestCard(quest: quest) { complete(quest) } onSkip: { withAnimation { quest.isSkipped = true } }
                }
                Text("Unfinished notes simply drift away tonight. There is nothing to catch up on.").font(.footnote).foregroundStyle(.secondary).padding(.top, 8)
            }.padding() }
            if earnedAnchor { Image(systemName: "anchor.circle.fill").font(.system(size: 76)).foregroundStyle(EunoiaColor.gold).shadow(color: EunoiaColor.gold.opacity(0.45), radius: 16).transition(.scale.combined(with: .opacity)) }
        }.navigationBarHidden(true)
    }
    private func complete(_ quest: DailyQuest) {
        guard !quest.isCompleted else { return }; quest.isCompleted = true; quest.isSkipped = false
        profiles.first?.anchors += 1; profiles.first?.distance = min(0.9, (profiles.first?.distance ?? 0.12) + 0.07)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { earnedAnchor = true }
        Task { @MainActor in try? await Task.sleep(for: .seconds(1)); withAnimation { earnedAnchor = false } }
    }
}

struct VoyageMapView: View {
    @Query private var profiles: [VoyageProfile]
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var selectedIsland: String?
    @State private var fog = true
    private let stops = [("Harbor", "house.fill", CGPoint(x: 75, y: 310)), ("Shell Island", "fossil.shell.fill", CGPoint(x: 245, y: 245)), ("Moonlight Bay", "moon.stars.fill", CGPoint(x: 120, y: 125)), ("Lantern Island", "lamp.desk.fill", CGPoint(x: 320, y: 85))]
    var body: some View {
        ZStack {
            EunoiaColor.sand.ignoresSafeArea()
            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 26).fill(EunoiaColor.parchment)
                    ForEach(0..<9, id: \.self) { i in Image(systemName: i.isMultiple(of: 3) ? "water.waves" : "sparkle").foregroundStyle(EunoiaColor.dustyBlue.opacity(0.48)).position(x: CGFloat(35 + (i * 71) % 330), y: CGFloat(45 + (i * 97) % 350)) }
                    Path { p in p.move(to: stops[0].2); stops.dropFirst().forEach { p.addLine(to: $0.2) } }.stroke(EunoiaColor.coral.opacity(0.65), style: StrokeStyle(lineWidth: 3, dash: [7, 8]))
                    ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                        let unlocked = index <= Int((profiles.first?.distance ?? 0.12) * 8)
                        Button { if unlocked { withAnimation(.spring) { selectedIsland = stop.0; scale = 1.35 } } } label: {
                            VStack(spacing: 2) { Image(systemName: unlocked ? stop.1 : "cloud.fog.fill").font(.system(size: 38)); Text(unlocked ? stop.0 : "Beyond the fog").font(.caption2.bold()) }
                        }.foregroundStyle(unlocked ? EunoiaColor.deepOcean : .secondary).position(stop.2)
                    }
                    Image(systemName: "safari.fill").font(.system(size: 42)).foregroundStyle(EunoiaColor.gold).position(x: 325, y: 340).onLongPressGesture { withAnimation { fog.toggle() } }
                    if fog { CloudFog().opacity(0.76).allowsHitTesting(false).transition(.opacity) }
                }.frame(width: 390, height: 410).scaleEffect(scale).offset(offset)
                    .gesture(DragGesture().onChanged { offset = $0.translation })
                    .simultaneousGesture(MagnifyGesture().onChanged { scale = min(max($0.magnification, 0.8), 2.2) })
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
            if let selectedIsland { VStack { Spacer(); ParchmentCard { HStack { Image(systemName: "bird.fill"); VStack(alignment: .leading) { Text("A new shore appeared.").font(.story(20)); Text(selectedIsland).font(.subheadline) }; Spacer(); Button { withAnimation { self.selectedIsland = nil; scale = 1 } } label: { Image(systemName: "xmark.circle.fill") } } }.padding() } }
        }.navigationTitle("Voyage Map").navigationBarTitleDisplayMode(.inline)
    }
}

private struct CloudFog: View {
    var body: some View { HStack(spacing: -25) { ForEach(0..<5, id: \.self) { _ in Circle().fill(.white).frame(width: 110) } }.blur(radius: 8).offset(x: 90, y: -100) }
}

struct BottleView: View {
    @AppStorage("savedBottle") private var saved = false
    @State private var stage = 0
    @State private var bottleDrag: CGSize = .zero
    @State private var corkDrag: CGFloat = 0
    @State private var paperDrag: CGFloat = 0
    @State private var sparkle = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [EunoiaColor.sky, EunoiaColor.foam, EunoiaColor.dustyBlue], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if stage < 3 { discoveryScene } else { messageScene.transition(.scale(scale: 0.7).combined(with: .opacity)) }
        }.navigationTitle("Message from the sea").navigationBarTitleDisplayMode(.inline)
    }

    private var discoveryScene: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(stage == 0 ? "You found something…" : stage == 1 ? "Pull the cork ↑" : "Draw out the little scroll ↑")
                .font(.story(25)).foregroundStyle(EunoiaColor.ink).animation(.easeInOut, value: stage)
            ZStack(alignment: .top) {
                BottleGlyph().frame(width: 104, height: 220).scaleEffect(stage == 0 ? 0.82 : 1)
                if stage == 1 {
                    Capsule().fill(EunoiaColor.wood).frame(width: 42, height: 42).offset(y: -10 + corkDrag)
                        .gesture(DragGesture().onChanged { corkDrag = min(0, $0.translation.height) }.onEnded { _ in
                            if corkDrag < -65 { pop(); } else { withAnimation(.spring) { corkDrag = 0 } }
                        })
                }
                if stage == 2 {
                    RoundedRectangle(cornerRadius: 6).fill(EunoiaColor.parchment).frame(width: 50, height: 100).offset(y: 42 + paperDrag)
                        .overlay(Image(systemName: "wave.3.right").foregroundStyle(EunoiaColor.gold).offset(y: 42 + paperDrag))
                        .gesture(DragGesture().onChanged { paperDrag = min(0, $0.translation.height) }.onEnded { _ in
                            if paperDrag < -90 { withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { stage = 3 } } else { withAnimation(.spring) { paperDrag = 0 } }
                        })
                }
            }.offset(bottleDrag).rotationEffect(.degrees(Double(bottleDrag.width / 18)))
                .gesture(DragGesture().onChanged { bottleDrag = $0.translation }.onEnded { _ in
                    if bottleDrag.height < -90 { withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) { stage = 1; bottleDrag = .zero }; UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
                    else { withAnimation(.spring) { bottleDrag = .zero } }
                }, isEnabled: stage == 0)
            Text(stage == 0 ? "Drag the bottle up from the waves" : "") .font(.subheadline).foregroundStyle(.secondary)
            WaveShape(phase: 0.5).fill(EunoiaColor.deepOcean.opacity(0.72)).frame(height: 120).padding(.horizontal, -30)
        }.padding(24)
    }

    private var messageScene: some View {
        ScrollView { VStack(spacing: 20) {
            Text("A message from the sea").font(.story(30)).foregroundStyle(EunoiaColor.ink)
            ParchmentCard { VStack(spacing: 18) {
                HStack { Image(systemName: "fossil.shell.fill"); Spacer(); Image(systemName: "star.fill") }.foregroundStyle(EunoiaColor.gold)
                Text("“Some days, moving forward means sailing.\n\nOther days, it means staying afloat.\n\nBoth count.”")
                    .font(.story(23, weight: .regular)).multilineTextAlignment(.center).lineSpacing(5).foregroundStyle(EunoiaColor.ink)
                Image(systemName: "anchor").foregroundStyle(EunoiaColor.dustyBlue)
            }}
            Text(saved ? "Safe on your shelf" : "Keep this bottle?").font(.headline).foregroundStyle(EunoiaColor.ink)
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(EunoiaColor.wood).frame(height: 22).offset(y: 48)
                BottleGlyph(tint: EunoiaColor.dustyBlue).frame(width: 42, height: 88).scaleEffect(saved ? 0.65 : 1).offset(y: saved ? 30 : 0)
                    .gesture(DragGesture().onEnded { value in if value.translation.height > 35 { saved = true; sparkle = true; UINotificationFeedbackGenerator().notificationOccurred(.success) } })
                if sparkle { Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(EunoiaColor.gold).offset(x: 45, y: 8).transition(.scale.combined(with: .opacity)) }
            }.frame(height: 120)
            if !saved { Text("Drag it down to the wooden shelf").font(.caption).foregroundStyle(.secondary) }
        }.padding(24) }
    }

    private func pop() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred(); withAnimation(.spring(response: 0.4, dampingFraction: 0.42)) { corkDrag = -150; stage = 2 } }
}

struct CabinView: View {
    @Query private var profiles: [VoyageProfile]
    @State private var selectedHat = "sailorcap.fill"
    let items = [("sailorcap.fill", 0), ("partyhat.fill", 3), ("crown.fill", 7)]
    @State private var lampOn = true
    @State private var curtainOpen = false
    @State private var plantWiggle = false
    var body: some View {
        ZStack { LinearGradient(colors: [lampOn ? EunoiaColor.sand : EunoiaColor.deepOcean.opacity(0.8), EunoiaColor.cream], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea(); ScrollView { VStack(spacing: 24) {
            Text("Your quiet place at sea").font(.story(21)).foregroundStyle(EunoiaColor.ink)
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(EunoiaColor.wood.opacity(0.32)).frame(height: 330)
                Circle().fill(EunoiaColor.sky).frame(width: 120).overlay(Image(systemName: "water.waves").foregroundStyle(EunoiaColor.deepOcean)).overlay(Rectangle().fill(EunoiaColor.wood).frame(width: 5)).offset(x: 90, y: -72)
                Image(systemName: curtainOpen ? "curtains.open" : "curtains.closed").font(.system(size: 82)).foregroundStyle(EunoiaColor.coral.opacity(0.8)).offset(x: 90, y: -72).onTapGesture { withAnimation(.spring) { curtainOpen.toggle() } }
                NavigationLink(destination: VoyageMapView()) { Image(systemName: "map.fill").font(.system(size: 56)).foregroundStyle(EunoiaColor.parchment, EunoiaColor.coral) }.offset(x: -95, y: -75)
                Image(systemName: "lamp.table.fill").font(.system(size: 54)).foregroundStyle(lampOn ? EunoiaColor.gold : .secondary).offset(x: 105, y: 95).onTapGesture { withAnimation { lampOn.toggle() } }
                Image(systemName: "leaf.fill").font(.system(size: 57)).foregroundStyle(.green.opacity(0.65)).rotationEffect(.degrees(plantWiggle ? 9 : -4)).offset(x: -110, y: 95).onTapGesture { withAnimation(.spring(response: 0.3, dampingFraction: 0.35)) { plantWiggle.toggle() } }
                VStack { Image(systemName: selectedHat).font(.system(size: 38)).foregroundStyle(EunoiaColor.gold); Image(systemName: "person.crop.circle.fill").font(.system(size: 78)).foregroundStyle(EunoiaColor.dustyBlue) }.onTapGesture(count: 2) { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                NavigationLink(destination: BottleShelfView()) { VStack(spacing: 3) { HStack(spacing: 6) { ForEach(0..<3, id: \.self) { _ in BottleGlyph().frame(width: 20, height: 43) } }; Text("Bottles").font(.caption2.bold()).foregroundStyle(EunoiaColor.cream) } }.offset(x: 0, y: 116)
            }.padding(.horizontal)
            VStack(alignment: .leading, spacing: 12) { Text("Wardrobe").font(.title2.bold()); HStack { ForEach(items, id: \.0) { item in
                let unlocked = (profiles.first?.anchors ?? 0) >= item.1
                Button { if unlocked { selectedHat = item.0 } } label: { VStack { Image(systemName: unlocked ? item.0 : "lock.fill").font(.title2); Text(item.1 == 0 ? "Aboard" : "\(item.1) ⚓").font(.caption) }.frame(maxWidth: .infinity, minHeight: 80).background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18)) }.foregroundStyle(unlocked ? EunoiaColor.deepOcean : .secondary).disabled(!unlocked)
            } } }
        }.padding() } }.navigationTitle("Cabin")
    }
}

struct YouView: View {
    var body: some View {
        ZStack { StorybookBackground(); List {
            Section { NavigationLink { CaptainLogView() } label: { Label("Captain’s Log", systemImage: "book.closed.fill") }; NavigationLink { BottleShelfView() } label: { Label("My Bottles", systemImage: "waterbottle.fill") } }
            Section("Support") { NavigationLink { LighthouseView() } label: { Label("Lighthouse", systemImage: "light.beacon.max.fill") } }
            Section { Text("Eunoia is designed to support your journey, but it is not a substitute for professional medical or mental-health care.").font(.footnote).foregroundStyle(.secondary) }
        }.scrollContentBackground(.hidden) }.navigationTitle("You")
    }
}

struct BottleShelfView: View {
    @AppStorage("savedBottle") private var saved = false
    @State private var selected = false
    @State private var shaking = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [EunoiaColor.sand, EunoiaColor.cream], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("My Bottles").font(.story(32)).foregroundStyle(EunoiaColor.ink)
                Text(saved ? "Treasures gathered along your voyage" : "Your first sea treasure will wait here.").foregroundStyle(.secondary)
                TabView {
                    ForEach(0..<3, id: \.self) { shelf in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 12).fill(EunoiaColor.wood).frame(height: 24)
                            if saved && shelf == 0 {
                                BottleGlyph(tint: EunoiaColor.dustyBlue).frame(width: 64, height: 132)
                                    .rotationEffect(.degrees(shaking ? 6 : 0)).scaleEffect(selected ? 1.14 : 1)
                                    .onTapGesture { withAnimation(.spring) { selected.toggle() } }
                                    .onLongPressGesture { withAnimation(.spring(response: 0.18, dampingFraction: 0.25)) { shaking.toggle() } }
                                    .accessibilityLabel("Saved message bottle").accessibilityHint("Tap to read its message")
                            } else { Text("A quiet shelf").font(.caption).foregroundStyle(EunoiaColor.cream).padding(.bottom, 7) }
                        }.padding(.horizontal, 30)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .always)).frame(height: 230)
                if selected {
                    ParchmentCard { Text("“Some days, moving forward means sailing. Other days, it means staying afloat. Both count.”").font(.story(20, weight: .regular)).multilineTextAlignment(.center).foregroundStyle(EunoiaColor.ink) }.padding(.horizontal).transition(.move(edge: .bottom).combined(with: .opacity))
                } else if saved { Text("Tap the bottle to read • Hold it to make it wobble").font(.caption).foregroundStyle(.secondary) }
                Spacer()
            }.padding(.top, 20)
        }.navigationBarTitleDisplayMode(.inline)
    }
}

struct CaptainLogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LogEntry.createdAt, order: .reverse) private var entries: [LogEntry]
    @State private var difficult = ""; @State private var helped = ""; @State private var proud = ""
    var body: some View {
        ZStack { StorybookBackground(); ScrollView { VStack(alignment: .leading, spacing: 16) {
            Text("Everything here is optional and stays on this device.").font(.subheadline).foregroundStyle(.secondary)
            reflectionField("Something that felt difficult today", text: $difficult)
            reflectionField("Something that helped", text: $helped)
            reflectionField("Something I’m proud of", text: $proud)
            Button("Save today’s reflection") { guard !difficult.isEmpty || !helped.isEmpty || !proud.isEmpty else { return }; context.insert(LogEntry(difficult: difficult, helped: helped, proud: proud)); difficult = ""; helped = ""; proud = "" }.buttonStyle(PrimaryButtonStyle())
            if !entries.isEmpty { Text("Earlier pages").font(.title2.bold()).padding(.top, 16) }
            ForEach(entries) { entry in SoftCard { VStack(alignment: .leading, spacing: 8) { Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted)).font(.caption.weight(.semibold)).foregroundStyle(EunoiaColor.gold); if !entry.difficult.isEmpty { Text(entry.difficult) }; if !entry.helped.isEmpty { Text(entry.helped) }; if !entry.proud.isEmpty { Text(entry.proud) } } } }
        }.padding() } }.navigationTitle("Captain’s Log")
    }
    private func reflectionField(_ title: String, text: Binding<String>) -> some View { VStack(alignment: .leading, spacing: 7) { Text(title).font(.headline); TextField("Write as little or as much as you like…", text: text, axis: .vertical).lineLimit(3...6).padding().background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 16)) } }
}

struct LighthouseView: View {
    var body: some View {
        ZStack { StorybookBackground(); ScrollView { VStack(alignment: .leading, spacing: 18) {
            HStack { Spacer(); ZStack { Circle().fill(EunoiaColor.gold.opacity(0.16)).frame(width: 150, height: 150); Image(systemName: "light.beacon.max.fill").font(.system(size: 72)).foregroundStyle(EunoiaColor.gold, EunoiaColor.deepOcean) }; Spacer() }
            Text("You don’t have to navigate alone.").font(.title.bold()).foregroundStyle(EunoiaColor.ink)
            SoftCard { VStack(alignment: .leading, spacing: 8) { Label("Find support", systemImage: "person.2.fill").font(.headline); Text("Consider reaching out to someone you trust, a family member, counselor, doctor, or an established eating-disorder support organization.").foregroundStyle(.secondary) } }
            SoftCard { VStack(alignment: .leading, spacing: 8) { Label("Need help now?", systemImage: "phone.fill").font(.headline).foregroundStyle(.red); Text("If you may be in immediate danger or unable to keep yourself safe, contact your local emergency service now. Crisis resources vary by country.").foregroundStyle(.secondary) } }
            Text("Eunoia is designed to support your journey, but it is not a substitute for professional medical or mental-health care.").font(.footnote).foregroundStyle(.secondary)
        }.padding() } }.navigationTitle("Lighthouse")
    }
}
