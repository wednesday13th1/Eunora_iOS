import SwiftUI
import SwiftData

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
    @AppStorage("cabinHat") private var selectedHat = "sailorcap.fill"
    let items = [("sailorcap.fill", 0), ("partyhat.fill", 3), ("crown.fill", 7)]
    @AppStorage("cabinLampOn") private var lampOn = true
    @State private var mapOpen = false
    @State private var plantWiggle = false
    @State private var bottlesLifted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ZStack { StorybookBackground(); ScrollView { LazyVStack(alignment: .leading, spacing: EunoiaSpacing.xl) {
            VStack(alignment: .leading, spacing: EunoiaSpacing.lg) { Text("Sailor").font(.eunoiaScreenTitle).foregroundStyle(EunoiaColor.primaryText); Text("Your quiet place at sea").font(.story(30)).foregroundStyle(EunoiaColor.deepOcean).frame(maxWidth: .infinity) }
            NavigationLink {
                SettingsView()
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .frame(minHeight: 44)
            }
            GeometryReader { proxy in
                let w = proxy.size.width
                ZStack {
                    RoundedRectangle(cornerRadius: EunoiaRadius.hero).fill(EunoiaColor.warmSand.opacity(lampOn ? 0.62 : 0.42))
                    Rectangle().fill(EunoiaColor.wood.opacity(0.18)).frame(height: w * 0.29).frame(maxHeight: .infinity, alignment: .bottom).clipShape(RoundedRectangle(cornerRadius: EunoiaRadius.hero))
                    Circle().fill(EunoiaColor.mistBlue).overlay(WaveShape(phase: plantWiggle ? 0.5 : 0).fill(EunoiaColor.oceanBlue.opacity(0.7)).offset(y: 35)).overlay(Circle().stroke(EunoiaColor.deepOcean, lineWidth: 8)).frame(width: w * 0.31).offset(x: w * 0.27, y: -w * 0.22)
                    Button { withAnimation(EunoiaMotion.collectible) { mapOpen.toggle() } } label: { Image(systemName: "map.fill").font(.system(size: w * 0.14)).foregroundStyle(EunoiaColor.lightSand, EunoiaColor.coral).rotationEffect(.degrees(mapOpen ? 0 : -8)) }.offset(x: -w * 0.31, y: -w * 0.25)
                    VStack(spacing: 0) { Image(systemName: selectedHat).font(.system(size: 36)).foregroundStyle(EunoiaColor.gold); Image(systemName: "person.crop.circle.fill").font(.system(size: 82)).foregroundStyle(EunoiaColor.softSeaBlue) }.offset(y: 12)
                    Image(systemName: "leaf.fill").font(.system(size: 58)).foregroundStyle(EunoiaColor.leaf).rotationEffect(.degrees(plantWiggle ? 7 : -3)).offset(x: -w * 0.33, y: w * 0.31).onTapGesture { withAnimation(EunoiaMotion.collectible) { plantWiggle.toggle() } }
                    Image(systemName: "lamp.table.fill").font(.system(size: 55)).foregroundStyle(lampOn ? EunoiaColor.gold : EunoiaColor.secondaryText).shadow(color: lampOn ? EunoiaColor.gold.opacity(0.5) : .clear, radius: 20).offset(x: w * 0.34, y: w * 0.31).onTapGesture { withAnimation(EunoiaMotion.normal) { lampOn.toggle() } }
                    NavigationLink(destination: BottleShelfView()) { HStack(spacing: 8) { ForEach(0..<3, id: \.self) { _ in BottleGlyph().frame(width: 26, height: 55) } }.padding(.horizontal, 14).padding(.top, 8).background(EunoiaColor.wood.opacity(0.7), in: RoundedRectangle(cornerRadius: 8)) }
                        .offset(y: w * 0.34 - (bottlesLifted ? 9 : 0)).shadow(color: bottlesLifted ? EunoiaColor.gold.opacity(0.45) : .clear, radius: 12).simultaneousGesture(TapGesture().onEnded { withAnimation(EunoiaMotion.collectible) { bottlesLifted = true } })
                }.onAppear { guard !reduceMotion else { return }; withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { plantWiggle = true } }
            }.aspectRatio(1, contentMode: .fit)
            VStack(alignment: .leading, spacing: EunoiaSpacing.md) { Text("Wardrobe").font(.eunoiaSectionTitle).foregroundStyle(EunoiaColor.primaryText); LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) { ForEach(items, id: \.0) { item in
                let unlocked = (profiles.first?.anchors ?? 0) >= item.1
                Button { if unlocked { withAnimation(EunoiaMotion.collectible) { selectedHat = item.0 } } } label: { VStack(spacing: 8) { Image(systemName: unlocked ? item.0 : "lock.fill").font(.title2); Text(item.1 == 0 ? "Aboard" : "\(item.1) ⚓").font(.caption.weight(.semibold)); if selectedHat == item.0 { Text("Equipped").font(.system(size: 10, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(EunoiaColor.gold.opacity(0.2), in: Capsule()) } }.frame(maxWidth: .infinity, minHeight: 106).background(EunoiaColor.card, in: RoundedRectangle(cornerRadius: EunoiaRadius.card)).overlay(RoundedRectangle(cornerRadius: EunoiaRadius.card).stroke(selectedHat == item.0 ? EunoiaColor.gold : .clear, lineWidth: 1.5)) }.foregroundStyle(unlocked ? EunoiaColor.deepOcean : EunoiaColor.secondaryText).opacity(unlocked ? 1 : 0.45).disabled(!unlocked)
            } } }
        }.eunoiaReadableContent().padding(.top, EunoiaSpacing.md) } }.toolbar(.hidden, for: .navigationBar)
    }
}

