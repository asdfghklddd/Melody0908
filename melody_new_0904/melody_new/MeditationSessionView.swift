import SwiftUI

struct MeditationSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStage: Int = 0 // 0-4 对应5个生长阶段
    @State private var isAnimating: Bool = false
    @State private var sessionStart: Date = Date()
    @State private var hasRecorded: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // 顶部导航栏
            HStack(alignment: .center, spacing: 0) {
                // 使用统一的返回按钮组件
                BackButton.defaultStyle {
                    dismiss()
                }
                .padding(.leading, 20)
                
                Spacer()
                
                Text("专注冥想")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                // 占位，保持标题居中
                Spacer()
                    .frame(width: 40) // 与返回按钮宽度相同，保持标题居中
            }
            .padding(0)
            .frame(width: 411, height: 85, alignment: .center)
            .background(Color(red: 0.9, green: 0.95, blue: 0.9))
            .zIndex(2) // 确保顶部栏在交互层级之上
            
            // 植物生长区域
            ZStack {
                // 背景
                Color(red: 0.95, green: 0.98, blue: 0.95)
                    .ignoresSafeArea()
                
                // 植物生长动画
                plantGrowthView
                
                // 点击区域
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            if currentStage < 4 {
                                currentStage += 1
                            } else {
                                currentStage = 0 // 重新开始
                            }
                        }
                    }
            }
            .frame(width: 411, height: 789) // 874 - 85 = 789
        }
        .padding(0)
        .frame(width: 411, height: 874, alignment: .center)
        .navigationBarHidden(true)
        // 底部完成按钮
        .overlay(alignment: .bottom) {
            bottomCompleteButton
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                isAnimating = true
            }
            sessionStart = Date()
        }
    }
    
    @ViewBuilder
    private var plantGrowthView: some View {
        ZStack {
            switch currentStage {
            case 0:
                // 第一阶段：种子
                stage1View
            case 1:
                // 第二阶段：发芽
                stage2View
            case 2:
                // 第三阶段：幼苗
                stage3View
            case 3:
                // 第四阶段：成长
                stage4View
            case 4:
                // 第五阶段：成熟
                stage5View
            default:
                stage1View
            }
        }
        .animation(.easeInOut(duration: 1.0), value: currentStage)
    }

    // 底部完成按钮
    private var bottomCompleteButton: some View {
        HStack {
            Spacer()
            Button("完成冥想") {
                completeAndDismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer()
        }
        .padding(.bottom, 24)
    }

    private func completeAndDismiss() {
        if !hasRecorded {
            hasRecorded = true
            let minutes = max(1, Int(Date().timeIntervalSince(sessionStart) / 60))
            RelaxStatsStore.shared.addSession(type: .meditation, duration: minutes, date: Date())
        }
        // 触觉反馈
        #if canImport(UIKit)
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        #endif
        dismiss()
    }
    
    // 第一阶段：种子
    private var stage1View: some View {
        GeometryReader { geometry in
            Image("seed1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.7)
        }
    }
    
    // 第二阶段：发芽
    private var stage2View: some View {
        GeometryReader { geometry in
            Image("seed2")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.7)
        }
    }
    
    // 第三阶段：幼苗
    private var stage3View: some View {
        GeometryReader { geometry in
            Image("seed3")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.7)
        }
    }
    
    // 第四阶段：成长
    private var stage4View: some View {
        GeometryReader { geometry in
            Image("seed4")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.7)
        }
    }
    
    // 第五阶段：成熟
    private var stage5View: some View {
        GeometryReader { geometry in
            Image("seed5")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.7)
        }
    }
}

#Preview {
    MeditationSessionView()
} 
