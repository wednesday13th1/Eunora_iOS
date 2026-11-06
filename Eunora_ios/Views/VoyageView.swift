import SwiftUI
import SwiftData

struct VoyageView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var profiles: [VoyageProfile]
    @Query private var allQuests: [DailyQuest]
    @Query private var checkIns: [CheckIn]
    @State private var showCheckIn = false
    @State private var rewardMessage: String?
    @State private var rewardAnchor = false
    @State private var anchorFlying = false
    @State private var oceanSurge = false
    @State private var showBottle = false

    private var today: String { Date.now.eunoiaDayKey }
    private var profile: VoyageProfile? { profiles.first }
    private var quests: [DailyQuest] { allQuests.filter { $0.dayKey == today } }
    private var weather: SeaWeather? { checkIns.first(where: { $0.dayKey == today }).flatMap { SeaWeather(rawValue: $0.weather) } }

    var body: some View {
        ZStack {
            StorybookBackground()
            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: EunoiaSpacing.lg) {
                        header
                        ZStack {
                            OceanScene(progress: profile?.distance ?? 0.12, weather: weather, destination: profile?.destination) {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                showBottle = true
                            }
                            if oceanSurge {
                                Text("The wind found your sails.").font(.story(20)).foregroundStyle(.white)
                                    .padding(.horizontal, 18).padding(.vertical, 10).background(EunoiaColor.deepOcean.opacity(0.82), in: Capsule())
                                    .transition(.move(edge: .bottom).combined(with: .opacity)).offset(y: 82)
                            }
                        }.id("ocean")
                        voyageStatus
                        if weather == nil { checkInPrompt }
                        QuestBoard(onComplete: showQuestReward)
                    }.eunoiaReadableContent().padding(.bottom, EunoiaSpacing.xl)
                }
                .onChange(of: oceanSurge) { _, isSailing in
                    if isSailing { withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) { reader.scrollTo("ocean", anchor: .center) } }
                }
            }
            if rewardAnchor {
                Image(systemName: "anchor.circle.fill").font(.system(size: 64)).foregroundStyle(EunoiaColor.gold)
                    .shadow(color: EunoiaColor.gold.opacity(0.5), radius: 14)
                    .rotationEffect(.degrees(anchorFlying ? 22 : -18))
                    .offset(x: anchorFlying ? 145 : 0, y: anchorFlying ? -315 : 30)
                    .scaleEffect(anchorFlying ? 0.35 : 1)
                    .transition(.scale.combined(with: .opacity)).accessibilityHidden(true)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCheckIn) { CheckInView() }
        .overlay(alignment: .bottom) {
            if let rewardMessage {
                Text(rewardMessage).font(.headline).foregroundStyle(.white).padding(.horizontal, 22).padding(.vertical, 14)
                    .background(EunoiaColor.deepOcean, in: Capsule()).padding(.bottom, 92).transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationDestination(isPresented: $showBottle) { BottleView() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: EunoiaSpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text("Good \(timeOfDay), Sailor.").font(.story(30)).foregroundStyle(EunoiaColor.deepOcean)
                Text("You don’t have to travel far today.").font(.system(size: 16)).foregroundStyle(EunoiaColor.secondaryText)
            }
            Spacer()
            Label("\(profile?.anchors ?? 0)", systemImage: "anchor").font(.headline).foregroundStyle(EunoiaColor.gold).padding(10).background(.white.opacity(0.7), in: Capsule())
        }.padding(.top, EunoiaSpacing.md)
    }

    private var voyageStatus: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SAILING TO").font(.caption2.weight(.bold)).tracking(1.5).foregroundStyle(.secondary)
                Text(profile?.destination ?? "Kyoto").font(.system(size: 28, weight: .bold)).foregroundStyle(EunoiaColor.primaryText)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Today’s distance").font(.caption).foregroundStyle(.secondary)
                Text("\(quests.filter(\.isCompleted).count) gentle steps").font(.system(size: 19, weight: .semibold)).foregroundStyle(EunoiaColor.deepOcean)
            }
        }
    }

    private var checkInPrompt: some View {
        Button { showCheckIn = true } label: {
            SoftCard { HStack(spacing: 14) {
                Image(systemName: "cloud.sun.fill").font(.title).foregroundStyle(EunoiaColor.gold)
                VStack(alignment: .leading, spacing: 3) { Text("How does the sea feel today?").font(.headline).foregroundStyle(EunoiaColor.ink); Text("A quiet check-in, with no scores.").font(.caption).foregroundStyle(.secondary) }
                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }}
        }.buttonStyle(.plain)
    }

    private func showQuestReward() {
        guard !reduceMotion else { return }
        anchorFlying = false
        withAnimation(.spring(response: 0.55, dampingFraction: 0.5)) { rewardAnchor = true }
        rewardMessage = ["A small step still moves the ship.", "You sailed a little farther today.", "That was enough for now."].randomElement()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.spring(response: 0.8, dampingFraction: 0.72)) { anchorFlying = true }
            try? await Task.sleep(for: .milliseconds(650)); UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation { rewardAnchor = false; oceanSurge = true }
            try? await Task.sleep(for: .seconds(1.6)); withAnimation { oceanSurge = false; rewardMessage = nil }
        }
    }

    private var timeOfDay: String { let h = Calendar.current.component(.hour, from: .now); return h < 12 ? "morning" : h < 18 ? "afternoon" : "evening" }
}

struct QuestCard: View {
    let quest: DailyQuest; let onComplete: () -> Void; let onSkip: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stamp = false
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        ParchmentCard {
            let layout = textSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(spacing: 14))
            layout {
                Image(systemName: quest.isCompleted ? "checkmark.circle.fill" : quest.symbol)
                    .font(.title2)
                    .foregroundStyle(EunoiaColor.deepOcean)
                    .frame(width: 32)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(quest.title).font(.headline).foregroundStyle(EunoiaColor.primaryText)
                    if quest.isSkipped {
                        Text("Resting here for today — no penalty.").font(.caption).foregroundStyle(.secondary)
                    } else if quest.isCompleted {
                        Text("Anchor earned").font(.subheadline).foregroundStyle(EunoiaColor.deepOcean)
                    } else {
                        Button("Not for me today", action: onSkip)
                            .font(.caption)
                            .frame(minHeight: 44)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !quest.isCompleted && !quest.isSkipped {
                    Button {
                        withAnimation(reduceMotion ? nil : EunoiaMotion.collectible) { stamp = true }
                        onComplete()
                    } label: {
                        Image(systemName: "anchor.circle.fill")
                            .font(.title)
                            .scaleEffect(stamp ? 1 : 0.86)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Stamp quest complete")
                }
            }
        }
    }
}
