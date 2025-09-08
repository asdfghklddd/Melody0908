import SwiftUI

import Charts

import EventKit

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// 平台颜色封装
extension Color {
    static var platformSystemBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #else
        return Color(nsColor: NSColor.windowBackgroundColor)
        #endif
    }
    static var platformSecondaryBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray6)
        #else
        return Color(nsColor: NSColor.underPageBackgroundColor)
        #endif
    }
}

// 统一动效常量（P1）
struct Motion {
    static let componentSpring: Animation = .spring(response: 0.5, dampingFraction: 0.8)
    static let quickSpring: Animation = .spring(response: 0.3, dampingFraction: 0.8)
    static let opacityEase: Animation = .easeInOut(duration: 0.25)
}

// MARK: - 基础组件：卡片视图
struct ContentCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color.platformSystemBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 详情视图
struct MainView: View {
    
    // 用于管理视图状态的枚举
    enum RecommendationStatus: Equatable {
        case idle
        case loading
        case success(String)
        case failure(String)
    }
    
    // 使用 @State 变量来存储和管理状态
    @State private var recommendationStatus: RecommendationStatus = .idle
    // 今日日历事件区间
    @State private var eventIntervals: [DateInterval] = []
    // 今日日程列表
    @State private var todaysEvents: [EKEvent] = []
    // 智能推荐：推荐卡片索引与展示标记
    @State private var recommendedCardIndex: Int? = nil
    @State private var showAIRibbon: Bool = false
    // 新增：显示模式管理
    @State private var isInBreakMode: Bool = false
    @State private var breakRecommendation: String = ""
    @State private var breakTimer: Timer? = nil
    @State private var originalGreeting: String = ""
    @State private var originalSelectedCardIndex: Int = 2
    @State private var originalRecommendedCardIndex: Int? = nil
    @State private var originalShowAIRibbon: Bool = false
    @State private var scheduleCheckTimer: Timer? = nil
    @State private var greetingRefreshTimer: Timer? = nil
    @State private var lastGreetingRefresh: Date = Date()
    // 新增：卡片滑动相关状态
    @State private var selectedCardIndex: Int = 2 // 默认选中中间卡片
    @State private var dragOffset: CGFloat = 0
    @State private var knobRotation: Double = 0
    // 同步日历，获取今日英文星期
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
    
    // 新增：导航状态
    @State private var showBreathingSession = false
    @State private var showMusicSession = false
    @State private var showStretchSession = false
    @State private var showMeditationSession = false
    @State private var showBubbleSession = false
    @State private var showProfileView = false // 新增：个人资料页导航状态
    // 新增：AI问候语是否展开
    @State private var isGreetingExpanded: Bool = false
    // 新增：为会话动态传参的时长
    @State private var breathingDuration: Int = 5
    @State private var musicDuration: Int = 5
    // 底部区域整体上移距离（调整这里即可全局生效）
    private let bottomSectionLift: CGFloat = 60
    // 旋钮配色色卡（按提供的色值）
    private let knobPalette: [Color] = [
        Color(red: 1.0, green: 0.796, blue: 0.408),  // #ffcb68 橙黄
        Color(red: 0.968, green: 0.639, blue: 0.0),   // #f7a303 深橙
        Color(red: 0.819, green: 0.965, blue: 0.345), // #d1f658 柠檬绿
        Color(red: 0.847, green: 0.949, blue: 1.0),   // #d8f2ff 淡蓝
        Color(red: 0.984, green: 0.894, blue: 0.733)  // #fbe4bb 乳米色
    ]
    private var knobAccentColor: Color { knobPalette[selectedCardIndex % knobPalette.count] }
    
    // 新增：卡片数据结构 - 匹配设计图的5张彩色卡片
    let cardData = [
        (title: "深呼吸", color: Color.cyan, description: "放松呼吸", imageName: "card_breathing"),
        (title: "种子", color: Color.green, description: "专注冥想", imageName: "card_meditation"),
        (title: "音乐", color: Color.orange, description: "音乐疗愈", imageName: "card_music"),
        (title: "运动", color: Color.blue, description: "轻松运动", imageName: "card_stretch"),
        (title: "戳泡泡", color: Color.red, description: "充分休息", imageName: "card_bubble")
    ]
    
    @State private var greetingText: String = "晚上好，欢迎来到melody"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色 - 新的设计颜色 #FFF3D8
                Color(red: 1.0, green: 0.953, blue: 0.847)
                    .ignoresSafeArea(.all, edges: .all)
                
