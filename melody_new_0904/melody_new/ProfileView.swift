import SwiftUI
import Charts
import UserNotifications
import UIKit

struct ProfileView: View {
    @State private var todayMinutes: Int = 0
    @State private var totalSessions: Int = 0
    @State private var streakDays: Int = 0
    @State private var showingSettings = false
    @State private var showingDataHistory = false
    @State private var weeklyStats: [DayStat] = []
    @Environment(\.presentationMode) var presentationMode
    
    // 计算属性：格式化时间
    private func formattedTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) 分钟"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) 小时"
            } else {
                return "\(hours) 小时 \(remainingMinutes) 分钟"
            }
        }
    }
    
    // 自定义颜色 - 与app主题保持一致
    let customOrange = Color(red: 255/255, green: 203/255, blue: 104/255)
    let customDarkOrange = Color(red: 247/255, green: 163/255, blue: 3/255)
    let customGreen = Color(red: 209/255, green: 246/255, blue: 88/255)
    let customYellow = Color(red: 255/255, green: 255/255, blue: 208/255)
    let customBlue = Color(red: 217/255, green: 242/255, blue: 255/255)
    let backgroundYellow = Color(red: 1.0, green: 0.953, blue: 0.847) // 与主页面一致
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundYellow.ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header区域
                        headerSection
                        
                        // 用户信息卡片
                        userInfoCard
                        
                        // 今日数据概览
                        todayStatsCard
                        
                        // 7天趋势图表
                        if #available(iOS 16.0, *) {
                            weeklyTrendCard
                        } else {
                            weeklyTrendCardLegacy
                        }
                        
                        // 成就与进展
                        achievementCard
                        
                        // 快速操作
                        quickActionsCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true) // 隐藏原生导航栏，使用自定义返回按钮
        .onAppear {
            loadUserData()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingDataHistory) {
            DataHistoryView()
        }
    }
    
    // MARK: - 视图组件
    
    private var headerSection: some View {
        HStack {
            // 返回按钮 - 使用统一组件
            BackButton.defaultStyle {
                presentationMode.wrappedValue.dismiss()
            }
            
            Spacer()
            
            Text("个人中心")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            // 设置按钮
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(customOrange)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var userInfoCard: some View {
        VStack(spacing: 16) {
            // 头像和基本信息
            VStack(spacing: 12) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                
                VStack(spacing: 4) {
                    Text("Melody 用户")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("已加入 \(getCurrentYear()) 年")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
    
    private var todayStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("今日数据")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("实时更新")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 12) {
                StatRow(
                    iconColor: customDarkOrange,
                    iconName: "clock.fill",
                    value: formattedTime(todayMinutes),
                    description: "今日放松时长",
                    trend: calculateTrendPercentage(for: "minutes"),
                    trendColor: getTrendColor(for: "minutes")
                )
                
                StatRow(
                    iconColor: customBlue,
                    iconName: "heart.fill",
                    value: "\(totalSessions) 次",
                    description: "完成会话数",
                    trend: calculateTrendPercentage(for: "sessions"),
                    trendColor: getTrendColor(for: "sessions")
                )
                
                StatRow(
                    iconColor: customGreen,
                    iconName: "checkmark.seal.fill",
                    value: "\(streakDays) 天",
                    description: "连续使用天数",
                    trend: streakDays > 0 ? "保持" : "开始",
                    trendColor: streakDays > 0 ? .green : .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    @available(iOS 16.0, *)
    private var weeklyTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("7天趋势")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button("查看详情") {
                    showingDataHistory = true
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
            
            if !weeklyStats.isEmpty {
                Chart(weeklyStats) { stat in
                    BarMark(
                        x: .value("Day", stat.date, unit: .day),
                        y: .value("Minutes", stat.minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [customOrange, customDarkOrange]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(dayOfWeek(date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text("\(minutes)分")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("暂无数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // iOS 15及以下版本的图表
    private var weeklyTrendCardLegacy: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("7天趋势")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button("查看详情") {
                    showingDataHistory = true
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
            
            if !weeklyStats.isEmpty {
                // 简单的条形图实现
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(weeklyStats.enumerated()), id: \.offset) { index, stat in
                        VStack(spacing: 4) {
                            // 条形图
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [customOrange, customDarkOrange]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 25, height: max(4, CGFloat(stat.minutes) * 2))
                                .animation(.easeInOut(duration: 0.5), value: stat.minutes)
                            
                            // 日期标签
                            Text(dayOfWeek(stat.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("暂无数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private var achievementCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("成就与进展")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                AchievementRow(
                    icon: "flag.fill",
                    title: "坚持使用",
                    description: "连续\(streakDays)天使用应用",
                    color: customOrange,
                    isCompleted: streakDays >= 7
                )
                
                AchievementRow(
                    icon: "star.fill",
                    title: "放松达人",
                    description: "累计放松时长达到\(formattedTime(todayMinutes * 7))",
                    color: customGreen,
                    isCompleted: todayMinutes * 7 >= 60
                )
                
                AchievementRow(
                    icon: "heart.fill",
                    title: "自律先锋",
                    description: "本周完成\(totalSessions)次会话",
                    color: customBlue,
                    isCompleted: totalSessions >= 10
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速操作")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                ActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "数据详情",
                    subtitle: "查看详细统计",
                    color: customBlue
                ) {
                    showingDataHistory = true
                }
                
                ActionButton(
                    icon: "square.and.arrow.up",
                    title: "分享成就",
                    subtitle: "与朋友分享进展",
                    color: customGreen
                ) {
                    shareAchievement()
                }
                
                ActionButton(
                    icon: "questionmark.circle",
                    title: "帮助支持",
                    subtitle: "使用指南和反馈",
                    color: customOrange
                ) {
                    openHelp()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - 辅助方法
    
    private func loadUserData() {
        // 迁移旧数据（如果需要）
        RelaxStatsStore.shared.migrateOldData()
        
        // 加载真实数据
        todayMinutes = RelaxStatsStore.shared.minutes(on: Date())
        totalSessions = RelaxStatsStore.shared.sessionsCount(on: Date())
        weeklyStats = RelaxStatsStore.shared.last7DaysStats()
        
        // 计算连续天数
        streakDays = RelaxStatsStore.shared.calculateStreakDays()
    }
    
    private func calculateTrendPercentage(for metric: String) -> String {
        let trend = RelaxStatsStore.shared.getTrendComparison(for: metric, days: 7)
        
        if abs(trend) < 0.1 {
            return "持平"
        } else if trend > 0 {
            return String(format: "+%.0f%%", trend)
        } else {
            return String(format: "%.0f%%", trend)
        }
    }
    
    private func getTrendColor(for metric: String) -> Color {
        let trend = RelaxStatsStore.shared.getTrendComparison(for: metric, days: 7)
        
        if abs(trend) < 0.1 {
            return .gray
        } else if trend > 0 {
            return .green
        } else {
            return .orange
        }
    }
    
    private func getCurrentYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
    
    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func shareAchievement() {
        let store = RelaxStatsStore.shared
        let totalStats = store.getTotalStats()
        let longestStreak = store.calculateStreakDays()
        
        let shareText = """
        🌟 我在 Melody 中的放松成就 🌟
        
        📊 总放松时长: \(formattedTime(totalStats.totalMinutes))
        🎯 完成会话: \(totalStats.totalSessions) 次
        🔥 最长连续: \(longestStreak) 天
        
        每天给自己一些放松的时光，让心灵更加平静 ✨
        
        #Melody #放松 #身心健康
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // 获取当前的视图控制器
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // 对于iPad，设置弹出框的源
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = window
                popoverController.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func openHelp() {
        // 创建帮助内容
        let helpContent = """
        📖 使用指南
        
        🎯 如何开始放松：
        • 在主页选择您喜欢的放松方式
        • 根据提示进行深呼吸、冥想或拉伸
        • 完成后会自动记录到您的统计中
        
        📊 查看数据：
        • 在个人中心可以查看详细的使用统计
        • 支持查看7天、30天或全部数据
        • 了解您的放松习惯和进展
        
        ⚙️ 个性化设置：
        • 在设置中调整每日目标
        • 开启通知提醒，养成放松习惯
        • 选择您偏好的音效和触觉反馈
        
        💡 小贴士：
        • 建议每天至少放松10-15分钟
        • 保持规律的放松时间
        • 尝试不同的放松方式，找到最适合的
        
        如有其他问题，请联系：melody@support.com
        """
        
        let alertController = UIAlertController(
            title: "帮助与支持",
            message: helpContent,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "了解了", style: .default))
        alertController.addAction(UIAlertAction(title: "联系我们", style: .default) { _ in
            self.contactSupport()
        })
        
        // 获取当前的视图控制器并显示
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alertController, animated: true)
        }
    }
    
    private func contactSupport() {
        // 尝试打开邮件应用
        if let emailURL = URL(string: "mailto:melody@support.com?subject=Melody%20App%20Support") {
            if UIApplication.shared.canOpenURL(emailURL) {
                UIApplication.shared.open(emailURL)
            } else {
                // 如果无法打开邮件应用，复制邮箱地址到剪贴板
                UIPasteboard.general.string = "melody@support.com"
                
                let alert = UIAlertController(
                    title: "邮箱地址已复制",
                    message: "melody@support.com 已复制到剪贴板",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    rootViewController.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - 数据结构（DayStat 在其他文件中已定义）

// MARK: - 组件视图

struct StatRow: View {
    let iconColor: Color
    let iconName: String
    let value: String
    let description: String
    let trend: String
    let trendColor: Color
    
    // 兼容性初始化器
    init(iconColor: Color, iconName: String, value: String, description: String, trend: String) {
        self.iconColor = iconColor
        self.iconName = iconName
        self.value = value
        self.description = description
        self.trend = trend
        self.trendColor = .green
    }
    
    init(iconColor: Color, iconName: String, value: String, description: String, trend: String, trendColor: Color) {
        self.iconColor = iconColor
        self.iconName = iconName
        self.value = value
        self.description = description
        self.trend = trend
        self.trendColor = trendColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: iconName)
                        .foregroundColor(.white)
                        .font(.title3)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text(trend)
                        .font(.caption)
                        .foregroundColor(trendColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(trendColor.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
}

struct AchievementRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isCompleted ? color : Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.system(size: 16, weight: .medium))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(16)
        }
    }
}

// MARK: - 设置页面
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
    @State private var soundEnabled = UserDefaults.standard.bool(forKey: "sound_enabled")
    @State private var hapticEnabled = UserDefaults.standard.bool(forKey: "haptic_enabled")
    @State private var dailyGoalMinutes = UserDefaults.standard.integer(forKey: "daily_goal_minutes") == 0 ? 30 : UserDefaults.standard.integer(forKey: "daily_goal_minutes")
    @State private var showingResetAlert = false
    @State private var showingAbout = false
    
    // 自定义颜色 - 与主题保持一致
    let customOrange = Color(red: 255/255, green: 203/255, blue: 104/255)
    let customDarkOrange = Color(red: 247/255, green: 163/255, blue: 3/255)
    let customGreen = Color(red: 209/255, green: 246/255, blue: 88/255)
    let customYellow = Color(red: 255/255, green: 255/255, blue: 208/255)
    let customBlue = Color(red: 217/255, green: 242/255, blue: 255/255)
    let backgroundYellow = Color(red: 1.0, green: 0.953, blue: 0.847)
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundYellow.ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // 通知设置
                        notificationSettingsCard
                        
                        // 目标设置
                        goalSettingsCard
                        
                        // 偏好设置
                        preferenceSettingsCard
                        
                        // 数据管理
                        dataManagementCard
                        
                        // 关于应用
                        aboutCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("重置数据", isPresented: $showingResetAlert) {
            Button("取消", role: .cancel) { }
            Button("确认重置", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("此操作将清除所有放松记录和统计数据，且无法恢复。确定要继续吗？")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private var headerSection: some View {
        HStack {
            BackButton.defaultStyle {
                presentationMode.wrappedValue.dismiss()
            }
            
            Spacer()
            
            Text("设置")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            // 占位，保持对称
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var notificationSettingsCard: some View {
        SettingsCard(title: "通知设置", icon: "bell.fill", iconColor: customOrange) {
            VStack(spacing: 16) {
                SettingsToggle(
                    title: "推送通知",
                    subtitle: "接收放松提醒和成就通知",
                    isOn: $notificationsEnabled
                ) {
                    UserDefaults.standard.set(notificationsEnabled, forKey: "notifications_enabled")
                    if notificationsEnabled {
                        requestNotificationPermission()
                    }
                }
            }
        }
    }
    
    private var goalSettingsCard: some View {
        SettingsCard(title: "目标设置", icon: "target", iconColor: customGreen) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("每日放松目标")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text("设置每天的放松时长目标")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if dailyGoalMinutes > 5 {
                                dailyGoalMinutes -= 5
                                saveDailyGoal()
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(customOrange)
                                .font(.title2)
                        }
                        
                        Text("\(dailyGoalMinutes) 分钟")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(minWidth: 80)
                        
                        Button(action: {
                            if dailyGoalMinutes < 120 {
                                dailyGoalMinutes += 5
                                saveDailyGoal()
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(customOrange)
                                .font(.title2)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: dailyGoalMinutes)
            }
        }
    }
    
    private var preferenceSettingsCard: some View {
        SettingsCard(title: "偏好设置", icon: "slider.horizontal.3", iconColor: customBlue) {
            VStack(spacing: 16) {
                SettingsToggle(
                    title: "音效反馈",
                    subtitle: "播放按钮点击和完成音效",
                    isOn: $soundEnabled
                ) {
                    UserDefaults.standard.set(soundEnabled, forKey: "sound_enabled")
                }
                
                SettingsToggle(
                    title: "触觉反馈",
                    subtitle: "提供触觉震动反馈",
                    isOn: $hapticEnabled
                ) {
                    UserDefaults.standard.set(hapticEnabled, forKey: "haptic_enabled")
                }
            }
        }
    }
    
    private var dataManagementCard: some View {
        SettingsCard(title: "数据管理", icon: "externaldrive.fill", iconColor: Color.purple) {
            VStack(spacing: 12) {
                SettingsButton(
                    title: "导出数据",
                    subtitle: "导出放松记录和统计数据",
                    icon: "square.and.arrow.up",
                    color: customGreen
                ) {
                    exportData()
                }
                
                SettingsButton(
                    title: "重置数据",
                    subtitle: "清除所有记录和统计",
                    icon: "trash.fill",
                    color: .red
                ) {
                    showingResetAlert = true
                }
            }
        }
    }
    
    private var aboutCard: some View {
        SettingsCard(title: "关于", icon: "info.circle.fill", iconColor: Color.gray) {
            VStack(spacing: 12) {
                SettingsButton(
                    title: "应用信息",
                    subtitle: "版本、开发者等信息",
                    icon: "app.fill",
                    color: customOrange
                ) {
                    showingAbout = true
                }
                
                SettingsButton(
                    title: "反馈建议",
                    subtitle: "帮助我们改进应用",
                    icon: "envelope.fill",
                    color: customBlue
                ) {
                    sendFeedback()
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func saveDailyGoal() {
        UserDefaults.standard.set(dailyGoalMinutes, forKey: "daily_goal_minutes")
        // 触觉反馈
        if hapticEnabled {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if !granted {
                    notificationsEnabled = false
                    UserDefaults.standard.set(false, forKey: "notifications_enabled")
                }
            }
        }
    }
    
    private func resetAllData() {
        RelaxStatsStore.shared.clearAllData()
        
        // 触觉反馈
        if hapticEnabled {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
    
    private func exportData() {
        let store = RelaxStatsStore.shared
        // 使用公开API获取统计
        let totalStats = store.getTotalStats()
        
        // 创建CSV格式的数据统计
        var csvContent = "统计项目,数值\n"
        csvContent += "总放松时长(分钟),\(totalStats.totalMinutes)\n"
        csvContent += "总会话数,\(totalStats.totalSessions)\n"
        csvContent += "平均每日时长,\(String(format: "%.1f", totalStats.averageDaily))\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        
        // 创建临时文件
        let fileName = "Melody_数据导出_\(dateFormatter.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // 显示分享界面
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = window
                    popoverController.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                rootViewController.present(activityVC, animated: true)
            }
            
            // 触觉反馈
            if hapticEnabled {
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
            
        } catch {
            // 显示错误提示
            let alert = UIAlertController(
                title: "导出失败",
                message: "无法创建数据文件，请稍后重试",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    private func sendFeedback() {
        // 实现反馈功能
        print("发送反馈")
    }
}

// MARK: - 设置页面辅助组件
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    @State private var isPressed = false
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Circle()
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(isPressed ? 0.12 : 0.08), radius: isPressed ? 12 : 8, x: 0, y: isPressed ? 8 : 4)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let action: () -> Void
    @State private var animateToggle = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .onChange(of: isOn) { newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                        animateToggle.toggle()
                    }
                    action()
                    
                    // 触觉反馈
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
                .scaleEffect(animateToggle ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: animateToggle)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        animateToggle = false
                    }
                }
        }
    }
}

struct SettingsButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // 触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.system(size: 14, weight: .medium))
                    )
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
                    .rotationEffect(.degrees(isPressed ? 5 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isPressed)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(isPressed ? 0.8 : 0.5))
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - 关于页面
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let customOrange = Color(red: 255/255, green: 203/255, blue: 104/255)
    let backgroundYellow = Color(red: 1.0, green: 0.953, blue: 0.847)
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundYellow.ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App Logo和信息
                        VStack(spacing: 16) {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            
                            VStack(spacing: 8) {
                                Text("Melody")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text("版本 1.0.0")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        // 应用描述
                        VStack(alignment: .leading, spacing: 16) {
                            Text("关于 Melody")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text("Melody 是一款专注于身心放松的应用，通过深呼吸、冥想、音乐和拉伸等多种方式，帮助您在繁忙的生活中找到内心的平静。\n\n我们相信，每个人都值得拥有一段专属的放松时光。")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        )
                        
                        // 开发信息
                        VStack(alignment: .leading, spacing: 16) {
                            Text("开发团队")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            VStack(spacing: 12) {
                                InfoRow(title: "开发者", value: "Melody Team")
                                InfoRow(title: "技术支持", value: "melody@support.com")
                                InfoRow(title: "隐私政策", value: "查看详情", isLink: true)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    var isLink: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(isLink ? .blue : .secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 数据历史页面
struct DataHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTimeRange: TimeRange = .week
    @State private var monthlyStats: [DayStat] = []
    @State private var weeklyStats: [DayStat] = []
    @State private var recentSessions: [SessionRecord] = []
    @State private var totalStats: TotalStats = TotalStats()
    
    // 自定义颜色
    let customOrange = Color(red: 255/255, green: 203/255, blue: 104/255)
    let customDarkOrange = Color(red: 247/255, green: 163/255, blue: 3/255)
    let customGreen = Color(red: 209/255, green: 246/255, blue: 88/255)
    let customBlue = Color(red: 217/255, green: 242/255, blue: 255/255)
    let backgroundYellow = Color(red: 1.0, green: 0.953, blue: 0.847)
    
    enum TimeRange: String, CaseIterable {
        case week = "7天"
        case month = "30天"
        case all = "全部"
    }
    
    struct TotalStats {
        var totalMinutes: Int = 0
        var totalSessions: Int = 0
        var longestStreak: Int = 0
        var favoriteType: SessionType = .breathing
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundYellow.ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // 时间范围选择器
                        timeRangeSelector
                        
                        // 总体统计卡片
                        totalStatsCard
                        
                        // 趋势图表
                        if #available(iOS 16.0, *) {
                            trendChartCard
                        } else {
                            trendChartCardLegacy
                        }
                        
                        // 会话类型分布
                        sessionTypeDistributionCard
                        
                        // 最近会话记录
                        recentSessionsCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadData()
        }
    }
    
    private var headerSection: some View {
        HStack {
            BackButton.defaultStyle {
                presentationMode.wrappedValue.dismiss()
            }
            
            Spacer()
            
            Text("数据详情")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    // 触觉反馈
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                        selectedTimeRange = range
                    }
                    
                    // 延迟加载数据以配合动画
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        loadData()
                    }
                }) {
                    Text(range.rawValue)
                        .font(.headline)
                        .fontWeight(selectedTimeRange == range ? .bold : .medium)
                        .foregroundColor(selectedTimeRange == range ? .white : .black)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTimeRange == range ? customOrange : Color.clear)
                                .scaleEffect(selectedTimeRange == range ? 1.02 : 1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: selectedTimeRange)
                        )
                        .scaleEffect(selectedTimeRange == range ? 1.05 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: selectedTimeRange)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private var totalStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("总体统计")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    icon: "clock.fill",
                    value: formatTime(totalStats.totalMinutes),
                    label: "总时长",
                    color: customOrange
                )
                
                StatCard(
                    icon: "heart.fill",
                    value: "\(totalStats.totalSessions)",
                    label: "总会话",
                    color: customGreen
                )
                
                StatCard(
                    icon: "flame.fill",
                    value: "\(totalStats.longestStreak) 天",
                    label: "最长连续",
                    color: .red
                )
                
                StatCard(
                    icon: "star.fill",
                    value: totalStats.favoriteType.displayName,
                    label: "偏爱类型",
                    color: customBlue
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    @available(iOS 16.0, *)
    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("使用趋势")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            if !weeklyStats.isEmpty {
                Chart(weeklyStats) { stat in
                    LineMark(
                        x: .value("Date", stat.date, unit: .day),
                        y: .value("Minutes", stat.minutes)
                    )
                    .foregroundStyle(customOrange)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    AreaMark(
                        x: .value("Date", stat.date, unit: .day),
                        y: .value("Minutes", stat.minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [customOrange.opacity(0.3), customOrange.opacity(0.1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(dayOfWeek(date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text("\(minutes)分")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } else {
                EmptyChartView()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private var trendChartCardLegacy: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("使用趋势")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            if !weeklyStats.isEmpty {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(weeklyStats.enumerated()), id: \.offset) { index, stat in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [customOrange, customDarkOrange]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 25, height: max(4, CGFloat(stat.minutes) * 2))
                                .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: stat.minutes)
                            
                            Text(dayOfWeek(stat.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            } else {
                EmptyChartView()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private var sessionTypeDistributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("会话类型分布")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                ForEach(SessionType.allCases, id: \.self) { type in
                    let count = recentSessions.filter { $0.type == type }.count
                    let percentage = recentSessions.isEmpty ? 0 : Double(count) / Double(recentSessions.count)
                    
                    SessionTypeRow(
                        type: type,
                        count: count,
                        percentage: percentage,
                        color: colorForSessionType(type)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近会话")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            if recentSessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("暂无会话记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentSessions.prefix(10), id: \.id) { session in
                        SessionRecordRow(session: session)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - 辅助方法
    
    private func loadData() {
        let store = RelaxStatsStore.shared
        
        // 加载统计数据
        switch selectedTimeRange {
        case .week:
            weeklyStats = store.last7DaysStats()
        case .month:
            weeklyStats = store.last30DaysStats()
        case .all:
            weeklyStats = store.last7DaysStats() // 暂时使用7天数据
        }
        
        // 使用真实会话数据
        recentSessions = store.getAllSessions()
        
        // 计算总体统计
        let stats = store.getTotalStats()
        totalStats.totalMinutes = stats.totalMinutes
        totalStats.totalSessions = stats.totalSessions
        totalStats.longestStreak = store.calculateStreakDays()
        // 计算偏爱类型
        let sessions = recentSessions
        var counts: [SessionType: Int] = [:]
        for s in sessions { counts[s.type, default: 0] += 1 }
        if let fav = counts.max(by: { $0.value < $1.value })?.key {
            totalStats.favoriteType = fav
        } else {
            totalStats.favoriteType = .breathing
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(remainingMinutes)分钟"
            }
        }
    }
    
    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func colorForSessionType(_ type: SessionType) -> Color {
        switch type {
        case .breathing: return customOrange
        case .music: return customGreen
        case .meditation: return customBlue
        case .stretch: return .purple
        case .bubble: return .pink
        }
    }
}

// MARK: - 数据历史页面辅助组件
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 18, weight: .medium))
                )
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

struct SessionTypeRow: View {
    let type: SessionType
    let count: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(type.displayName.prefix(1))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text("\(count) 次会话")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f%%", percentage * 100))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                // 进度条
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .overlay(
                            HStack {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color)
                                    .frame(width: geometry.size.width * CGFloat(percentage), height: 4)
                                    .animation(.easeInOut(duration: 0.5), value: percentage)
                                
                                Spacer(minLength: 0)
                            }
                        )
                }
                .frame(height: 4)
                .frame(width: 60)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SessionRecordRow: View {
    let session: SessionRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(colorForType(session.type))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: iconForType(session.type))
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.type.displayName)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(formatDate(session.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.duration) 分钟")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                if session.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForType(_ type: SessionType) -> Color {
        switch type {
        case .breathing: return Color(red: 255/255, green: 203/255, blue: 104/255)
        case .music: return Color(red: 209/255, green: 246/255, blue: 88/255)
        case .meditation: return Color(red: 217/255, green: 242/255, blue: 255/255)
        case .stretch: return .purple
        case .bubble: return .pink
        }
    }
    
    private func iconForType(_ type: SessionType) -> String {
        switch type {
        case .breathing: return "wind"
        case .music: return "music.note"
        case .meditation: return "heart.fill"
        case .stretch: return "figure.walk"
        case .bubble: return "circle.fill"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundColor(.gray)
            Text("暂无数据")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - RelaxStatsStore 扩展方法
extension RelaxStatsStore {
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: "relax_daily_stats")
        UserDefaults.standard.removeObject(forKey: "relax_sessions")
        
        // 发送通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .relaxStatsUpdated, object: nil)
        }
    }
    
    func last30DaysStats() -> [DayStat] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) ?? endDate
        
        var stats: [DayStat] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayMinutes = minutes(on: currentDate)
            stats.append(DayStat(date: currentDate, minutes: dayMinutes))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return stats
    }
    
    func getAllDaysStats() -> [DayStat] {
        // 简化实现，返回最近30天的数据
        return last30DaysStats()
    }
}

// MARK: - 扩展通知名称 (已在RelaxStatsStore.swift中定义)

#Preview {
    ProfileView()
}