struct YouView: View {
    var body: some View {
        ZStack { StorybookBackground(); ScrollView { LazyVStack(alignment: .leading, spacing: EunoiaSpacing.xl) {
            Text("You").font(.eunoiaScreenTitle).foregroundStyle(EunoiaColor.primaryText)
            EditorialHeading(text: "Your own corner of the voyage", size: 30)
            VStack(spacing: EunoiaSpacing.md) {
                destinationRow("Captain’s Log", icon: "book.closed.fill", subtitle: "A private page for today") { CaptainLogView() }
                destinationRow("My Bottles", icon: "waterbottle.fill", subtitle: "Messages gathered at sea") { BottleShelfView() }
                destinationRow("Lighthouse", icon: "light.beacon.max.fill", subtitle: "Calm support when you need it") { LighthouseView() }
            }
            Text("Eunoia is designed to support your journey, but it is not a substitute for professional medical or mental-health care.").font(.footnote).foregroundStyle(EunoiaColor.secondaryText).lineSpacing(3)
        }.eunoiaReadableContent().padding(.top, EunoiaSpacing.lg) } }.toolbar(.hidden, for: .navigationBar)
    }
    private func destinationRow<Destination: View>(_ title: String, icon: String, subtitle: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) { EunoiaCard(radius: EunoiaRadius.largeCard) { HStack(spacing: EunoiaSpacing.md) { Image(systemName: icon).font(.system(size: 26)).foregroundStyle(EunoiaColor.gold).frame(width: 44, height: 44).background(EunoiaColor.lightSand, in: Circle()); VStack(alignment: .leading, spacing: 4) { Text(title).font(.system(size: 20, weight: .semibold)); Text(subtitle).font(.system(size: 14)).foregroundStyle(EunoiaColor.secondaryText) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(EunoiaColor.secondaryText) } } }.buttonStyle(.plain).foregroundStyle(EunoiaColor.primaryText)
    }
}