                VStack(spacing: 0) {
                    // 顶部区域 - 增加顶部间距
                    topHeaderView
                        .padding(.top, 100) // 向下移动40pt
                    
                    Spacer()
                    
                    // 中间彩色卡片扇形区域
                    fanCardsView
                    
                    Spacer()
                    
                    // 底部区域
                    bottomControlsView
                        .offset(y: -bottomSectionLift)
                    
                    // 页面底部日程展示
                    ScheduleBar(intervals: eventIntervals)
                        .frame(height: 24)
                        .padding(.top, 24)
                        .offset(y: -bottomSectionLift)
                    ScrollView(.vertical, showsIndicators: false) {
                        ForEach(todaysEvents, id: \.eventIdentifier) { ev in
                            HStack {
                                Text(ev.title ?? "(无标题)")
                                    .font(.subheadline)
                                Spacer()
                                Text(ev.startDate, style: .time)
                                Text("–")
                                Text(ev.endDate, style: .time)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.top, 10)
                    .frame(maxHeight: 120)
                    .background(Color.platformSecondaryBackground)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20) // 减少原本的顶部padding
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            #endif
            .onAppear {
                Task {
                    await fetchAndAnalyzeCalendar()
                    await loadTodayIntervals()
                    await loadTodayEvents()
                    await MainActor.run {
                        updateRecommendationUsingSchedule()
                    }
                }
                updateKnobRotation()
                
                // 启动定期检查定时器（每5分钟检查一次）
                scheduleCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
                    Task { @MainActor in
                        self.checkScheduleGapAndTriggerAI()
                    }
                }
                
                // 启动问候语刷新定时器（每30分钟刷新一次）
                greetingRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
                    Task { @MainActor in
                        if !self.isInBreakMode {
                            await self.refreshGreetingIfNeeded()
                        }
                    }
                }
            }
            .onDisappear {
                // 清理所有定时器
                scheduleCheckTimer?.invalidate()
                scheduleCheckTimer = nil
                greetingRefreshTimer?.invalidate()
                greetingRefreshTimer = nil
                breakTimer?.invalidate()
                breakTimer = nil
            }
            #if os(iOS)
            .navigationDestination(isPresented: $showProfileView) { // 新增：个人资料页导航
                ProfileView()
            }
            #endif
        }
    }
    
    // MARK: - 实际功能实现
    
    // 异步函数：获取日历事件并调用大模型API
    private func fetchAndAnalyzeCalendar() async {
        // 更新状态为加载中
        await MainActor.run {
            self.recommendationStatus = .loading
        }
        
        let eventStore = EKEventStore()
        
        do {
            // 请求日历权限
            let granted = try await eventStore.requestAccess(to: .event)
            
            guard granted else {
                // 权限被拒绝，更新状态并返回
                await MainActor.run {
                    self.recommendationStatus = .failure("未授予日历访问权限。请前往“设置”开启。")
                }
                return
            }
            
            // 权限已授予，获取今日日历事件
            let calendarContent = await getTodayCalendarEvents(eventStore: eventStore)
            
            if calendarContent.isEmpty {
                await MainActor.run {
                    let message = "今天日历没有安排，空闲时间很多哦！"
                    self.recommendationStatus = .success(message)
                    self.greetingText = message
                }
                return
            }
            
            // 先调用大模型 API 获取顶部问候
            do {
                let apiURLBase = "https://api-inference.modelscope.cn/v1/chat/completions"
                guard let baseURL = URL(string: apiURLBase) else { throw URLError(.badURL) }
                let modelName = "Qwen/Qwen3-Coder-480B-A35B-Instruct"
                let systemPrompt = "请你严格按照我的回复要求来执行回答，你会阅读用户日历里面的日程，然后作为一个专精高效工作方法和科学健康放松方法与时间管理的专家，来进行分析。但是请你不要输出你的分析过程，以最终只能输出8-20个字的短句，而且只能回复一句话，用鼓励性语气来鼓励用户或者是用户问你休息推荐的时候，给出推荐的放松方式以及理由。总之记住你回答的格式，每次8-20个字，鼓励性。你只有2种回答模式可以选择：【1】「当你收到“输出鼓励性话语”这个指令」：给出类似“每动一次，就离目标更近一点!加油，让我们一起慢慢变强大”这样的鼓励，注意是类似这样的鼓励，没让你只能回复这一句鼓励的话，每次都不一样，生动有趣。【2】「当你收到『分析日程推荐运动方式』你先获取分析当前时间，分析日历里获取的用户的日程信息，结合分析后给出推荐的运动方式和理由。你的回答必须在两种模式中选择一种，不能自说自话回答规定之外的内容。不能不遵守回答格式，回复一大堆话。以下是一个供你参考的模版范例：example：“刚才坐着办公了一个半小时很努力呢，现在melody推荐起来做3分钟拉伸，放松四肢，效率高高的！”"
                let userPrompt = "请分析如下日程：\n\(calendarContent)并给出一句话鼓励或运动推荐，8-20字，鼓励性，请严格遵守格式。"

                let tokens = readModelScopeTokens()
                guard !tokens.isEmpty else {
                    throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "未配置 MODELSCOPE_API_TOKEN 或 MODELSCOPE_API_TOKEN_2（Edit Scheme 或 Info.plist）"])
                }

                let payload: [String: Any] = [
                    "model": modelName,
                    "messages": [
                        ["role": "system", "content": systemPrompt],
                        ["role": "user", "content": userPrompt]
                    ],
                    "temperature": 0.7,
                    "max_tokens": 512,
                    "stream": false
                ]

                func buildRequest(url: URL) throws -> URLRequest {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.timeoutInterval = 30
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                    return request
                }

                var lastErrorDetail: String = ""
                var successText: String?
                let authModes = [0, 1]
                tokenLoop: for token in tokens {
                    let urlVariants: [URL] = [
                        baseURL,
                        URL(string: apiURLBase + "?token=\(token)")!
                    ]
                    for url in urlVariants {
                        for mode in authModes {
                            do {
                                var request = try buildRequest(url: url)
                                if mode == 0 {
                                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                                } else if mode == 1 {
                                    request.setValue(token, forHTTPHeaderField: "X-API-Key")
                                }
                                let (data, response) = try await URLSession.shared.data(for: request)
                                guard let http = response as? HTTPURLResponse else {
                                    throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效响应对象"])
                                }
                                if !(200...299).contains(http.statusCode) {
                                    let body = String(data: data, encoding: .utf8) ?? "<empty>"
                                    lastErrorDetail = "HTTP \(http.statusCode) @mode=\(mode) url=\(url.absoluteString) token_*\(token.suffix(6)) body=\(body.prefix(500))"
                                    continue
                                }
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                let text = ((json?["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any])?["content"] as? String
                                    ?? (json?["choices"] as? [[String: Any]])?.first?["text"] as? String
                                    ?? json?["output_text"] as? String
                                    ?? String(data: data, encoding: .utf8)
                                successText = text?.trimmingCharacters(in: .whitespacesAndNewlines)
                                break tokenLoop
                            } catch {
                                lastErrorDetail = error.localizedDescription
                                continue
                            }
                        }
                    }
                }

                guard let result = successText, !result.isEmpty else {
                    throw NSError(domain: "API", code: 401, userInfo: [NSLocalizedDescriptionKey: lastErrorDetail.isEmpty ? "鉴权失败或响应为空" : lastErrorDetail])
                }

                await MainActor.run {
                    self.recommendationStatus = .success(result)
                    self.greetingText = result
                    self.lastGreetingRefresh = Date() // 记录问候语刷新时间
                }
            } catch {
                let msg = "分析失败：\(error.localizedDescription)"
                await MainActor.run {
                    self.recommendationStatus = .failure(msg)
                    self.greetingText = msg
                }
            }
            // 调用模型获取推荐卡片
            await requestRecommendedCardIndex(from: calendarContent)
            return
            
        } catch {
            await MainActor.run {
                self.recommendationStatus = .failure("日历访问出错：\(error.localizedDescription)")
            }
        }
    }
    
    // 异步函数：获取今日日历事件并格式化为字符串
    private func getTodayCalendarEvents(eventStore: EKEventStore) async -> String {
        let today = Date()
        let calendar = Calendar.current
        
        // 设置时间范围为今天
        let startDate = calendar.startOfDay(for: today)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        let calendars = eventStore.calendars(for: .event)
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        
        let events = eventStore.events(matching: predicate)
        
        // 格式化日历内容
        var calendarString = "今天：\(today.formatted(.dateTime.month().day()))\n\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        for event in events {
            let startTime = formatter.string(from: event.startDate)
            let endTime = formatter.string(from: event.endDate)
            calendarString += "\(startTime) - \(endTime): \(event.title ?? "无标题事件")\n"
        }
        
        return calendarString
    }

    // 读取 ModelScope Tokens（支持多个），按优先级：环境变量1、环境变量2、Info.plist 1、Info.plist 2
    private func readModelScopeTokens() -> [String] {
        let env1 = (ProcessInfo.processInfo.environment["MODELSCOPE_API_TOKEN"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let env2 = (ProcessInfo.processInfo.environment["MODELSCOPE_API_TOKEN_2"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let info1 = ((Bundle.main.object(forInfoDictionaryKey: "MODELSCOPE_API_TOKEN") as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let info2 = ((Bundle.main.object(forInfoDictionaryKey: "MODELSCOPE_API_TOKEN_2") as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let placeholder = "ms-ee852714-14b8-4fab-8874-cfdf88c9428a"
        let raw = [env1, env2, info1, info2]
        var seen = Set<String>()
        var tokens: [String] = []
        for token in raw {
            if !token.isEmpty && token != placeholder && !seen.contains(token) {
                seen.insert(token)
                tokens.append(token)
            }
        }
        return tokens
    }
    
    // 异步函数：实际调用 ModelScope API
    private func callModelScopeAPI(with calendarContent: String) async {
        let tokens = readModelScopeTokens()
        if tokens.isEmpty {
            await callSiliconFlowAPI(with: calendarContent)
            return
        }
        let modelId = "Qwen/Qwen3-32B"
        enum AuthMode: String { case bearer = "Authorization: Bearer", xApiKey = "X-API-Key", xToken = "X-Token", none = "No-Auth" }
        let authModes: [AuthMode] = [.bearer, .xApiKey, .xToken, .none]
        
        // --- 请求体集合 ---
        let openAIChatBody: [String: Any] = [
            "model": modelId,
            "messages": [
                ["role": "system", "content": "请你严格按照我的回复要求来执行回答，你会阅读用户日历里面的日程，然后作为一个专精高效工作方法和科学健康放松方法与时间管理的专家，来进行分析。但是请你不要输出你的分析过程，以最终只能输出8-20个字的短句，而且只能回复一句话，用鼓励性语气来鼓励用户或者是用户问你休息推荐的时候，给出推荐的放松方式以及理由。总之记住你回答的格式，每次8-20个字，鼓励性。你只有2种回答模式可以选择：【1】「当你收到“输出鼓励性话语”这个指令」：给出类似“每动一次，就离目标更近一点!加油，让我们一起慢慢变强大”这样的鼓励，注意是类似这样的鼓励，没让你只能回复这一句鼓励的话，每次都不一样，生动有趣。【2】「当你收到『分析日程推荐运动方式』你先获取分析当前时间，分析日历里获取的用户的日程信息，结合分析后给出推荐的运动方式和理由。你的回答必须在两种模式中选择一种，不能自说自话回答规定之外的内容。不能不遵守回答格式，回复一大堆话。以下是一个供你参考的模版范例：example：“刚才坐着办公了一个半小时很努力呢，现在melody推荐起来做3分钟拉伸，放松四肢，效率高高的！”"],
                ["role": "user", "content": "请分析如下日程：\n\(calendarContent)并给出一句话鼓励或运动推荐，8-20字，鼓励性，请严格遵守格式。" ]
            ],
            "stream": false
        ]
        
        let legacyMessagesBody: [String: Any] = [
            "input": [
                "messages": [
                    ["role": "system", "content": "请你严格按照我的回复要求来执行回答，你会阅读用户日历里面的日程，然后作为一个专精高效工作方法和科学健康放松方法与时间管理的专家，来进行分析。但是请你不要输出你的分析过程，以最终只能输出8-20个字的短句，而且只能回复一句话，用鼓励性语气来鼓励用户或者是用户问你休息推荐的时候，给出推荐的放松方式以及理由。总之记住你回答的格式，每次8-20个字，鼓励性。你只有2种回答模式可以选择：【1】「当你收到“输出鼓励性话语”这个指令」：给出类似“每动一次，就离目标更近一点!加油，让我们一起慢慢变强大”这样的鼓励，注意是类似这样的鼓励，没让你只能回复这一句鼓励的话，每次都不一样，生动有趣。【2】「当你收到『分析日程推荐运动方式』你先获取分析当前时间，分析日历里获取的用户的日程信息，结合分析后给出推荐的运动方式和理由。你的回答必须在两种模式中选择一种，不能自说自话回答规定之外的内容。不能不遵守回答格式，回复一大堆话。以下是一个供你参考的模版范例：example：“刚才坐着办公了一个半小时很努力呢，现在melody推荐起来做3分钟拉伸，放松四肢，效率高高的！”"] ,
                    ["role": "user", "content": "请分析如下日程：\n\(calendarContent)并给出一句话鼓励或运动推荐，8-20字，鼓励性，请严格遵守格式。" ]
                ]
            ],
            "parameters": ["result_format": "message"]
        ]
        
        let plainInputPrompt = "请你严格按照我的回复要求来执行回答，你会阅读用户日历里面的日程，然后作为一个专精高效工作方法和科学健康放松方法与时间管理的专家，来进行分析。但是请你不要输出你的分析过程，以最终只能输出8-20个字的短句，而且只能回复一句话，用鼓励性语气来鼓励用户或者是用户问你休息推荐的时候，给出推荐的放松方式以及理由。总之记住你回答的格式，每次8-20个字，鼓励性。你只有2种回答模式可以选择：【1】「当你收到“输出鼓励性话语”这个指令」：给出类似“每动一次，就离目标更近一点!加油，让我们一起慢慢变强大”这样的鼓励，注意是类似这样的鼓励，没让你只能回复这一句鼓励的话，每次都不一样，生动有趣。【2】「当你收到『分析日程推荐运动方式』你先获取分析当前时间，分析日历里获取的用户的日程信息，结合分析后给出推荐的运动方式和理由。你的回答必须在两种模式中选择一种，不能自说自话回答规定之外的内容。不能不遵守回答格式，回复一大堆话。以下是一个供你参考的模版范例：example：“刚才坐着办公了一个半小时很努力呢，现在melody推荐起来做3分钟拉伸，放松四肢，效率高高的！”\n\n\(calendarContent)并给出一句话鼓励或运动推荐，8-20字，鼓励性，请严格遵守格式。"
        let legacyPlainInputBody: [String: Any] = [
            "input": plainInputPrompt,
            "parameters": [:]
        ]
        
        func sendRequest(urlString: String, body: [String: Any], authMode: AuthMode, token: String, maxRetries: Int = 2) async throws -> (String, HTTPURLResponse, Data) {
            guard let apiUrl = URL(string: urlString) else {
                throw NSError(domain: "URLError", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL 无效: \(urlString)"])
            }
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            var request = URLRequest(url: apiUrl)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            switch authMode {
            case .bearer:
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            case .xApiKey:
                request.setValue(token, forHTTPHeaderField: "X-API-Key")
            case .xToken:
                request.setValue(token, forHTTPHeaderField: "X-Token")
            case .none:
                break
            }
            request.httpBody = jsonData
            
            var lastError: Error?
            var attempt = 0
            while attempt <= maxRetries {
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NSError(domain: "HTTPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的响应对象"])
                    }
                    return (urlString, httpResponse, data)
                } catch {
                    lastError = error
                    if attempt < maxRetries {
                        let delay = pow(2.0, Double(attempt)) * 0.6
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
                attempt += 1
            }
            throw lastError ?? NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知网络错误"])
        }
        
        func extractText(from data: Data) -> String? {
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return nil
            }
            if let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            }
            if let output = json["output"] as? [String: Any],
               let choices = output["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            }
            if let output = json["output"] as? [String: Any], let text = output["text"] as? String { return text }
            if let text = json["text"] as? String { return text }
            if let text = json["output_text"] as? String { return text }
            if let message = json["message"] as? String { return message }
            return nil
        }
        
        let bodies: [[String: Any]] = [openAIChatBody, legacyMessagesBody, legacyPlainInputBody]
        var failureDetails: [String] = []
        
        for token in tokens {
            let tokenSuffix = String(token.suffix(6))
            let endpointVariants: [String] = [
                "https://api-inference.modelscope.cn/v1/chat/completions",
                "https://api-inference.modelscope.cn/v1/chat/completions?token=\(token)",
                "https://api-inference.modelscope.cn/api-inference/v1/models/\(modelId)",
                "https://api-inference.modelscope.cn/api-inference/v1/models/\(modelId)?token=\(token)"
            ]
            for (bIndex, body) in bodies.enumerated() {
                for url in endpointVariants {
                    for auth in authModes {
                        do {
                            let (target, httpResponse, data) = try await sendRequest(urlString: url, body: body, authMode: auth, token: token)
                            if httpResponse.statusCode != 200 {
                                let status = httpResponse.statusCode
                                let errorData = String(data: data, encoding: .utf8) ?? "<无法解析错误信息>"
                                let snippet = errorData.prefix(800)
                                let reason = "[B\(bIndex+1) \(auth.rawValue) @ \(target) token_*\(tokenSuffix)] HTTP \(status): \(snippet)"
                                print("API请求失败: \(reason)")
                                failureDetails.append(reason)
                                continue
                            }
                            if let textOutput = extractText(from: data), !textOutput.isEmpty {
                                await MainActor.run {
                                    self.recommendationStatus = .success(textOutput)
                                    self.greetingText = textOutput
                                }
                                return
                            } else {
                                let responseString = String(data: data, encoding: .utf8) ?? "<无法解析响应>"
                                let snippet = responseString.prefix(800)
                                let reason = "[B\(bIndex+1) \(auth.rawValue) @ \(target) token_*\(tokenSuffix)] 解析失败，原始响应: \(snippet)"
                                print(reason)
                                failureDetails.append(reason)
                                continue
                            }
                        } catch {
                            let reason = "[B\(bIndex+1) \(auth.rawValue) @ \(url) token_*\(tokenSuffix)] 异常: \(error.localizedDescription)"
                            print(reason)
                            failureDetails.append(reason)
                            continue
                        }
                    }
                }
            }
        }
        
        let message = failureDetails.isEmpty ? "API 调用失败：请检查 Token、模型权限与请求体格式。" : "API 调用失败详情：\n" + failureDetails.joined(separator: "\n——\n")
        await MainActor.run {
            self.recommendationStatus = .failure(message)
        }
    }
    
    // 新增：SiliconFlow API 调用（免费的Qwen模型）
    private func callSiliconFlowAPI(with calendarContent: String) async {
        let apiUrl = URL(string: "https://api.siliconflow.cn/v1/chat/completions")!

        // 改为从环境变量或 Info.plist 读取，避免硬编码
        let envTokenRaw = ProcessInfo.processInfo.environment["SILICONFLOW_API_TOKEN"] ?? ""
        let infoTokenRaw = (Bundle.main.object(forInfoDictionaryKey: "SILICONFLOW_API_TOKEN") as? String) ?? ""
        let siliconToken = envTokenRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? infoTokenRaw.trimmingCharacters(in: .whitespacesAndNewlines) : envTokenRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !siliconToken.isEmpty else {
            await MainActor.run {
                self.recommendationStatus = .failure("未配置 SILICONFLOW_API_TOKEN（Edit Scheme 或 Info.plist）")
            }
            return
        }
        
        let systemPrompt = """
        你是一位温暖贴心的生活助手。用户会提供他们的日程安排，
        请根据日程内容，以轻松友好的语气提供3条贴心的建议或提醒。
        每条建议都要具体、实用、温暖，让用户感到被关心。
        请用简洁的语言，每条建议不超过30字。
        """
        
        let requestBody: [String: Any] = [
            "model": "Qwen/Qwen2.5-7B-Instruct",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "我的日程安排：\n\(calendarContent)"]
            ],
            "temperature": 0.7,
            "max_tokens": 300,
            "stream": false
        ]
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(siliconToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("SiliconFlow API 响应状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw NSError(domain: "API", code: httpResponse.statusCode,
                                 userInfo: [NSLocalizedDescriptionKey: errorMsg])
                }
            }
            
            // 解析响应
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                await MainActor.run {
                    self.recommendationStatus = .success(content)
                    self.greetingText = content
                    self.lastGreetingRefresh = Date() // 记录问候语刷新时间
                }
            } else {
                throw NSError(domain: "API", code: -1,
                                 userInfo: [NSLocalizedDescriptionKey: "响应格式错误"])
            }
            
        } catch {
            await MainActor.run {
                self.recommendationStatus = .failure("API调用失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 获取今日日历事件区间
    private func loadTodayIntervals() async {
        let store = EKEventStore()
        do {
            let granted = try await store.requestAccess(to: .event)
            guard granted else { return }
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: Date())
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: store.calendars(for: .event))
            let events = store.events(matching: predicate)
            eventIntervals = events.map { DateInterval(start: $0.startDate, duration: $0.endDate.timeIntervalSince($0.startDate)) }
        } catch {
            // ignore
            eventIntervals = []
        }
    }
    
    // 读取今日日程到 todaysEvents
    private func loadTodayEvents() async {
        let store = EKEventStore()
        do {
            let granted = try await store.requestAccess(to: .event)
            guard granted else { return }
            let cal = Calendar.current
            let start = cal.startOfDay(for: Date())
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            let pred = store.predicateForEvents(withStart: start, end: end, calendars: store.calendars(for: .event))
            let evs = store.events(matching: pred).sorted { $0.startDate < $1.startDate }
            await MainActor.run {
                todaysEvents = evs
                updateRecommendationUsingSchedule()
            }
        } catch { }

    }
    
    // 基于今日日程与当前时间计算推荐的放松方式，并置中卡片
    private func updateRecommendationUsingSchedule() {
        let now = Date()
        // 检测是否处于日程间隙
        checkScheduleGapAndTriggerAI()
        
        // 如果已经有AI推荐，则不使用本地时间推荐逻辑，避免覆盖AI推荐
        if recommendedCardIndex != nil && showAIRibbon {
            print("已有AI推荐，跳过本地时间推荐逻辑")
            return
        }
        
        // 计算距离下一个事件开始的可用分钟数（若无，则视为充裕）
        let nextEvent = todaysEvents.first { $0.startDate > now }
        let availableMinutes: Int = {
            if let next = nextEvent { return max(0, Int(next.startDate.timeIntervalSince(now) / 60.0)) }
            return 60 // 没有后续事件，默认充裕
        }()
        // 如果当前正在事件中，也按短时休息处理
        let inEvent = todaysEvents.contains { $0.startDate <= now && now < $0.endDate }
        let minutes = inEvent ? min(availableMinutes, 5) : availableMinutes

        // 根据可用时长选择推荐卡片（仅作为备用推荐）
        // 0: 深呼吸, 1: 种子(冥想), 2: 音乐, 3: 运动, 4: 戳泡泡
        let index: Int
        switch minutes {
        case 20...: index = 3        // 有20+分钟 -> 运动
        case 10..<20: index = 2      // 10-20分钟 -> 音乐
        case 5..<10: index = 1       // 5-10分钟 -> 冥想
        case 2..<5: index = 4        // 2-5分钟 -> 戳泡泡
        default: index = 0           // <2分钟 -> 深呼吸
        }

        recommendedCardIndex = index
        showAIRibbon = false // 本地推荐不显示AI标签

        if selectedCardIndex != index {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedCardIndex = index
                updateKnobRotation()
            }
        }
    }
    
    // 新增：检测日程间隙并触发AI推荐
    private func checkScheduleGapAndTriggerAI() {
        let now = Date()
        
        // 检查当前是否在事件中（专注时间）
        let currentlyInEvent = todaysEvents.contains { event in
            now >= event.startDate && now < event.endDate
        }
        
        // 如果当前在事件中（专注时间），确保显示问候语
        if currentlyInEvent {
            if isInBreakMode {
                // 从休息模式切换回专注模式
                exitBreakMode()
            }
            return
        }
        
        // 如果已经在休息模式，不重复触发
        if isInBreakMode {
            return
        }
        
        // 查找最近结束的事件（1小时内结束的）
        let recentlyEndedEvent = todaysEvents
            .filter { event in
                let timeSinceEnd = now.timeIntervalSince(event.endDate)
                return timeSinceEnd > 0 && timeSinceEnd <= 3600 // 1小时内结束
            }
            .sorted { $0.endDate > $1.endDate } // 按结束时间倒序
            .first
        
        // 查找下一个即将开始的事件
        let upcomingEvent = todaysEvents
            .filter { event in
                let timeToStart = event.startDate.timeIntervalSince(now)
                return timeToStart > 0 && timeToStart <= 7200 // 2小时内开始
            }
            .sorted { $0.startDate < $1.startDate } // 按开始时间正序
            .first
        
        // 检查是否处于休息间隙
        if let recentEvent = recentlyEndedEvent,
           let nextEvent = upcomingEvent {
            
            let timeSinceLastEnd = Int(now.timeIntervalSince(recentEvent.endDate) / 60)
            let timeToNextStart = Int(nextEvent.startDate.timeIntervalSince(now) / 60)
            
            // 触发休息建议的条件：
            // 1. 距离上个事件结束至少5分钟（给用户整理时间）
            // 2. 距离下个事件开始还有至少15分钟（确保有足够放松时间）
            // 3. 总间隙时间至少25分钟
            let totalGap = timeSinceLastEnd + timeToNextStart
            
            if timeSinceLastEnd >= 5 && timeToNextStart >= 15 && totalGap >= 25 {
                print("检测到休息间隙：上个事件\(timeSinceLastEnd)分钟前结束，下个事件\(timeToNextStart)分钟后开始")
                triggerBreakModeWithAI(gapDuration: timeToNextStart)
            }
        }
    }
    
    // 新增：触发休息模式并调用AI
    private func triggerBreakModeWithAI(gapDuration: Int) {
        Task {
            // 保存原始问候语
            originalGreeting = greetingText
            
            // 构建日历内容用于AI分析
            let calendarContent = await getTodayCalendarEvents(eventStore: EKEventStore())
            
            // 调用AI获取放松建议
            await callAIForBreakRecommendation(calendarContent: calendarContent, gapMinutes: gapDuration)
        }
    }
    
    // 新增：专门用于休息建议的AI调用
    private func callAIForBreakRecommendation(calendarContent: String, gapMinutes: Int) async {
        let tokens = readModelScopeTokens()
        if tokens.isEmpty {
            await callSiliconFlowForBreakRecommendation(calendarContent: calendarContent, gapMinutes: gapMinutes)
        } else {
            await callModelScopeForBreakRecommendation(calendarContent: calendarContent, gapMinutes: gapMinutes, tokens: tokens)
        }
    }
    
    // 新增：ModelScope API调用休息建议
    private func callModelScopeForBreakRecommendation(calendarContent: String, gapMinutes: Int, tokens: [String]) async {
        guard let url = URL(string: "https://api-inference.modelscope.cn/v1/chat/completions") else { return }
        let systemPrompt = "请你严格按照我的回复要求来执行回答，你会阅读用户日历里面的日程，然后作为一个专精高效工作方法和科学健康放松方法与时间管理的专家，来进行分析。但是请你不要输出你的分析过程，以最终只能输出8-20个字的短句，而且只能回复一句话，用鼓励性语气来鼓励用户或者是用户问你休息推荐的时候，给出推荐的放松方式以及理由。总之记住你回答的格式，每次8-20个字，鼓励性。你只有2种回答模式可以选择：【1】「当你收到\"输出鼓励性话语\"这个指令」：给出类似\"每动一次，就离目标更近一点!加油，让我们一起慢慢变强大\"这样的鼓励，注意是类似这样的鼓励，没让你只能回复这一句鼓励的话，每次都不一样，生动有趣。【2】「当你收到『分析日程推荐运动方式』你先获取分析当前时间，分析日历里获取的用户的日程信息，结合分析后给出推荐的运动方式和理由。你的回答必须在两种模式中选择一种，不能自说自话回答规定之外的内容。不能不遵守回答格式，回复一大堆话。以下是一个供你参考的模版范例：example：\"刚才坐着办公了一个半小时很努力呢，现在melody推荐起来做3分钟拉伸，放松四肢，效率高高的！\""
        let userPrompt = "分析日程推荐运动方式。当前你有\(gapMinutes)分钟的休息时间，日程：\n\(calendarContent)"
        let payload: [String: Any] = [
            "model": "Qwen/Qwen3-Coder-480B-A35B-Instruct",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 512,
            "stream": false
        ]
        for token in tokens {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    await MainActor.run {
                        enterBreakMode(with: content, duration: gapMinutes)
                    }
                    return
                }
            } catch {
                print("ModelScope休息建议调用失败: token_*\(token.suffix(6)) error: \(error)")
                continue
            }
        }
    }
    
    // 新增：SiliconFlow API调用休息建议
    private func callSiliconFlowForBreakRecommendation(calendarContent: String, gapMinutes: Int) async {
        guard let url = URL(string: "https://api.siliconflow.cn/v1/chat/completions") else { return }

        // 改为从环境变量或 Info.plist 读取，避免硬编码
        let envTokenRaw = ProcessInfo.processInfo.environment["SILICONFLOW_API_TOKEN"] ?? ""
        let infoTokenRaw = (Bundle.main.object(forInfoDictionaryKey: "SILICONFLOW_API_TOKEN") as? String) ?? ""
        let siliconToken = envTokenRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? infoTokenRaw.trimmingCharacters(in: .whitespacesAndNewlines) : envTokenRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !siliconToken.isEmpty else { return }
        let systemPrompt = "请你严格按照我的回复要求来执行回答，你会阅读用户日历里面的日程，然后作为一个专精高效工作方法和科学健康放松方法与时间管理的专家，来进行分析。但是请你不要输出你的分析过程，以最终只能输出8-20个字的短句，而且只能回复一句话，用鼓励性语气来鼓励用户或者是用户问你休息推荐的时候，给出推荐的放松方式以及理由。总之记住你回答的格式，每次8-20个字，鼓励性。你只有2种回答模式可以选择：【1】「当你收到\"输出鼓励性话语\"这个指令」：给出类似\"每动一次，就离目标更近一点!加油，让我们一起慢慢变强大\"这样的鼓励，注意是类似这样的鼓励，没让你只能回复这一句鼓励的话，每次都不一样，生动有趣。【2】「当你收到『分析日程推荐运动方式』你先获取分析当前时间，分析日历里获取的用户的日程信息，结合分析后给出推荐的运动方式和理由。你的回答必须在两种模式中选择一种，不能自说自话回答规定之外的内容。不能不遵守回答格式，回复一大堆话。以下是一个供你参考的模版范例：example：\"刚才坐着办公了一个半小时很努力呢，现在melody推荐起来做3分钟拉伸，放松四肢，效率高高的！\""
        
        let userPrompt = "分析日程推荐运动方式。当前你有\(gapMinutes)分钟的休息时间，日程：\n\(calendarContent)"
        
        let payload: [String: Any] = [
            "model": "Qwen/Qwen2.5-7B-Instruct",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 300,
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(siliconToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                await MainActor.run {
                    enterBreakMode(with: content, duration: gapMinutes)
                }
            }
        } catch {
            print("SiliconFlow休息建议调用失败: \(error)")
        }
    }
    
    // 新增：进入休息模式
    private func enterBreakMode(with recommendation: String, duration: Int) {
        if !isInBreakMode {
            originalSelectedCardIndex = selectedCardIndex
            originalRecommendedCardIndex = recommendedCardIndex
            originalShowAIRibbon = showAIRibbon
        }
        isInBreakMode = true
        breakRecommendation = recommendation
        greetingText = recommendation
        
        // 将AI放松建议映射为五个卡片之一，并与主页推荐状态保持一致
        let normalized = recommendation
            .replacingOccurrences(of: "。", with: "")
            .replacingOccurrences(of: ".", with: "")
            .lowercased()
        let mapping: [(String, Int)] = [
            ("深呼吸", 0), ("呼吸", 0), ("breathe", 0),
            ("种子", 1), ("冥想", 1), ("专注", 1), ("meditation", 1),
            ("音乐", 2), ("听音乐", 2), ("music", 2), ("疗愈", 2),
            ("运动", 3), ("拉伸", 3), ("stretch", 3), ("活动", 3), ("锻炼", 3),
            ("戳泡泡", 4), ("泡泡", 4), ("bubble", 4), ("休息", 4), ("放松", 4)
        ]
        var mappedIndex: Int? = mapping.first { key, _ in
            let keyLower = key.lowercased()
            return normalized.contains(keyLower)
        }?.1
        // 如果无法从文案中解析出具体方式，则按休息时长启发式回退
        if mappedIndex == nil {
            switch duration {
            case 20...: mappedIndex = 3
            case 10..<20: mappedIndex = 2
            case 5..<10: mappedIndex = 1
            case 2..<5: mappedIndex = 4
            default: mappedIndex = 0
            }
        }
        if let idx = mappedIndex {
            recommendedCardIndex = idx
            showAIRibbon = true
            if selectedCardIndex != idx {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    selectedCardIndex = idx
                    updateKnobRotation()
                }
            }
        }

        // 设置定时器，在建议的放松时间结束后恢复问候语
        let recommendedDuration: TimeInterval
        switch duration {
        case 15..<30: recommendedDuration = 300 // 5分钟
        case 30..<60: recommendedDuration = 600 // 10分钟
        default: recommendedDuration = 900 // 15分钟
        }
        
        breakTimer?.invalidate()
        breakTimer = Timer.scheduledTimer(withTimeInterval: recommendedDuration, repeats: false) { _ in
            Task { @MainActor in
                self.exitBreakMode()
            }
        }
    }
    
    // 新增：退出休息模式
    private func exitBreakMode() {
        isInBreakMode = false
        greetingText = originalGreeting
        breakRecommendation = ""
        breakTimer?.invalidate()
        breakTimer = nil
        // 恢复进入休息模式前的主页推荐与选择状态
        recommendedCardIndex = originalRecommendedCardIndex
        showAIRibbon = originalShowAIRibbon
        if selectedCardIndex != originalSelectedCardIndex {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedCardIndex = originalSelectedCardIndex
                updateKnobRotation()
            }
        }
    }
    
    // 新增：刷新问候语（专注模式下每30分钟刷新）
    private func refreshGreetingIfNeeded() async {
        // 只在非休息模式下刷新问候语
        guard !isInBreakMode else { return }
        
        let now = Date()
        let timeSinceLastRefresh = now.timeIntervalSince(lastGreetingRefresh)
        
        // 如果距离上次刷新超过25分钟，则刷新（提供5分钟缓冲）
        if timeSinceLastRefresh >= 1500 {
            lastGreetingRefresh = now
            await fetchAndAnalyzeCalendar()
        }
    }
    
    // 新增：基于 Qwen API 获取推荐卡片索引
    private func requestRecommendedCardIndex(from calendarContent: String) async {
        let tokens = readModelScopeTokens()
        guard !tokens.isEmpty, let url = URL(string: "https://api-inference.modelscope.cn/v1/chat/completions") else { return }
        let system = "你将阅读用户今天的日程，仅输出一个放松方式中文名称，且必须是以下五个之一：深呼吸、种子、音乐、运动、戳泡泡。不要输出其他任何文字或标点。"
        let user = "今天日程如下：\n\(calendarContent)\n\n请从[深呼吸, 种子, 音乐, 运动, 戳泡泡]中选择最合适的一项，且只输出该项名称。"
        let payload: [String: Any] = [
            "model": "Qwen/Qwen3-Coder-480B-A35B-Instruct",
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "temperature": 0.2,
            "max_tokens": 16,
            "stream": false
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        for token in tokens {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            do {
                req.httpBody = try JSONSerialization.data(withJSONObject: payload)
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { continue }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let content = ((json?["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any])?["content"] as? String
                let answer = (content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let normalized = answer.replacingOccurrences(of: "。", with: "").replacingOccurrences(of: ".", with: "")
                let mapping: [(String, Int)] = [
                    ("深呼吸", 0), ("呼吸", 0), ("breathe", 0),
                    ("种子", 1), ("冥想", 1), ("专注", 1), ("meditation", 1),
                    ("音乐", 2), ("听音乐", 2), ("music", 2), ("疗愈", 2),
                    ("运动", 3), ("拉伸", 3), ("stretch", 3), ("活动", 3), ("锻炼", 3),
                    ("戳泡泡", 4), ("泡泡", 4), ("bubble", 4), ("休息", 4), ("放松", 4)
                ]
                let idx = mapping.first(where: { normalized.contains($0.0) })?.1
                await MainActor.run {
                    if let idx = idx {
                        print("AI推荐卡片索引: \(idx), 对应: \(cardData[idx].title)")
                        recommendedCardIndex = idx
                        showAIRibbon = true
                        if selectedCardIndex != idx {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                selectedCardIndex = idx
                                updateKnobRotation()
                            }
                        }
                    } else {
                        print("AI推荐解析失败，文本内容: \(normalized)")
                    }
                }
                return
            } catch {
                continue
            }
        }
    }
    
    // MARK: - 视图渲染
    
    // 顶部标题区域 - 重新设计日期显示
    private var topHeaderView: some View {
        VStack(spacing: 30) { // 增加垂直间距从20到30
            // 顶部布局：左上角日期，右上角头像
            HStack {
                // 左上角日期区域
                VStack(alignment: .leading, spacing: 2) {
                    // 星期文字 - 淡橙色
                    Text(weekdayString.uppercased())
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(Color(red: 1.0, green: 0.796, blue: 0.408)) // #FFCB68
                        .tracking(1.2) // 字母间距
                    
                    // Melody标题 - 深橙色
                    Text("Melody")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(Color(red: 0.968, green: 0.639, blue: 0.0)) // #F7A300
                }
                
                Spacer()
                
                // 右上角头像 - 保持原有点击逻辑
                Button {
                    showProfileView = true
                } label: {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("👤")
                                .font(.system(size: 20))
                        )
                }
            }
            
            // AI问候卡片
            HStack(alignment: .top, spacing: 12) {
                // 左侧头像
                Circle()
                    .fill(Color(red: 1.0, green: 0.796, blue: 0.408)) // #FFCB68橙色
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("😊")
                            .font(.system(size: 24))
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    if recommendationStatus == .loading {
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.7))
                                .frame(height: 12)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 160, height: 12)
                        }
                        .frame(minHeight: greetingCollapsedMinHeight(for: greetingText))
                        .transition(.opacity)
                        .animation(Motion.opacityEase, value: recommendationStatus)
                    } else {
                        TypewriterText(
                            text: greetingText,
                            fontSize: adaptiveFontSize(for: greetingText),
                            lineLimit: isGreetingExpanded ? 100 : 2
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: greetingCollapsedMinHeight(for: greetingText))
                        .transition(.opacity)
                        .animation(Motion.opacityEase, value: greetingText)
                    }
                    
                    // 展开/收起按钮
                    HStack {
                        Spacer()
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isGreetingExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isGreetingExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.orange)
                                .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.7))
                            .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(red: 0.988, green: 0.898, blue: 0.737)) // #FCE5BC橙色
            )
        }
    }
    
    // 扇形卡片视图 - 调整为完全显示所有卡片
    private var fanCardsView: some View {
        ZStack {
            ForEach(Array(cardData.enumerated()), id: \.offset) { index, card in
                FanCardView(
                    card: card,
                    index: index,
                    selectedIndex: selectedCardIndex,
                    dragOffset: dragOffset,
                    isRecommended: (recommendedCardIndex == index && showAIRibbon)
                )
                .onTapGesture {
                    if index != selectedCardIndex {
                        withAnimation(Motion.componentSpring) {
                            selectedCardIndex = index
                            updateKnobRotation()
                        }
                    } else {
                        // 点击已选中的卡片，触发导航
                        navigateToSession(for: index)
                    }
                }
            }
        }
        .frame(height: 400) // 增加高度确保卡片完全显示
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    
                    withAnimation(Motion.componentSpring) {
                        if value.translation.width > threshold && selectedCardIndex > 0 {
                            selectedCardIndex -= 1
                            updateKnobRotation()
                        } else if value.translation.width < -threshold && selectedCardIndex < cardData.count - 1 {
                            selectedCardIndex += 1
                            updateKnobRotation()
                        }
                        dragOffset = 0
                    }
                }
        )
        #if os(iOS)
        .navigationDestination(isPresented: $showBreathingSession) {
            BreathingSessionView(durationMinutes: breathingDuration)
        }
        .navigationDestination(isPresented: $showMusicSession) {
            MusicSessionView(durationMinutes: musicDuration)
        }
        .navigationDestination(isPresented: $showStretchSession) {
            StretchSessionView()
        }
        .navigationDestination(isPresented: $showMeditationSession) {
            MeditationSessionView()
        }
        .navigationDestination(isPresented: $showBubbleSession) {
            BubbleSessionView()
        }
        #endif
    }
    
    // 底部控制区域 - 简化设计，旋钮居中
    private var bottomControlsView: some View {
        HStack {
            
            
            // 中间：机械旋钮（移到中间位置）
            ZStack {
                // 底座阴影
                Circle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 170, height: 170)
                    .offset(x: 2, y: 2)
                
                // 外圈基座
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.4)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 160, height: 160)
                
                // 外圈边框
                Circle()
                    .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                    .frame(width: 160, height: 160)
                
                // 旋钮刻度
                ForEach(0..<cardData.count, id: \.self) { index in
                    let isActive = index == selectedCardIndex
                    Rectangle()
                        .fill(isActive ? knobAccentColor : Color.gray.opacity(0.4))
                        .frame(width: isActive ? 6 : 2, height: isActive ? 24 : 8)
                        .offset(y: -32)
                        .rotationEffect(.degrees(Double(index) * (360.0 / Double(cardData.count))))
                        .animation(Motion.quickSpring, value: isActive)
                }
                
                // 旋钮主体
                Circle()
                    .fill(RadialGradient(
                        gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.5), Color.gray.opacity(0.7)]),
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 30
                    ))
                    .frame(width: 170, height: 170)
                    .shadow(color: .black.opacity(0.2), radius: 3)
                
                // 旋钮纹理
                ForEach(0..<12, id: \.self) { index in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 0.8, height: 25)
                        .offset(y: 0)
                        .rotationEffect(.degrees(Double(index) * 30))
                }
                
                // 中心指示器
                Circle()
                    .fill(knobAccentColor)
                    .frame(width: 40, height: 40)
                    .shadow(color: knobAccentColor.opacity(0.5), radius: 2)
            }
            .rotationEffect(.degrees(knobRotation))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let center = CGPoint(x: 40, y: 40)
                        let vector = CGPoint(x: value.location.x - center.x, y: value.location.y - center.y)
                        let angle = atan2(vector.y, vector.x) * 180 / .pi
                        let normalizedAngle = (angle + 360).truncatingRemainder(dividingBy: 360)
                        
                        let segmentAngle = 360.0 / Double(cardData.count)
                        let targetIndex = Int((normalizedAngle + segmentAngle / 2) / segmentAngle) % cardData.count
                        
                        if targetIndex != selectedCardIndex {
                            withAnimation(Motion.quickSpring) {
                                selectedCardIndex = targetIndex
                                updateKnobRotation()
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(Motion.componentSpring) {
                            updateKnobRotation()
                        }
                    }
            )
            
            
        }
        .offset(y: -12)
    }
    
    // 计算自适应字体大小的函数
    private func adaptiveFontSize(for text: String) -> CGFloat {
        let characterCount = text.count
        
        // 根据字符数量调整字体大小
        switch characterCount {
        case 0...15:
            return 16 // 15字以内保持原始大小
        case 16...20:
            return 15 // 16-20字稍微减小
        case 21...25:
            return 14 // 21-25字进一步减小
        case 26...30:
            return 13 // 26-30字继续减小
        default:
            return 12 // 超过30字使用最小字体
        }
    }
    
    // 问候卡最小高度，锁定两行，避免打字动画引起回流（P1）
    private func greetingCollapsedMinHeight(for text: String) -> CGFloat {
        let font = adaptiveFontSize(for: text)
        return font * 1.45 * 2
    }
    
    // 更新旋钮旋转角度的函数
    private func updateKnobRotation() {
        let segmentAngle = 360.0 / Double(cardData.count)
        knobRotation = Double(selectedCardIndex) * segmentAngle
        
        // 添加触觉反馈
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    // 导航到对应的会话页面
    private func navigateToSession(for index: Int) {
        let available = computeAvailableMinutesFromSchedule()
        switch index {
        case 0: // 深呼吸（1-5分钟以内）
            breathingDuration = max(1, min(available, 5))
            showBreathingSession = true
        case 1: // 冥想（页面内按实际耗时记录）
            showMeditationSession = true
        case 2: // 音乐（至少2分钟，不超过可用与20分钟）
            musicDuration = max(2, min(available, 20))
            showMusicSession = true
        case 3: // 运动（页面内按实际耗时记录）
            showStretchSession = true
        case 4: // 戳泡泡（页面内按实际耗时记录）
            showBubbleSession = true
        default:
            break
        }
    }

    // 基于今日日程与当前时间计算可用分钟数
    private func computeAvailableMinutesFromSchedule() -> Int {
        let now = Date()
        // 找到下一个事件
        let nextEvent = todaysEvents.first { $0.startDate > now }
        let minutesToNext = nextEvent.map { max(0, Int($0.startDate.timeIntervalSince(now) / 60.0)) } ?? 60
        // 正在事件中则给短时窗口
        let inEvent = todaysEvents.contains { $0.startDate <= now && now < $0.endDate }
        return inEvent ? min(minutesToNext, 5) : minutesToNext
    }
    
}

