import Foundation

enum WebDailyQuests {
    struct Quest {
        let id: String
        let title: String
        let xp: Int
    }

    struct Category: Identifiable {
        let id: String
        let title: String
        let symbol: String
        let accent: UInt
        var quests: [Quest]
    }

    static func categories(on date: Date) -> [Category] {
        let localDate = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = .gmt
        guard let midnight = utcCalendar.date(from: localDate) else { return [] }
        let day = Int(floor(midnight.timeIntervalSince1970 / 86_400))
        let round = Int(floor(Double(day) / 3))
        let position = day - round * 3

        return pool.map { category in
            var order = shuffled(category.quests, seed: "\(round):\(category.id)")
            let previous = shuffled(category.quests, seed: "\(round - 1):\(category.id)")
            let previousLast = Set(previous.suffix(3).map(\.id))
            for index in 0..<3 where previousLast.contains(order[index].id) {
                if let swap = (3..<6).first(where: { !previousLast.contains(order[$0].id) }) {
                    order.swapAt(index, swap)
                }
            }
            var today = category
            today.quests = Array(order[(position * 3)..<(position * 3 + 3)])
            return today
        }
    }

    private static func shuffled(_ quests: [Quest], seed: String) -> [Quest] {
        var state = seed.utf16.reduce(UInt32(2_166_136_261)) { ($0 ^ UInt32($1)) &* 16_777_619 }
        var result = quests
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            state = state &+ 0x6D2B79F5
            var value = (state ^ (state >> 15)) &* (1 | state)
            value = (value &+ ((value ^ (value >> 7)) &* (61 | value))) ^ value
            let random = Double(value ^ (value >> 14)) / 4_294_967_296
            result.swapAt(index, Int(random * Double(index + 1)))
        }
        return result
    }

    static let xpByTitle = Dictionary(uniqueKeysWithValues: pool.flatMap(\.quests).map { ($0.title, $0.xp) })

    static func totalXP(for records: [DailyQuest]) -> Int {
        records.filter(\.isCompleted).reduce(0) { $0 + (xpByTitle[$1.title] ?? 0) }
    }

    static func rank(for xp: Int) -> String {
        switch xp {
        case ..<50: "Deckhand"
        case ..<110: "First Mate"
        case ..<175: "Navigator"
        default: "Captain"
        }
    }

    private static let pool: [Category] = [
        .init(id: "anchor", title: "Anchor Points", symbol: "anchor", accent: 0x7A9AB0, quests: [
            .init(id: "a1", title: "Write 3 things your body did for you today", xp: 20),
            .init(id: "a2", title: "Take 5 slow, deep breaths with your eyes closed", xp: 10),
            .init(id: "a3", title: "Name one emotion you're feeling right now, without judgment", xp: 15),
            .init(id: "a4", title: "Try the 5-4-3-2-1 trick: notice 5 things you see, 4 you can touch, 3 you hear", xp: 15),
            .init(id: "a5", title: "Write down one thing you're proud of from this week", xp: 15),
            .init(id: "a6", title: "Say one kind thing to yourself, out loud or in your head", xp: 15),
            .init(id: "a7", title: "Put a hand on your heart and breathe slowly for one minute", xp: 10),
            .init(id: "a8", title: "Write down one thing you're grateful for today", xp: 10),
            .init(id: "a9", title: "Journal for five minutes about anything on your mind", xp: 20),
        ]),
        .init(id: "wave", title: "Wave Riders", symbol: "water.waves", accent: 0x6A8A9A, quests: [
            .init(id: "w1", title: "If it feels right, try a little gentle movement you enjoy.", xp: 25),
            .init(id: "w2", title: "Go outside and feel fresh air on your face", xp: 15),
            .init(id: "w3", title: "Listen to a song that lifts your spirits", xp: 10),
            .init(id: "w4", title: "Stretch gently for a few minutes, just because it feels good", xp: 15),
            .init(id: "w5", title: "Dance to one song in your room like nobody is watching", xp: 15),
            .init(id: "w6", title: "Do something creative: draw, doodle, write, or make something", xp: 20),
            .init(id: "w7", title: "Spend a few minutes with a pet, a plant, or somewhere green", xp: 15),
            .init(id: "w8", title: "Take a slow walk with no goal, just to notice what is around you", xp: 20),
            .init(id: "w9", title: "Rest on purpose: lie down for ten minutes with your phone away", xp: 15),
        ]),
        .init(id: "crew", title: "Crew Connection", symbol: "bubble.left", accent: 0x8A7A9A, quests: [
            .init(id: "c1", title: "Send one kind or honest message to someone you trust", xp: 20),
            .init(id: "c2", title: "Read a survivor letter from the message bottles", xp: 15),
            .init(id: "c3", title: "Share a thought with someone you feel safe talking to.", xp: 15),
            .init(id: "c4", title: "Tell someone you trust one real thing about your day", xp: 20),
            .init(id: "c5", title: "Message a friend just to say hi", xp: 15),
            .init(id: "c6", title: "Ask someone how they are really doing, and listen to the answer", xp: 20),
            .init(id: "c7", title: "Thank someone for something, big or small", xp: 20),
            .init(id: "c8", title: "Spend ten minutes with someone who makes you feel safe", xp: 20),
            .init(id: "c9", title: "Write a letter in a bottle for someone who is struggling", xp: 25),
        ]),
        .init(id: "nourish", title: "Nourishment Quest", symbol: "leaf", accent: 0x6A8A78, quests: [
            .init(id: "n1", title: "If it feels comfortable, have something to eat somewhere you can sit.", xp: 30),
            .init(id: "n2", title: "Pause for a drink of water when you feel ready.", xp: 15),
            .init(id: "n3", title: "If you feel curious, explore a food you haven’t tried before.", xp: 25),
            .init(id: "n4", title: "Eat a snack you enjoy, and let yourself enjoy it", xp: 20),
            .init(id: "n5", title: "Make space for something to eat after waking up.", xp: 25),
            .init(id: "n6", title: "Notice one thing you like about a food: its taste, smell or texture", xp: 15),
            .init(id: "n7", title: "Share a meal or snack with someone you feel safe around", xp: 30),
            .init(id: "n8", title: "Have a warm drink and enjoy it slowly", xp: 10),
            .init(id: "n9", title: "Think of a food you are looking forward to this week", xp: 15),
        ]),
    ]
}