struct BottleShelfView: View {
    fileprivate enum Phase: Equatable {
        case idle
        case pressingCork
        case pullingCork
        case bottleReaction
        case revealingLetter
        case liftingLetter
        case openingLetter
        case opened
        case closing
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Phase = .idle
    @State private var letter = WebLetter.all[0]
    @State private var sceneStarted = false
    @State private var hintPulse = false
    @State private var particlesVisible = false
    @State private var corkPressScale: CGFloat = 1
    @State private var corkPullOffset: CGFloat = 0
    @State private var corkPullRotation: Double = 0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LettersAtmosphere(isMoving: sceneStarted && !reduceMotion)

                ScrollView {
                    VStack(spacing: EunoiaSpacing.sm) {
                        Text("LETTERS").font(.caption.weight(.semibold)).tracking(3.4)
                        EditorialHeading(text: "Letters washed ashore")
                            .accessibilityAddTraits(.isHeader)
                        Text("Messages carried across the sea, waiting to be discovered.")
                            .font(.body)
                            .foregroundStyle(EunoiaColor.secondaryText)
                        ScrollView(.horizontal) {
                            HStack(spacing: EunoiaSpacing.xs) {
                                ForEach(WebLetter.all) { bottle in
                                    Button {
                                        letter = bottle
                                    } label: {
                                        Label(bottle.author, systemImage: "waterbottle.fill")
                                            .padding(.horizontal, 12)
                                            .frame(minHeight: 44)
                                            .background(letter.id == bottle.id ? EunoiaColor.mistBlue : EunoiaColor.card, in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityAddTraits(letter.id == bottle.id ? .isSelected : [])
                                }
                            }
                        }
                        .defaultScrollAnchor(.leading)
                        .disabled(phase != .idle)

                        BottleDiscoveryScene(
                            glass: letter.glass,
                            phase: phase,
                            animateIdle: sceneStarted && !reduceMotion,
                            hintPulse: hintPulse,
                            particlesVisible: particlesVisible,
                            corkPressScale: corkPressScale,
                            corkPullOffset: corkPullOffset,
                            corkPullRotation: corkPullRotation,
                            onCorkTap: openLetter
                        )
                        .frame(height: 430)
                        .allowsHitTesting(phase == .idle)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundStyle(EunoiaColor.deepOcean)
                    .padding(.vertical, EunoiaSpacing.md)
                    .eunoiaReadableContent()
                }
                .accessibilityHidden(showsPaper)
                .allowsHitTesting(!showsPaper)
                .blur(radius: isReading ? 3.5 : 0)
                .opacity(isReading ? 0.48 : 1)

                if showsPaper {
                    FloatingLetter(phase: phase, letter: letter, close: closeLetter)
                        .frame(
                            width: min(EunoiaLayout.readableWidth, proxy.size.width - 28),
                            height: max(1, proxy.size.height - EunoiaSpacing.xxl * 2)
                        )
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2 - EunoiaSpacing.md)
                        .offset(y: phase == .liftingLetter ? proxy.size.height * 0.11 - 218 : 0)
                        .transition(.identity)
                        .zIndex(4)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            sceneStarted = true
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { hintPulse = true }
        }
        .onDisappear { animationTask?.cancel() }
    }

    private var showsPaper: Bool {
        switch phase { case .liftingLetter, .openingLetter, .opened, .closing: true; default: false }
    }

    private var isReading: Bool {
        switch phase { case .openingLetter, .opened, .closing: true; default: false }
    }

    private func openLetter() {
        guard phase == .idle else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if reduceMotion {
            phase = .opened
            return
        }
        phase = .pressingCork
        withAnimation(.easeInOut(duration: 0.075)) { corkPressScale = 0.96 }
        animationTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(75))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.075)) { corkPressScale = 1 }
            try? await Task.sleep(for: .milliseconds(75))
            guard !Task.isCancelled else { return }

            phase = .pullingCork
            withAnimation(.easeInOut(duration: 0.12)) {
                corkPullOffset = -13
                corkPullRotation = 3.5
            }
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.11)) {
                corkPullOffset = -34
                corkPullRotation = -2.8
            }
            try? await Task.sleep(for: .milliseconds(110))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.17)) {
                corkPullOffset = -91
                corkPullRotation = 5
            }
            try? await Task.sleep(for: .milliseconds(170))
            guard !Task.isCancelled else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            particlesVisible = true
            withAnimation(.easeOut(duration: 0.12)) { phase = .bottleReaction }
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.36, 0, 0.2, 1, duration: 0.70)) { phase = .revealingLetter }
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            phase = .liftingLetter
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.22, 0.72, 0.24, 1, duration: 0.30)) { phase = .openingLetter }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.30)) { phase = .opened }
            particlesVisible = false
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    private func closeLetter() {
        guard phase == .opened else { return }
        if reduceMotion {
            phase = .idle
            return
        }
        withAnimation(.easeInOut(duration: 0.26)) { phase = .closing }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            phase = .idle
            corkPressScale = 1
            corkPullOffset = 0
            corkPullRotation = 0
        }
    }
}