// MARK: - 流式输出文本组件
struct TypewriterText: View {
    let text: String
    let fontSize: CGFloat
    let lineLimit: Int?
    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0
    @State private var timer: Timer?
    @State private var showCursor: Bool = true
    @State private var cursorTimer: Timer?
    
    // 默认初始化器（向后兼容）
    init(text: String, fontSize: CGFloat) {
        self.text = text
        self.fontSize = fontSize
        self.lineLimit = 2
    }
    
    // 带 lineLimit 参数的初始化器
    init(text: String, fontSize: CGFloat, lineLimit: Int?) {
        self.text = text
        self.fontSize = fontSize
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(displayedText)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(.black)
                .lineLimit(lineLimit)
                .multilineTextAlignment(.leading)
            
            // 打字光标效果
            if currentIndex < text.count {
                Text("|")
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.black)
                    .opacity(showCursor ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showCursor)
            }
        }
        .onAppear {
            startTyping()
            startCursorAnimation()
        }
        .onChange(of: text) { oldValue, newValue in
            restartTyping()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func startTyping() {
        displayedText = ""
        currentIndex = 0
        
        timer?.invalidate()
        
        // 根据文字长度调整打字速度
        let typingSpeed: TimeInterval = text.count > 20 ? 0.03 : 0.05
        
        timer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { _ in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText = String(text[..<text.index(after: index)])
                currentIndex += 1
            } else {
                timer?.invalidate()
                timer = nil
                // 打字完成后停止光标闪烁
                cursorTimer?.invalidate()
                cursorTimer = nil
            }
        }
    }
    
    private func startCursorAnimation() {
        cursorTimer?.invalidate()
        showCursor = true
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            showCursor.toggle()
        }
    }
    
    private func restartTyping() {
        timer?.invalidate()
        timer = nil
        cursorTimer?.invalidate()
        cursorTimer = nil
        startTyping()
        startCursorAnimation()
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        cursorTimer?.invalidate()
        cursorTimer = nil
    }
}

