import SwiftUI
import EventKit

// 主页面：读取日历、计算空闲、推荐放松任务
struct RelaxPlannerView: View {
    // MARK: - Calendar / Data
    private let eventStore = EKEventStore()
    @State private var todaysEvents: [EKEvent] = []
    @State private var freeIntervals: [DateInterval] = []
    @State private var suggestions: [RelaxSuggestion] = [
        RelaxSuggestion(type: .stretch5, title: "5分钟拉伸", subtitle: "活动关节，唤醒身体", durationMinutes: 5),
        RelaxSuggestion(type: .breathing1, title: "1分钟呼吸", subtitle: "跟随节奏深呼吸", durationMinutes: 1),
        RelaxSuggestion(type: .music2, title: "2分钟轻音乐", subtitle: "放松一下大脑", durationMinutes: 2)
    ]
    @State private var selectedIndex: Int = 0
    @State private var currentSuggestion: RelaxSuggestion? = nil
    @State private var weeklyStats: [DayStat] = DayStat.last7Days()

    // MARK: - UI State
    @State private var isLoading: Bool = false
    @State private var showSession: Bool = false

    private let nowProvider: () -> Date = { Date() }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            contentForCurrentTab
            .overlay(alignment: .bottom) { bottomTabPaddingSafe }
            .overlay(alignment: .topTrailing) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding()
                }
            }
        }
        .onAppear { loadToday(); weeklyStats = RelaxStatsStore.shared.last7DaysStats() }
        .sheet(isPresented: $showSession) {
            if let s = currentSuggestion {
                RelaxSessionContainer(type: s.type, suggestion: s) { mins in
                    addRelaxMinutes(mins)
                }
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(alignment: .center) {
            Text(formattedHeaderDate())
                .font(.largeTitle).bold()
                .foregroundColor(.white)
            Spacer()
            HStack(spacing: 10) {
                Circle().fill(Color.yellow.opacity(0.9)).frame(width: 10, height: 10)
                Circle().fill(Color.pink.opacity(0.9)).frame(width: 8, height: 8)
                Image(systemName: "person.crop.circle.fill").foregroundColor(.white.opacity(0.9)).font(.system(size: 24))
            }
        }
    }

    // 主内容：根据 Tab 切换
    @ViewBuilder private var contentForCurrentTab: some View {
        switch currentTab {
        case .home:
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    topBar
                    suggestionPager
                    timelineSection
                    chartSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
        case .bookmarks:
            BookmarksView()
        case .discover:
            DiscoverView()
        case .insights:
            InsightsPageView()
        case .profile:
            ProfilePageView()
        }
    }

    // MARK: - Suggestions Pager
    private var suggestionPager: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("放松方式")
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)

            TabView(selection: $selectedIndex) {
                ForEach(suggestions.indices, id: \.self) { idx in
                    suggestionCard(suggestions[idx], idx: idx)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 240)
        }
    }

    private func suggestionCard(_ s: RelaxSuggestion, idx: Int) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [Color(.sRGB, red: 0.18, green: 0.2, blue: 0.28, opacity: 1),
                                               Color(.sRGB, red: 0.08, green: 0.09, blue: 0.12, opacity: 1)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    ZStack {
                        ForEach(0..<12, id: \.self) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: CGFloat(Int.random(in: 22...48)), height: CGFloat(Int.random(in: 22...48)))
                                .offset(x: CGFloat(Int.random(in: -120...120)), y: CGFloat(Int.random(in: -40...20)))
                        }
                    }
                )

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(s.title)
                        .font(.title).bold()
                        .foregroundColor(.white)
                    if idx == recommendedIndex {
                        Text("推荐")
                            .font(.caption2).bold()
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.yellow)
                            .clipShape(Capsule())
                            .foregroundColor(.black)
                    }
                }
                Text(s.subtitle)
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: 10) {
                    Label("\(s.durationMinutes) min", systemImage: "clock")
                        .foregroundColor(.white.opacity(0.9))
                    if let until = nextFreeInterval()?.end {
                        Text("空档截至 \(timeOnly(until))")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.footnote)
                    }
                }
                Button {
                    currentSuggestion = s
                    showSession = true
                } label: {
                    Text("立即开始")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 6)
            }
            .padding(22)
        }
        .frame(height: 220)
        .padding(.horizontal, 2)
    }

    private var recommendedIndex: Int {
        let minutes = Int((nextFreeInterval()?.duration ?? 0) / 60)
        if minutes >= 5, let i = suggestions.firstIndex(where: { $0.type == .stretch5 }) { return i }
        if minutes >= 2, let i = suggestions.firstIndex(where: { $0.type == .music2 }) { return i }
        if minutes >= 1, let i = suggestions.firstIndex(where: { $0.type == .breathing1 }) { return i }
        return 0
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每天的放松时长")
                .font(.headline)
                .foregroundColor(.white)
            RelaxChartView(weeklyStats: weeklyStats)
                .frame(height: 140)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func addRelaxMinutes(_ minutes: Int) {
        RelaxStatsStore.shared.add(minutes: minutes)
        weeklyStats = RelaxStatsStore.shared.last7DaysStats()
    }

    // MARK: - Timeline Section
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("任务节奏表")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: loadToday) {
                    Image(systemName: "arrow.clockwise").foregroundColor(.white)
                }
            }

            // 时间线可视化（简化版）
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let segments = daySegments()
                HStack(spacing: 0) {
                    ForEach(segments.indices, id: \.self) { i in
                        let seg = segments[i]
                        Rectangle()
                            .fill(seg.isBusy ? Color.red.opacity(0.35) : Color.green.opacity(0.25))
                            .frame(width: max(1, totalWidth * CGFloat(seg.duration / (24 * 60 * 60))), height: 18)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .frame(height: 18)

            // 事件列表
            VStack(alignment: .leading, spacing: 10) {
                ForEach(displayItems(), id: \.id) { item in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(item.isBusy ? Color.red.opacity(0.25) : Color.green.opacity(0.25))
                            .frame(width: 8, height: 24)
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .foregroundColor(.white)
                            Text("\(timeOnly(item.interval.start)) - \(timeOnly(item.interval.end)) · \(Int(item.interval.duration / 60))m")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Bottom Tab (固定悬浮)
    private var bottomTabPaddingSafe: some View {
        VStack(spacing: 0) {
            bottomTab
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(
            Color.black.opacity(0.001) // 触发安全区
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var bottomTab: some View {
        HStack(spacing: 28) {
            tabButton("house.fill", tab: .home)
            tabButton("bookmark", tab: .bookmarks)
            tabButton("sparkles", tab: .discover)
            tabButton("chart.bar", tab: .insights)
            tabButton("person", tab: .profile)
        }
        .frame(height: 58)
        .padding(.horizontal, 18)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // Tab 枚举与选择
    private enum AppTab { case home, bookmarks, discover, insights, profile }
    @State private var currentTab: AppTab = .home

    private func tabButton(_ name: String, tab: AppTab) -> some View {
        Button(action: { currentTab = tab }) {
            Image(systemName: name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(currentTab == tab ? .white : .white.opacity(0.7))
                .frame(width: 44, height: 44)
                .background(currentTab == tab ? Color.white.opacity(0.12) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Data Loading
    private func loadToday() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: nowProvider())
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
            let events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }

            let free = computeFreeIntervals(events: events, in: DateInterval(start: nowProvider(), end: endOfDay))

            DispatchQueue.main.async {
                self.todaysEvents = events
                self.freeIntervals = free
                self.isLoading = false
                self.selectedIndex = self.recommendedIndex
            }
        }
    }

    private func computeFreeIntervals(events: [EKEvent], in window: DateInterval) -> [DateInterval] {
        var intervals: [DateInterval] = []
        var cursor = window.start
        for event in events where event.endDate > window.start && event.startDate < window.end {
            let start = max(event.startDate, window.start)
            if start > cursor {
                intervals.append(DateInterval(start: cursor, end: start))
            }
            cursor = max(cursor, min(event.endDate, window.end))
        }
        if cursor < window.end {
            intervals.append(DateInterval(start: cursor, end: window.end))
        }
        return intervals.filter { $0.duration >= 60 } // 至少 1 分钟
    }

    private func pickSuggestion(from free: [DateInterval]) -> RelaxSuggestion? {
        guard let next = nextFreeInterval(from: free) else { return nil }
        let minutes = Int(next.duration / 60)
        if minutes >= 5 { return RelaxSuggestion(type: .stretch5, title: "5分钟拉伸", subtitle: "活动关节，唤醒身体", durationMinutes: 5) }
        if minutes >= 2 { return RelaxSuggestion(type: .music2, title: "2分钟轻音乐", subtitle: "放松一下大脑", durationMinutes: 2) }
        if minutes >= 1 { return RelaxSuggestion(type: .breathing1, title: "1分钟呼吸", subtitle: "跟随节奏深呼吸", durationMinutes: 1) }
        return nil
    }

    private func nextFreeInterval(from list: [DateInterval]? = nil) -> DateInterval? {
        let source = list ?? freeIntervals
        let now = nowProvider()
        return source.first { $0.end > now }
    }

    // MARK: - Helpers for timeline
    private struct Segment { let duration: TimeInterval; let isBusy: Bool }
    private func daySegments() -> [Segment] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: nowProvider())
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        var segments: [Segment] = []

        var cursor = dayStart
        for e in todaysEvents.sorted(by: { $0.startDate < $1.startDate }) {
            if e.startDate > cursor { segments.append(Segment(duration: e.startDate.timeIntervalSince(cursor), isBusy: false)) }
            let busyEnd = min(e.endDate, dayEnd)
            if busyEnd > e.startDate { segments.append(Segment(duration: busyEnd.timeIntervalSince(e.startDate), isBusy: true)) }
            cursor = max(cursor, busyEnd)
        }
        if cursor < dayEnd { segments.append(Segment(duration: dayEnd.timeIntervalSince(cursor), isBusy: false)) }
        return segments
    }

    private struct DisplayItem { let id = UUID(); let title: String; let interval: DateInterval; let isBusy: Bool }
    private func displayItems() -> [DisplayItem] {
        var items: [DisplayItem] = todaysEvents.map { DisplayItem(title: $0.title.isEmpty ? "忙碌" : $0.title, interval: DateInterval(start: $0.startDate, end: $0.endDate), isBusy: true) }
        let free = freeIntervals.map { DisplayItem(title: "空闲", interval: $0, isBusy: false) }
        // 合并后按开始时间排序
        let all = items + free
        return all.sorted { $0.interval.start < $1.interval.start }
    }

    private func formattedHeaderDate() -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "EEEE" // Friday
        let weekday = df.string(from: nowProvider())
        return weekday
    }

    private func timeOnly(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: date)
    }
}

// MARK: - Stats & Chart
struct DayStat: Identifiable {
    let id = UUID()
    var date: Date
    var minutes: Int

    static func last7Days(from now: Date = Date()) -> [DayStat] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        return (0..<7).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: start)!
            return DayStat(date: d, minutes: 0)
        }
    }
}

