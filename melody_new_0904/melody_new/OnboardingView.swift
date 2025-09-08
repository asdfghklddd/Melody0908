import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isCompleted = false
    @State private var page1TextShown = false
    @State private var page2TextShown = false
    @State private var page4TextShown = false
    @State private var page3TextShown = false
    
    // 回调闭包，完成时通知父视图
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            if !isCompleted {
                // 根据当前页面显示不同的页面布局
                switch currentPage {
                case 0:
                    OnboardingPage1(textRevealed: $page1TextShown)
                case 1:
                    OnboardingPage2(textRevealed: $page2TextShown)
                case 2:
                    OnboardingPage3(textRevealed: $page3TextShown)
                case 3:
                    OnboardingPage4(textRevealed: $page4TextShown)
                default:
                    OnboardingPage1(textRevealed: $page1TextShown)
                }
                
                // 页面指示器 - 底部横排居中
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? 
                                      Color.orange : Color.orange.opacity(0.3))
                                .frame(width: index == currentPage ? 12 : 8, 
                                       height: index == currentPage ? 12 : 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), 
                                          value: currentPage)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onTapGesture {
            if currentPage == 0 && !page1TextShown {
                withAnimation(.interpolatingSpring(stiffness: 140, damping: 12)) {
                    page1TextShown = true
                }
            } else if currentPage == 1 && !page2TextShown {
                withAnimation(.interpolatingSpring(stiffness: 140, damping: 12)) {
                    page2TextShown = true
                }
            } else if currentPage == 2 && !page3TextShown {
                withAnimation(.interpolatingSpring(stiffness: 140, damping: 12)) {
                    page3TextShown = true
                }
            } else if currentPage == 3 && !page4TextShown {
                withAnimation(.interpolatingSpring(stiffness: 140, damping: 12)) {
                    page4TextShown = true
                }
            } else {
                nextPage()
            }
        }
        .ignoresSafeArea()
        .transition(.asymmetric(
            insertion: .opacity,
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - 功能函数
    private func nextPage() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if currentPage < 3 {
                currentPage += 1
            } else {
                // 完成onboarding
                isCompleted = true
                
                // 延迟一点时间让动画播放完成，然后调用回调
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - 第一个页面：日历读取，日程管理
struct OnboardingPage1: View {
    @Binding var textRevealed: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片
                Image("onboarding1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                VStack {
                    // 顶部留白（原LOGO位置）
                    Spacer().frame(height: 60)

                    Spacer()
                    
                    // 中间的介绍文字（点击后从右上角掉入）
                    VStack(spacing: 12) {
                        Text("日历读取")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                        Text("日程管理")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 30)
                    // 初始位于右上角视野外，点击后以弹簧动画掉入，并整体上移避免与插画重叠
                    .offset(x: textRevealed ? 0 : geometry.size.width * 0.6,
                            y: textRevealed ? -60 : -geometry.size.height * 0.6)
                    .opacity(textRevealed ? 1 : 0)
                    .rotationEffect(.degrees(textRevealed ? 0 : 10))
                    .animation(.interpolatingSpring(stiffness: 140, damping: 12), value: textRevealed)
                    
                    Spacer()
                    Spacer()
                }
            }
        }
    }
}

// MARK: - 第二个页面：AI分析，主动推荐
struct OnboardingPage2: View {
    @Binding var textRevealed: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片
                Image("onboarding2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                VStack {
                    Spacer()
                    
                    // 中间介绍文字（点击后从顶部掉落，最终停在底部上方约25%处）
                    VStack(spacing: 12) {
                        Text("AI分析")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                        Text("主动推荐")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 30)
                    .offset(x: 0,
                            y: textRevealed ? geometry.size.height * 0.25 - 20 : -geometry.size.height)
                    .opacity(textRevealed ? 1 : 0)
                    .rotationEffect(.degrees(textRevealed ? 0 : -6))
                    .animation(.interpolatingSpring(stiffness: 140, damping: 12), value: textRevealed)
                    
                    Spacer()
                    
                    // 底部留白（原LOGO位置）
                    Spacer().frame(height: 40)
                }
            }
        }
    }
}

// MARK: - 第三个页面：多种运动，自在放松
struct OnboardingPage3: View {
    @Binding var textRevealed: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片
                Image("onboarding3")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                VStack {
                    // 顶部留白（原LOGO位置）
                    Spacer().frame(height: 60)

                    Spacer()

                    // 介绍文字：点击后从顶部坠落，最终停在页面下方约20%
                    VStack(spacing: 12) {
                        Text("多种运动")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                        Text("自在放松")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 30)
                    .offset(x: 0,
                            y: textRevealed ? geometry.size.height * 0.20 : -geometry.size.height)
                    .opacity(textRevealed ? 1 : 0)
                    .rotationEffect(.degrees(textRevealed ? 0 : -6))
                    .animation(.interpolatingSpring(stiffness: 140, damping: 12), value: textRevealed)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - 第四个页面：数据统计，可视成长
struct OnboardingPage4: View {
    @Binding var textRevealed: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片
                Image("onboarding4")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                VStack {
                    // 顶部留白（原LOGO位置）
                    Spacer().frame(height: 60)
                    
                    Spacer()
                    
                    // 介绍文字：点击后自顶部坠落，停在页面下方约20%
                    VStack(spacing: 12) {
                        Text("数据统计")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                        Text("可视成长")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 30)
                    .offset(x: 0,
                            y: textRevealed ? geometry.size.height * 0.20 : -geometry.size.height)
                    .opacity(textRevealed ? 1 : 0)
                    .rotationEffect(.degrees(textRevealed ? 0 : -6))
                    .animation(.interpolatingSpring(stiffness: 140, damping: 12), value: textRevealed)
                    
                    Spacer()
                    Spacer()
                }
            }
        }
    }
}

// MARK: - 预览
#Preview {
    OnboardingView {
        print("Onboarding completed!")
    }
}