// MARK: - 扇形卡片组件
struct FanCardView: View {
    let card: (title: String, color: Color, description: String, imageName: String)
    let index: Int
    let selectedIndex: Int
    let dragOffset: CGFloat
    let isRecommended: Bool
    
    var body: some View {
        let isCenter = index == selectedIndex
        let distanceFromCenter = abs(CGFloat(index - selectedIndex))
        
        // 扇形布局计算（自适应倾斜：以选中卡片为0°，两侧随距离增加而增大）
        let totalCards = 5
        let maxAngle: Double = 28
        // 与选中卡片的相对位置（向左为负，向右为正）
        let relative = CGFloat(index - selectedIndex)
        // 根据当前所选位置动态确定两端最大距离，确保最外侧始终接近 maxAngle
        let halfRange = CGFloat(max(selectedIndex, totalCards - 1 - selectedIndex))
        let normalized = halfRange == 0 ? 0 : (relative / halfRange) // [-1, 1]
        let baseAngle = Double(normalized) * maxAngle
        
        // 位置计算 - 调整间距确保所有卡片可见
        // 尺寸整体放大25%
        let cardWidth: CGFloat = isCenter ? 150 : 125
        let cardHeight: CGFloat = isCenter ? 225 : 188
        // 增大间距，使屏幕同时只展示约3张卡片（两侧不完整）
        let baseSpacing: CGFloat = 120
        let xPosition = CGFloat(index - selectedIndex) * baseSpacing
        
        // 弧形效果：以选中卡片为弧顶，越远越低
        let arcHeight: CGFloat = 26
        let yOffset = arcHeight * (1 - (normalized * normalized))
        
        // 视觉效果
        let scale: CGFloat = isCenter ? 1.15 : (distanceFromCenter == 1 ? 0.95 : 0.8)
        let opacity: Double = isCenter ? 1.0 : (distanceFromCenter <= 1 ? 0.85 : 0.6)
        
        // 直接使用图片作为卡片主体，完全替代原来的纯色卡片
        Image(card.imageName)
            .resizable()
            .aspectRatio(contentMode: .fill) // 完全填充
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 20)) // 裁剪为圆角矩形
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4) // 添加阴影效果
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(baseAngle))
            .offset(x: xPosition + dragOffset, y: -yOffset)
            .animation(Motion.componentSpring, value: scale)
            .animation(Motion.componentSpring, value: xPosition)
            .animation(Motion.opacityEase, value: opacity)
            .zIndex(isCenter ? 10 : (10 - distanceFromCenter))
            // 顶部左侧角标
            .overlay(alignment: .topLeading) {
                if isRecommended {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("AI智能推荐")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.95))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                    .padding(8)
                }
            }
            .overlay(
                // 底部标题区域 - 半透明背景确保文字可读性
                VStack {
                    Spacer()
                    Text(card.title)
                        .font(isCenter ? .headline : .subheadline)
                        .fontWeight(isCenter ? .bold : .medium)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.55))
                        )
                        .padding(.bottom, isCenter ? 16 : 12)
                }
            )
    }
}