struct RelaxChartView: View {
    let weeklyStats: [DayStat]

    var body: some View {
        GeometryReader { geo in
            let maxValue = max(5, weeklyStats.map { $0.minutes }.max() ?? 5)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(weeklyStats.indices, id: \.self) { idx in
                    let item = weeklyStats[idx]
                    VStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.5))
                            .frame(height: CGFloat(item.minutes) / CGFloat(maxValue) * (geo.size.height - 24))
                        Text(dayLabel(item.date))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "E"
        return df.string(from: date)
    }
}

// MARK: - Models
struct RelaxSuggestion {
    let type: RelaxType
    let title: String
    let subtitle: String
    let durationMinutes: Int
}

enum RelaxType { case stretch5, breathing1, music2 }

// MARK: - Session Container (参考图3)
private struct RelaxSessionContainer: View {
    let type: RelaxType
    let suggestion: RelaxSuggestion
    var onComplete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isRunning: Bool = true
    @State private var speed: Double = 1.0

    var body: some View {
        VStack(spacing: 16) {
            // 顶部标题区
            HStack {
                Text(sessionTitle())
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill").font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // 引导语
            Text(guideText())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // 中部动画/占位（参考图3大圆区域）
            Group {
                if type == .breathing1 {
                    BreathingCircle(durationSeconds: suggestion.durationMinutes * 60, speed: speed, isRunning: isRunning)
                } else if type == .stretch5 {
                    StretchHint(durationSeconds: suggestion.durationMinutes * 60)
                } else {
                    MusicRelax(durationSeconds: suggestion.durationMinutes * 60)
                }
            }
            .padding(.vertical, 8)

            // 速度滑杆（海龟/兔子）
            HStack {
                Image(systemName: "tortoise.fill").foregroundColor(.secondary)
                Slider(value: $speed, in: 0.5...1.8)
                Image(systemName: "hare.fill").foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // 底部操作按钮区域
            HStack(spacing: 12) {
                Button(action: { isRunning.toggle() }) {
                    Text(isRunning ? "暂停" : "继续")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button(action: { speed = 1.0 }) {
                    Text("重置")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button(action: { onComplete(suggestion.durationMinutes); dismiss() }) {
                    Text("完成")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func sessionTitle() -> String {
        switch type {
        case .breathing1: return "引导呼吸"
        case .stretch5: return "快速拉伸"
        case .music2: return "轻音乐"
        }
    }

    private func guideText() -> String {
        switch type {
        case .breathing1: return "吸气 4, 停留 2, 呼气 6，放松肩颈。"
        case .stretch5: return "跟随提示完成颈部、肩部与背部舒展。"
        case .music2: return "闭上眼睛，放松面部，专注音乐律动。"
        }
    }
}

// MARK: - Subviews for Sessions
struct BreathingCircle: View {
    let durationSeconds: Int
    let speed: Double
    let isRunning: Bool
    @State private var scale: CGFloat = 0.6

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 260, height: 260)
                Circle()
                    .fill(Color.blue.opacity(0.25))
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale)
                    .animation(isRunning ? .easeInOut(duration: max(1.5, 4 / speed)).repeatForever(autoreverses: true) : .default, value: scale)
            }
            .onAppear { scale = 1.0 }
            Text("跟随圆的节奏呼吸")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
}

private struct StretchHint: View {
    let durationSeconds: Int
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.cooldown")
                .font(.system(size: 120))
                .foregroundColor(.blue)
            Text("颈部转动、耸肩、胸椎展开各 20 秒")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
    }
}

private struct MusicRelax: View {
    let durationSeconds: Int
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "music.quarternote.3")
                .font(.system(size: 120))
                .foregroundColor(.purple)
            Text("想象海边微风，放空两分钟")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
    }
}

#Preview {
    RelaxPlannerView()
} 