private struct LettersAtmosphere: View {
    let isMoving: Bool
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(hex: 0xEFF9FA), EunoiaColor.mistBlue, Color(hex: 0xD8EBEE)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            Circle().fill(.white.opacity(0.22)).frame(width: 290, height: 150).blur(radius: 42).offset(x: isMoving ? 90 : -70, y: -220)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: isMoving)
            WaveShape(phase: isMoving ? 0.7 : -0.25).fill(EunoiaColor.deepOcean.opacity(0.045)).frame(height: 155).blur(radius: 5).offset(y: 28)
                .animation(.linear(duration: 7.4).repeatForever(autoreverses: true), value: isMoving)
            WaveShape(phase: isMoving ? -0.5 : 0.35).fill(.white.opacity(0.15)).frame(height: 115).blur(radius: 7).offset(y: 38)
                .animation(.easeInOut(duration: 5.8).repeatForever(autoreverses: true), value: isMoving)
        }
    }
}

private struct BottleDiscoveryScene: View {
    let glass: UInt
    let phase: BottleShelfView.Phase
    let animateIdle: Bool
    let hintPulse: Bool
    let particlesVisible: Bool
    let corkPressScale: CGFloat
    let corkPullOffset: CGFloat
    let corkPullRotation: Double
    let onCorkTap: () -> Void

    private var isPressing: Bool { phase == .pressingCork }
    private var corkIsFree: Bool {
        switch phase { case .bottleReaction, .revealingLetter, .liftingLetter, .openingLetter, .opened, .closing: true; default: false }
    }
    private var letterIsEmerging: Bool { phase == .revealingLetter }
    private var keepsInternalPaper: Bool { phase == .idle || phase == .pressingCork || phase == .pullingCork || phase == .bottleReaction }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !animateIdle)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let float = animateIdle ? CGFloat(sin(t * .pi * 2 / 4.8) * 4) : 0
            let drift = animateIdle ? CGFloat(sin(t * .pi * 2 / 7.4) * 1.5) : 0
            let tilt = animateIdle ? CGFloat(sin(t * .pi * 2 / 6.2) * 0.72) : 0
            GeometryReader { proxy in
                let centerY = proxy.size.height / 2
                let mouthY = centerY - 135
                ZStack {
                    Capsule().fill(EunoiaColor.deepOcean.opacity(0.11)).frame(width: 154, height: 17).blur(radius: 7)
                        .scaleEffect(x: 1 - abs(float) * 0.009).position(x: proxy.size.width / 2, y: centerY + 149)

                    if phase == .bottleReaction || letterIsEmerging {
                        RolledPaper()
                            .frame(width: 76, height: 166)
                            .scaleEffect(letterIsEmerging ? 1 : 0.92, anchor: .bottom)
                            .rotationEffect(.degrees(letterIsEmerging ? 2 : -1.5))
                            .opacity(letterIsEmerging ? 1 : 0)
                            .position(
                                x: proxy.size.width / 2 + (letterIsEmerging ? 0 : -2),
                                y: letterIsEmerging ? mouthY - 83 : mouthY + 78
                            )
                            .mask(alignment: .top) {
                                Rectangle().frame(height: max(0, mouthY + 2))
                            }
                            .zIndex(1)
                    }

                    PremiumBottle(glass: glass, paperVisible: keepsInternalPaper)
                        .frame(width: 136, height: 270)
                        .rotationEffect(.degrees(tilt + (phase == .bottleReaction ? -1.2 : 0)))
                        .scaleEffect(x: phase == .bottleReaction ? 1.012 : 1, y: isPressing ? 0.997 : phase == .bottleReaction ? 0.992 : 1)
                        .offset(x: drift + (phase == .bottleReaction ? 2 : 0), y: float + (isPressing ? 3 : corkIsFree ? 2 : 0))
                        .position(x: proxy.size.width / 2, y: centerY)
                        .zIndex(2)

                    Button(action: onCorkTap) {
                        CorkPiece()
                            .frame(width: 38, height: 42)
                            .frame(width: 48, height: 48)
                            .contentShape(Rectangle())
                    }
                        .buttonStyle(.plain)
                        .offset(y: 3)
                        .position(x: proxy.size.width / 2 + drift + (corkIsFree ? 18 : 0), y: mouthY + 18 + float + (isPressing ? 3 : 0) + corkPullOffset)
                        .scaleEffect(corkPressScale)
                        .rotationEffect(.degrees(corkIsFree ? 10 : corkPullRotation + tilt * 0.2))
                        .opacity(phase == .openingLetter || phase == .opened || phase == .closing ? 0 : 1)
                        .accessibilityLabel("Bottle cork").accessibilityHint("Double tap to open the bottle and reveal the letter")
                        .accessibilityAddTraits(.isButton)
                        .zIndex(3)

                    if particlesVisible {
                        ForEach(0..<5, id: \.self) { index in
                            Circle().fill(index.isMultiple(of: 2) ? Color.white : EunoiaColor.gold)
                                .frame(width: index.isMultiple(of: 2) ? 3 : 2)
                                .position(x: proxy.size.width / 2 + CGFloat(index - 2) * 10, y: mouthY - 12 - CGFloat(index % 2) * 14)
                                .opacity(letterIsEmerging ? 0.48 : 0)
                                .zIndex(4)
                        }
                    }

                    if phase == .idle || phase == .pressingCork {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.turn.left.up").font(.system(size: 11, weight: .light))
                            Text("TAP THE CORK").font(.system(size: 11, weight: .semibold)).tracking(1.7)
                        }
                        .foregroundStyle(EunoiaColor.deepOcean)
                        .opacity(hintPulse ? 0.72 : 0.38)
                        .position(x: proxy.size.width / 2 + 73, y: mouthY - 8 - (hintPulse ? 3 : 0))
                    }
                }
            }
        }
    }
}