// MARK: - 其他标签页视图（保持不变）
struct SearchView: View {
    var body: some View {
        VStack {
            Text("搜索内容")
                .font(.largeTitle)
                .padding()
            
            Spacer()
        }
        .navigationTitle("搜索")
    }
}

struct FavoritesView: View {
    var body: some View {
        VStack {
            Text("收藏内容")
                .font(.largeTitle)
                .padding()
            
            Spacer()
        }
        .navigationTitle("收藏")
    }
}

// ProfileView 和相关组件现在在单独的 ProfileView.swift 文件中定义


// MARK: - 主应用视图（简化版本）
struct MelodyAppView: View {
    var body: some View {
        MainView()
    }
}

// MARK: - 预览（保持不变）
#Preview {
    MainView()
}

// MARK: - 日程条视图
struct ScheduleBar: View {
    let intervals: [DateInterval]
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 空闲背景
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.3))
                // 已安排区间
                ForEach(intervals, id: \.start) { interval in
                    let dayStart = Calendar.current.startOfDay(for: Date())
                    let width = geo.size.width * interval.duration / 86400
                    let offset = geo.size.width * interval.start.timeIntervalSince(dayStart) / 86400
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.6))
                        .frame(width: width)
                        .offset(x: offset)
                }
            }
        }
    }
}
