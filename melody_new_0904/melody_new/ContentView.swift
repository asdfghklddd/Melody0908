import SwiftUI

struct ContentView: View {
    @State private var goToEntry = false   // ← 用状态控制跳转

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color(red: 1.0, green: 0.953, blue: 0.847) // #FFF3D8
                    .ignoresSafeArea(.all, edges: .all)
                
                VStack(spacing: 0) {
                    // 顶部区域
                    topSection
                    
                    // 中部彩色卡片区域
                    Spacer()
                    colorfulCardsSection
                    Spacer()
                    
                    // 底部统计入口区域
                    bottomSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $goToEntry) {
                MelodyAppView()
            }
        }
    }
    
    // 获取当前星期几
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
    
    // MARK: - 顶部区域
    private var topSection: some View {
        VStack(spacing: 20) {
            // 动态显示当前星期几
            HStack {
                Text(weekdayString)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // 右上角头像
                Circle()
                    .fill(Color.orange)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("👤")
                            .font(.system(size: 20))
                    )
            }
            
            // 绿色问候卡片
            HStack(spacing: 12) {
                // 左侧头像
                Circle()
                    .fill(Color.orange)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("😊")
                            .font(.system(size: 24))
                    )
                
                Text("晚上好呀 我是Melody (*^_^*)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.green.opacity(0.7))
            )
        }
    }
    
    // MARK: - 彩色卡片区域
    private var colorfulCardsSection: some View {
        ZStack {
            // 卡片1 - 青色
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cyan)
                .frame(width: 120, height: 180)
                .rotationEffect(.degrees(-15))
                .offset(x: -80, y: -20)
            
            // 卡片2 - 绿色
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.green)
                .frame(width: 120, height: 180)
                .rotationEffect(.degrees(-5))
                .offset(x: -30, y: -10)
            
            // 卡片3 - 橙色
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange)
                .frame(width: 120, height: 180)
                .rotationEffect(.degrees(5))
                .offset(x: 20, y: 0)
            
            // 卡片4 - 蓝色
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue)
                .frame(width: 120, height: 180)
                .rotationEffect(.degrees(15))
                .offset(x: 70, y: 10)
            
            // 卡片5 - 红色
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.red)
                .frame(width: 120, height: 180)
                .rotationEffect(.degrees(25))
                .offset(x: 120, y: 20)
        }
        .frame(height: 200)
        .onTapGesture {
            goToEntry = true
        }
    }
    
    // MARK: - 底部统计入口区域
    private var bottomSection: some View {
        VStack(spacing: 20) {
            // 时钟和统计入口
            HStack(spacing: 15) {
                // 时钟图标
                ZStack {
                    Circle()
                        .stroke(Color.orange, lineWidth: 3)
                        .frame(width: 60, height: 60)
                    
                    // 时钟指针
                    VStack {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 2, height: 15)
                            .offset(y: -7)
                        
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 2, height: 20)
                            .rotationEffect(.degrees(90))
                            .offset(y: 5)
                    }
                    
                    // 时钟刻度
                    ForEach(0..<12) { i in
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 1, height: 8)
                            .offset(y: -22)
                            .rotationEffect(.degrees(Double(i) * 30))
                    }
                }
                
                
                
                Spacer()
                
                // 右侧头像
                ZStack {
                    
                }
            }
            
            // 底部导航点
            HStack(spacing: 15) {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 12, height: 12)
                
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 12, height: 12)
                
                Spacer()
                
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 12, height: 12)
                
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.bottom, 20)
    }
}

// 可重用的卡片组件
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
}