private struct PremiumBottle: View {
    let glass: UInt
    let paperVisible: Bool
    var body: some View {
        ZStack(alignment: .top) {
            if paperVisible {
                RolledPaper().frame(width: 52, height: 126).rotationEffect(.degrees(-4)).offset(y: 94).opacity(0.66)
            }
            BottleSilhouette().fill(LinearGradient(colors: [Color(hex: glass).opacity(0.48), Color(hex: glass).opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing))
            BottleSilhouette().stroke(Color.white.opacity(0.42), lineWidth: 2)
            Capsule().fill(Color.white.opacity(0.27)).frame(width: 9, height: 148).blur(radius: 1).rotationEffect(.degrees(3)).offset(x: -37, y: 70)
            Capsule().fill(EunoiaColor.deepOcean.opacity(0.08)).frame(width: 13, height: 172).blur(radius: 4).offset(x: 43, y: 72)
            Ellipse().stroke(Color.white.opacity(0.29), lineWidth: 5).frame(width: 102, height: 19).offset(y: 241)
            RoundedRectangle(cornerRadius: 8).stroke(EunoiaColor.deepOcean.opacity(0.11), lineWidth: 4).frame(width: 48, height: 61).offset(y: 3)
        }.shadow(color: EunoiaColor.deepOcean.opacity(0.12), radius: 13, y: 9)
    }
}

private struct BottleSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.38, y: 0)); p.addLine(to: CGPoint(x: w * 0.62, y: 0))
        p.addLine(to: CGPoint(x: w * 0.64, y: h * 0.22))
        p.addCurve(to: CGPoint(x: w * 0.86, y: h * 0.35), control1: CGPoint(x: w * 0.65, y: h * 0.29), control2: CGPoint(x: w * 0.83, y: h * 0.29))
        p.addCurve(to: CGPoint(x: w * 0.92, y: h * 0.88), control1: CGPoint(x: w * 0.91, y: h * 0.50), control2: CGPoint(x: w * 0.92, y: h * 0.73))
        p.addQuadCurve(to: CGPoint(x: w * 0.82, y: h), control: CGPoint(x: w * 0.92, y: h))
        p.addLine(to: CGPoint(x: w * 0.18, y: h)); p.addQuadCurve(to: CGPoint(x: w * 0.08, y: h * 0.88), control: CGPoint(x: w * 0.08, y: h))
        p.addCurve(to: CGPoint(x: w * 0.14, y: h * 0.35), control1: CGPoint(x: w * 0.08, y: h * 0.73), control2: CGPoint(x: w * 0.09, y: h * 0.50))
        p.addCurve(to: CGPoint(x: w * 0.36, y: h * 0.22), control1: CGPoint(x: w * 0.17, y: h * 0.29), control2: CGPoint(x: w * 0.35, y: h * 0.29))
        p.closeSubpath(); return p
    }
}

private struct CorkPiece: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0xC59A6C), Color(hex: 0xA9784E)], startPoint: .leading, endPoint: .trailing))
            .overlay(VStack(spacing: 7) { ForEach(0..<3, id: \.self) { _ in Capsule().fill(EunoiaColor.wood.opacity(0.17)).frame(width: 20, height: 1) } })
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(EunoiaColor.wood.opacity(0.22)))
            .shadow(color: EunoiaColor.deepOcean.opacity(0.18), radius: 4, y: 4)
    }
}

