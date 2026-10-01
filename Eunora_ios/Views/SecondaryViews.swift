import SwiftUI
import SwiftData

struct QuestsView: View {
    @Query private var quests: [DailyQuest]
    var body: some View {
        ZStack { StorybookBackground(); ScrollView { VStack(alignment: .leading, spacing: 14) {
            Text("Small things count.").font(.title3).foregroundStyle(.secondary)
            ForEach(quests.filter { $0.dayKey == Date.now.eunoiaDayKey }) { quest in
                SoftCard { HStack { Image(systemName: quest.symbol).foregroundStyle(EunoiaColor.deepOcean); Text(quest.title); Spacer(); Image(systemName: quest.isCompleted ? "checkmark.circle.fill" : quest.isSkipped ? "minus.circle" : "circle").foregroundStyle(quest.isCompleted ? EunoiaColor.gold : .secondary) } }
            }
            Text("Unfinished quests simply drift away at the end of the day. There is nothing to catch up on.").font(.footnote).foregroundStyle(.secondary).padding(.top, 8)
        }.padding() } }.navigationTitle("Quests")
    }
}

struct VoyageMapView: View {
    @Query private var profiles: [VoyageProfile]
    private let stops = [("Harbor", "house.fill"), ("Shell Island", "fossil.shell.fill"), ("Moonlight Bay", "moon.stars.fill"), ("Lantern Island", "lamp.desk.fill"), ("Destination", "flag.pattern.checkered")]
    var body: some View {
        ZStack { StorybookBackground(); ScrollView {
            VStack(spacing: 0) {
                Text("Every island appears in its own time.").font(.subheadline).foregroundStyle(.secondary).padding(.bottom, 24)
                ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                    let unlocked = index <= Int((profiles.first?.distance ?? 0.12) * 5)
                    HStack(spacing: 20) {
                        ZStack { Circle().fill(unlocked ? EunoiaColor.sky : EunoiaColor.sand.opacity(0.5)).frame(width: 68, height: 68); Image(systemName: unlocked ? stop.1 : "cloud.fog.fill").font(.title).foregroundStyle(unlocked ? EunoiaColor.deepOcean : .secondary) }
                        VStack(alignment: .leading) { Text(stop.0).font(.headline); Text(unlocked ? (index == 0 ? "Your voyage began here" : "Discovered") : "Waiting beyond the fog").font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                    }.accessibilityElement(children: .combine)
                    if index < stops.count - 1 { Path { path in path.move(to: .init(x: 34, y: 0)); path.addLine(to: .init(x: 34, y: 55)) }.stroke(EunoiaColor.dustyBlue, style: StrokeStyle(lineWidth: 3, dash: [5])).frame(height: 55) }
                }
            }.padding(24)
        }}.navigationTitle("Voyage Map")
    }
}

struct BottleView: View {
    @AppStorage("savedBottle") private var saved = false
    @State private var opened = false
    var body: some View {
        ZStack { StorybookBackground(); VStack(spacing: 28) {
            Spacer()
            Image(systemName: opened ? "envelope.open.fill" : "waterbottle.fill").font(.system(size: 110)).foregroundStyle(EunoiaColor.dustyBlue, EunoiaColor.gold).contentTransition(.symbolEffect(.replace))
            Text(opened ? "A note from the sea" : "A bottle washed ashore.").font(.title.bold()).foregroundStyle(EunoiaColor.ink)
            if opened {
                SoftCard { Text("“Some days, recovery means moving forward. Other days, it means staying afloat. Both count.”").font(.title3).multilineTextAlignment(.center).lineSpacing(6).foregroundStyle(EunoiaColor.ink) }.transition(.scale.combined(with: .opacity))
                Button { saved.toggle(); UIImpactFeedbackGenerator(style: .soft).impactOccurred() } label: { Label(saved ? "Saved to My Bottles" : "Save to My Bottles", systemImage: saved ? "heart.fill" : "heart") }.foregroundStyle(EunoiaColor.gold)
            } else { Button("Open gently") { withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) { opened = true }; UIImpactFeedbackGenerator(style: .soft).impactOccurred() }.buttonStyle(PrimaryButtonStyle()) }
            Spacer()
        }.padding(24) }.navigationTitle("Message in a Bottle").navigationBarTitleDisplayMode(.inline)
    }
}

struct CabinView: View {
    @Query private var profiles: [VoyageProfile]
    @State private var selectedHat = "sailorcap.fill"
    let items = [("sailorcap.fill", 0), ("partyhat.fill", 3), ("crown.fill", 7)]
    var body: some View {
        ZStack { LinearGradient(colors: [EunoiaColor.sand, EunoiaColor.cream], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea(); ScrollView { VStack(spacing: 24) {
            Text("Your quiet place at sea").foregroundStyle(.secondary)
            SoftCard { ZStack { RoundedRectangle(cornerRadius: 22).fill(EunoiaColor.deepOcean.opacity(0.12)).frame(height: 220); VStack { Image(systemName: selectedHat).font(.system(size: 44)).foregroundStyle(EunoiaColor.gold); Image(systemName: "person.crop.circle.fill").font(.system(size: 92)).foregroundStyle(EunoiaColor.dustyBlue); Text("Sailor").font(.headline) } } }
            VStack(alignment: .leading, spacing: 12) { Text("Wardrobe").font(.title2.bold()); HStack { ForEach(items, id: \.0) { item in
                let unlocked = (profiles.first?.anchors ?? 0) >= item.1
                Button { if unlocked { selectedHat = item.0 } } label: { VStack { Image(systemName: unlocked ? item.0 : "lock.fill").font(.title2); Text(item.1 == 0 ? "Aboard" : "\(item.1) ⚓").font(.caption) }.frame(maxWidth: .infinity, minHeight: 80).background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18)) }.foregroundStyle(unlocked ? EunoiaColor.deepOcean : .secondary).disabled(!unlocked)
            } } }
            SoftCard { HStack { Image(systemName: "lamp.table.fill").font(.largeTitle).foregroundStyle(EunoiaColor.gold); VStack(alignment: .leading) { Text("Cabin lamp").font(.headline); Text("A little warmth, already yours.").font(.caption).foregroundStyle(.secondary) }; Spacer() } }
        }.padding() } }.navigationTitle("Cabin")
    }
}

struct YouView: View {
    var body: some View {
        ZStack { StorybookBackground(); List {
            Section { NavigationLink { CaptainLogView() } label: { Label("Captain’s Log", systemImage: "book.closed.fill") }; NavigationLink { BottleView() } label: { Label("My Bottles", systemImage: "waterbottle.fill") } }
            Section("Support") { NavigationLink { LighthouseView() } label: { Label("Lighthouse", systemImage: "light.beacon.max.fill") } }
            Section { Text("Eunoia is designed to support your journey, but it is not a substitute for professional medical or mental-health care.").font(.footnote).foregroundStyle(.secondary) }
        }.scrollContentBackground(.hidden) }.navigationTitle("You")
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
