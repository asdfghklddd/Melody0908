import SwiftUI

struct BreathingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var speed: Double = 1.0
    @State private var isRunning: Bool = true
    @State private var remainingTime: Int = 0
    @State private var sessionCompleted: Bool = false
    let durationMinutes: Int
    
    // 定义颜色常量
    private let backgroundColor = Color(red: 0.816, green: 0.965, blue: 0.341) // #D0F657
    private let lightYellow = Color(red: 1.0, green: 1.0, blue: 0.714) // #FFFFB6
    private let orangeMain = Color(red: 1.0, green: 0.796, blue: 0.408) // #FFCB68
    private let orangeLight = Color(red: 0.988, green: 0.898, blue: 0.737) // #FCE5BC
    
    var body: some View {
        ZStack {
            // 主背景色
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部区域 - 返回按钮
                HStack {
                    BackButton.defaultStyle {
                        dismiss()
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 20)
                
                Spacer(minLength: 40)
                
                // 中心内容区域 - 圆角矩形容器
                VStack(spacing: 0) {
                    // 时间显示区域
                    HStack {
                        Spacer()
                        Text(timeString)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            .background(orangeMain)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                        Spacer()
                    }
                    .padding(.top, 25)
                    
                    // 深呼吸文字区域
                    HStack {
                        Spacer()
                        Text("深呼吸~")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        Spacer()
                    }
                    .padding(.top, 25)
                    
                    // 呼吸圆形动画区域
                    ModernBreathingCircle(
                        durationSeconds: durationMinutes * 60,
                        speed: speed,
                        isRunning: isRunning,
                        orangeMain: orangeMain,
                        orangeLight: orangeLight
                    )
                    .padding(.vertical, 35)
                    
                    Spacer(minLength: 30)
                }
                .background(lightYellow)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
                
                // 底部控制区域
                VStack(spacing: 25) {
                    // 操作按钮区域 - 触控区域提示
                    Text("操作按钮区域")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.top, 10)
                    
                    // 暂停/继续和结束按钮
                    HStack(spacing: 20) {
                        // 暂停/继续按钮
                        Button(action: { isRunning.toggle() }) {
                            Text(isRunning ? "暂停" : "继续")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                        
                        // 结束按钮
                        Button("完成") { 
                            completeSession()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 60)
            }
        }
        .navigationBarHidden(true) // 隐藏原生导航栏，使用自定义返回按钮
        .onAppear {
            remainingTime = durationMinutes * 60
            startTimer()
        }
    }
    
    // 时间格式化
    private var timeString: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // 启动倒计时
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if isRunning && remainingTime > 0 {
                remainingTime -= 1
            } else if remainingTime <= 0 {
                timer.invalidate()
                completeSession()
            }
        }
    }
    
    // 完成会话
    private func completeSession() {
        // 保存会话数据
        RelaxStatsStore.shared.addSession(
            type: .breathing,
            duration: durationMinutes,
            date: Date()
        )
        
        sessionCompleted = true
        
        // 触觉反馈
        #if canImport(UIKit)
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
        #endif
        
        // 返回上一页
        dismiss()
    }
}

// 现代化的呼吸圆形组件
struct ModernBreathingCircle: View {
    let durationSeconds: Int
    let speed: Double
    let isRunning: Bool
    let orangeMain: Color
    let orangeLight: Color
    
    @State private var scale1: CGFloat = 0.7
    @State private var scale2: CGFloat = 0.85
    @State private var scale3: CGFloat = 0.95
    @State private var opacity: Double = 0.8
    
    var body: some View {
        ZStack {
            // 最外层圆环 - 浅橙色
            Circle()
                .fill(orangeLight.opacity(0.2))
                .frame(width: 320, height: 320)
                .scaleEffect(scale3)
            
            // 第二层圆环 - 中等橙色
            Circle()
                .fill(orangeLight.opacity(0.4))
                .frame(width: 260, height: 260)
                .scaleEffect(scale2)
            
            // 第三层圆环 - 深橙色
            Circle()
                .fill(orangeLight.opacity(0.6))
                .frame(width: 210, height: 210)
                .scaleEffect(scale1)
            
            // 主要动画圆 - 渐变填充
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            orangeMain.opacity(0.9),
                            orangeMain.opacity(0.6),
                            orangeLight.opacity(0.3)
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 85
                    )
                )
                .frame(width: 170, height: 170)
                .scaleEffect(scale1)
            
            // 中心核心圆
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            orangeMain,
                            orangeMain.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 130, height: 130)
                .scaleEffect(scale1 * 0.8)
            
            // 橙色呼吸指示环（由蓝色改为橙色）
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            orangeMain.opacity(0.9),
                            orangeLight.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 150, height: 150)
                .scaleEffect(scale1 * 0.9)
            
            // 内层高亮指示
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: 120, height: 120)
                .scaleEffect(scale1 * 0.75)
        }
        .opacity(opacity)
        .onAppear {
            startBreathingAnimation()
        }
        .onChange(of: isRunning) { newValue in
            if newValue {
                startBreathingAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func startBreathingAnimation() {
        let breathingDuration = max(2.0, 4.5 / speed)
        
        if isRunning {
            // 主呼吸动画 - 最显著的缩放
            withAnimation(.easeInOut(duration: breathingDuration).repeatForever(autoreverses: true)) {
                scale1 = 1.15
            }
            
            // 次级动画 - 稍微不同的节奏
            withAnimation(.easeInOut(duration: breathingDuration * 1.2).repeatForever(autoreverses: true)) {
                scale2 = 1.05
            }
            
            // 外围环动画 - 最轻微的变化
            withAnimation(.easeInOut(duration: breathingDuration * 0.8).repeatForever(autoreverses: true)) {
                scale3 = 1.02
            }
            
            // 透明度动画 - 增加呼吸感
            withAnimation(.easeInOut(duration: breathingDuration * 0.5).repeatForever(autoreverses: true)) {
                opacity = 1.0
            }
        }
    }
    
    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            scale1 = 0.7
            scale2 = 0.85
            scale3 = 0.95
            opacity = 0.8
        }
    }
} 