private struct RolledPaper: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 7).fill(LinearGradient(colors: [Color(hex: 0xFFF9E9), Color(hex: 0xF1E3C5)], startPoint: .leading, endPoint: .trailing))
            .overlay(HStack { Rectangle().fill(EunoiaColor.warmSand.opacity(0.34)).frame(width: 4); Spacer(); Rectangle().fill(EunoiaColor.warmSand.opacity(0.24)).frame(width: 3) }.clipShape(RoundedRectangle(cornerRadius: 7)))
    }
}

private struct FloatingLetter: View {
    let phase: BottleShelfView.Phase
    let letter: WebLetter
    let close: () -> Void

    private var open: Bool { phase == .openingLetter || phase == .opened || phase == .closing }
    private var contentVisible: Bool { phase == .opened || phase == .closing }
    private var closing: Bool { phase == .closing }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(colors: [Color(hex: 0xF8F0E4), Color(hex: 0xEDDEC8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 0) { ForEach(0..<15, id: \.self) { _ in Rectangle().fill(EunoiaColor.warmSand.opacity(0.055)).frame(height: 1); Spacer(minLength: 15) } }.padding(22)
            ScrollView {
                VStack(spacing: 18) {
                    Text("FOUND WASHED ASHORE").font(.system(size: 10, weight: .semibold)).tracking(2).opacity(contentVisible ? 0.56 : 0)
                    Text(letter.author).font(.title2).foregroundStyle(EunoiaColor.ink)
                        .accessibilityAddTraits(.isHeader).opacity(contentVisible ? 1 : 0)
                    Text(letter.text)
                        .font(.voyageBody()).lineSpacing(7).foregroundStyle(Color(hex: 0x3A2A1A))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(contentVisible ? 1 : 0)
                }.padding(.horizontal, 30).padding(.vertical, 38)
            }
            LinearGradient(colors: [Color(hex: 0xFFF7E4), Color(hex: 0xEAD8B9)], startPoint: .top, endPoint: .bottom)
                .frame(height: open ? 0 : 54)
                .overlay(alignment: .bottom) { Rectangle().fill(EunoiaColor.warmSand.opacity(0.22)).frame(height: 1) }
                .rotation3DEffect(.degrees(open ? -88 : 0), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.55)
                .opacity(phase == .opened || closing ? 0 : 1)
            Button(action: close) { Image(systemName: "xmark").font(.system(size: 15, weight: .medium)).frame(width: 44, height: 44).contentShape(Rectangle()) }
                .foregroundStyle(EunoiaColor.ink.opacity(0.65)).padding(8).opacity(phase == .opened ? 1 : 0).disabled(phase != .opened).accessibilityLabel("Close letter")
        }
        .frame(width: open ? nil : 76, height: open ? nil : 166)
        .clipShape(RoundedRectangle(cornerRadius: open ? 17 : 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: open ? 17 : 8).stroke(EunoiaColor.warmSand.opacity(0.38)))
        .shadow(color: EunoiaColor.deepOcean.opacity(open ? 0.14 : 0.02), radius: open ? 28 : 3, y: open ? 18 : 2)
        .rotationEffect(.degrees(open ? 0 : 2))
        .scaleEffect(closing ? 0.985 : phase == .openingLetter ? 1.08 : phase == .opened ? 1 : 1)
        .offset(y: closing ? 8 : 0)
        .opacity(closing ? 0 : 1)
        .accessibilityElement(children: phase == .opened ? .contain : .ignore)
    }
}

struct CaptainLogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LogEntry.createdAt, order: .reverse) private var entries: [LogEntry]
    @State private var difficult = ""; @State private var helped = ""; @State private var proud = ""
    @State private var savedMessage = false
    var body: some View {
        ZStack { StorybookBackground(); ScrollView { LazyVStack(alignment: .leading, spacing: 26) {
            HStack { EunoiaBackButton(); Spacer() }
            Text("Captain’s Log").font(.eunoiaScreenTitle).foregroundStyle(EunoiaColor.primaryText)
            HStack { Image(systemName: "safari.fill"); Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())) }.font(.system(size: 13, weight: .semibold)).foregroundStyle(EunoiaColor.gold).textCase(.uppercase)
            Text("Everything here is optional and stays on this device.").font(.system(size: 16)).foregroundStyle(EunoiaColor.secondaryText)
            reflectionField("Something that felt difficult today", text: $difficult)
            reflectionField("Something that helped", text: $helped)
            reflectionField("Something I’m proud of", text: $proud)
            Button("Save today’s reflection") { guard !difficult.isEmpty || !helped.isEmpty || !proud.isEmpty else { return }; context.insert(LogEntry(difficult: difficult, helped: helped, proud: proud)); difficult = ""; helped = ""; proud = ""; UINotificationFeedbackGenerator().notificationOccurred(.success); withAnimation(EunoiaMotion.collectible) { savedMessage = true }; Task { @MainActor in try? await Task.sleep(for: .seconds(2)); withAnimation { savedMessage = false } } }.buttonStyle(PrimaryButtonStyle())
            if savedMessage { Label("Log saved for today.", systemImage: "anchor.circle.fill").font(.system(size: 16, weight: .semibold)).foregroundStyle(EunoiaColor.gold).frame(maxWidth: .infinity).transition(.scale.combined(with: .opacity)) }
            if !entries.isEmpty { Text("Earlier pages").font(.eunoiaSectionTitle).padding(.top, 16) }
            ForEach(entries) { entry in SoftCard { VStack(alignment: .leading, spacing: 8) { Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted)).font(.caption.weight(.semibold)).foregroundStyle(EunoiaColor.gold); if !entry.difficult.isEmpty { Text(entry.difficult) }; if !entry.helped.isEmpty { Text(entry.helped) }; if !entry.proud.isEmpty { Text(entry.proud) } } } }
        }.eunoiaReadableContent().padding(.vertical, EunoiaSpacing.md) } }.toolbar(.hidden, for: .navigationBar)
    }
    private func reflectionField(_ title: String, text: Binding<String>) -> some View { VStack(alignment: .leading, spacing: 12) { Text(title).font(.system(size: 20, weight: .semibold)).foregroundStyle(EunoiaColor.primaryText); TextField("Write as little or as much as you like…", text: text, axis: .vertical).font(.system(size: 17)).lineLimit(4...7).padding(18).frame(minHeight: 138, alignment: .top).background(EunoiaColor.card.opacity(0.92), in: RoundedRectangle(cornerRadius: 21)).overlay(RoundedRectangle(cornerRadius: 21).stroke(EunoiaColor.warmSand.opacity(0.35))) } }
}

struct LighthouseView: View {
    var body: some View {
        ZStack { StorybookBackground(); ScrollView { LazyVStack(alignment: .leading, spacing: EunoiaSpacing.lg) {
            EunoiaBackButton()
            Text("Lighthouse").font(.eunoiaScreenTitle).foregroundStyle(EunoiaColor.primaryText)
            HStack { Spacer(); ZStack { Circle().fill(EunoiaColor.gold.opacity(0.14)).frame(width: 158, height: 158); Image(systemName: "light.beacon.max.fill").font(.system(size: 76)).foregroundStyle(EunoiaColor.gold, EunoiaColor.deepOcean) }; Spacer() }
            Text("You don’t have to navigate alone.").font(.story(32)).foregroundStyle(EunoiaColor.deepOcean).frame(maxWidth: 320, alignment: .leading)
            supportCard(title: "Find support", icon: "person.2.fill", emergency: false, body: "Consider reaching out to someone you trust, a family member, counselor, doctor, or an established eating-disorder support organization.")
            supportCard(title: "Need help now?", icon: "phone.fill", emergency: true, body: "If you may be in immediate danger or unable to keep yourself safe, contact your local emergency service now. Crisis resources vary by country.")
            Text("Eunoia is designed to support your journey, but it is not a substitute for professional medical or mental-health care.").font(.footnote).foregroundStyle(EunoiaColor.secondaryText).padding(.bottom, EunoiaSpacing.lg)
        }.eunoiaReadableContent().padding(.top, EunoiaSpacing.md) } }.toolbar(.hidden, for: .navigationBar)
    }
    private func supportCard(title: String, icon: String, emergency: Bool, body: String) -> some View { EunoiaCard(radius: 23, tint: EunoiaColor.card.opacity(0.78), padding: 21) { VStack(alignment: .leading, spacing: 12) { Label(title, systemImage: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(emergency ? Color.red : EunoiaColor.deepOcean); Text(body).font(.system(size: 16)).foregroundStyle(EunoiaColor.primaryText).lineSpacing(4) } } }
}
