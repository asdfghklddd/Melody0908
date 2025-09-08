import SwiftUI
import AVKit
import AVFoundation

// 音乐游戏状态枚举
enum MusicGameState {
    case initial    // 初始状态，显示开始页面背景
    case playing    // 游戏进行中，显示小路背景
    case completed  // 游戏结束
}

struct MusicSessionView: View {
    // 用于返回上一页
    @Environment(\.dismiss) private var dismiss
    
    // 从 MainView 传入的持续时间
    let durationMinutes: Int
    
    // 游戏状态管理
    @State private var gameState: MusicGameState = .initial
    @State private var sessionCompleted: Bool = false
    @State private var timeRemaining: Int = 0
    @State private var showStartButton: Bool = true
    @State private var showGameEndDialog: Bool = false
    @State private var showCelebrationView: Bool = false
    
    // 音频播放器
    @State private var audioPlayer: AVAudioPlayer?
    
    // 定时器
    private let gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // 动态背景
            Group {
                if gameState == .initial {
                    // 开始页面背景
                    Image("music_start_bg")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                } else if gameState == .playing {
                    // 游戏进行中的背景（小路背景）
                    Image("music_playing_bg")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                }
            }
            .animation(.easeInOut(duration: 0.8), value: gameState)
            
            // 顶部的返回按钮和游戏信息
            VStack {
                HStack {
                    // 使用统一的返回按钮组件
                    BackButton.defaultStyle {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    // 游戏进行时显示时间信息
                    if gameState == .playing {
                        VStack(alignment: .trailing) {
                            Text("剩余时间")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("\(timeRemaining)s")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
            }
            
            // 中间内容区域
            VStack {
                Spacer()
                
                if gameState == .initial {
                    // 初始状态下的音符装饰（如果需要的话）
                    ZStack {
                        NoteView(x: 100, y: 50, rotation: 10, scale: 1.2)
                        NoteView(x: -80, y: 120, rotation: -15, scale: 1.0)
                        NoteView(x: 150, y: 200, rotation: 5, scale: 0.9)
                        NoteView(x: -120, y: 250, rotation: 20, scale: 0.8)
                        NoteView(x: 50, y: 300, rotation: -10, scale: 0.7)
                    }
                    .opacity(0.6) // 让音符稍微透明一些，不遮挡背景
                    .padding(.bottom, -150)
                }
                
                Spacer()
            }
            
            // 底部按钮区域
            VStack {
                Spacer()
                
                if gameState == .initial && showStartButton {
                    // START按钮
                    Button(action: {
                        startMusicSession()
                    }) {
                        Text("START")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                            .frame(width: 180, height: 180)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
                            )
                    }
                    .scaleEffect(showStartButton ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showStartButton)
                }
                
                Spacer().frame(height: 80)
            }
            
            // 游戏结束弹窗
            if showGameEndDialog {
                VStack(spacing: 20) {
                    Text("音乐会话结束!")
                        .font(.title)
                        .foregroundColor(.black)
                    
                    Text("感谢您的聆听")
                        .font(.title2)
                        .foregroundColor(.black)
                    
                    HStack(spacing: 20) {
                        Button("重新开始") {
                            resetGame()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Button("完成") {
                            completeSessionWithCelebration()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(52)
                .background(Color.white.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 15)
                .scaleEffect(showGameEndDialog ? 1.0 : 0.8)
                .opacity(showGameEndDialog ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showGameEndDialog)
            }
            
            // 庆祝视图
            if showCelebrationView {
                CelebrationView {
                    // 庆祝完成后返回主页
                    dismiss()
                }
            }
        }
        .navigationBarHidden(true) // 隐藏原生导航栏，使用自定义返回按钮
        .onDisappear {
            stopMusic()
        }
        .onReceive(gameTimer) { _ in
            if gameState == .playing && timeRemaining > 0 {
                timeRemaining -= 1
                if timeRemaining <= 0 {
                    // 时间到，自动结束并记录
                    gameState = .completed
                    showGameEndDialog = true
                    completeSessionIfNeeded()
                    stopMusic()
                }
            }
        }
    }
    
    // MARK: - 私有方法
    
    // 开始音乐会话
    private func startMusicSession() {
        // 按钮消失动画
        withAnimation(.easeOut(duration: 0.3)) {
            showStartButton = false
        }
        
        // 开始播放音乐
        playMusic()
        
        // 延迟切换背景和游戏状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                gameState = .playing
                timeRemaining = durationMinutes * 60 // 转换为秒
            }
        }
        
        // 触觉反馈
        #if canImport(UIKit)
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
        #endif
    }
    
    // 播放音乐（将文件名替换为你的 mp3 名称）
    private func playMusic() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("⚠️ 无法设置音频会话: \(error)")
        }
        
        if let dataAsset = NSDataAsset(name: "music") {
            do {
                let player = try AVAudioPlayer(data: dataAsset.data)
                player.numberOfLoops = 0
                player.prepareToPlay()
                player.play()
                self.audioPlayer = player
                return
            } catch {
                print("❌ 通过资产播放音乐失败: \(error)")
            }
        }
        
        if let url = Bundle.main.url(forResource: "music", withExtension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = 0
                player.prepareToPlay()
                player.play()
                self.audioPlayer = player
                return
            } catch {
                print("❌ 通过文件播放音乐失败: \(error)")
            }
        }
        
        print("❌ 未找到音乐资源 'music'。请确认 mp3 已放入 Assets 或 Bundle。")
    }
    
    // 停止音乐
    private func stopMusic() {
        audioPlayer?.stop()
        audioPlayer = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            // 忽略停止会话错误
        }
    }
    
    // 完成会话
    private func completeSession() {
        completeSessionIfNeeded()
        gameState = .completed
        showGameEndDialog = true
        stopMusic()
        
        // 触觉反馈
        #if canImport(UIKit)
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
        #endif
    }
    
    private func completeSessionIfNeeded() {
        guard !sessionCompleted else { return }
        sessionCompleted = true
        RelaxStatsStore.shared.addSession(
            type: .music,
            duration: max(1, durationMinutes),
            date: Date()
        )
    }
    
    // 完成会话并显示庆祝
    private func completeSessionWithCelebration() {
        // 关闭弹窗
        showGameEndDialog = false
        
        // 显示庆祝视图
        withAnimation(.easeInOut(duration: 0.5)) {
            completeSessionIfNeeded()
            showCelebrationView = true
        }
    }
    
    // 重置游戏
    private func resetGame() {
        showGameEndDialog = false
        showCelebrationView = false
        gameState = .initial
        showStartButton = true
        timeRemaining = 0
        sessionCompleted = false
        stopMusic()
    }
}

// 单个音符视图
struct NoteView: View {
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    
    var body: some View {
        Image(systemName: "music.note")
            .resizable()
            .scaledToFit()
            .frame(width: 25 * scale, height: 40 * scale)
            .foregroundColor(.black)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }
}

// 单个山脉视图
struct MountainView: View {
    let width: CGFloat
    let height: CGFloat
    let isCentral: Bool
    
    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                // 山体
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addQuadCurve(to: CGPoint(x: width, y: height), control: CGPoint(x: width / 2, y: 0))
                }
                .fill(Color(red: 0.2, green: 0.6, blue: 0.2)) // 深绿色
                .frame(width: width, height: height)
                
                // 山顶
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height - 10))
                    path.addQuadCurve(to: CGPoint(x: width, y: height - 10), control: CGPoint(x: width / 2, y: isCentral ? 50 : 30))
                }
                .fill(Color(red: 0.3, green: 0.8, blue: 0.3)) // 浅绿色
                .frame(width: width, height: height)
            }
        }
    }
}

// 庆祝视图组件
struct CelebrationView: View {
    @State private var player: AVPlayer?
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // 背景色
            Color(red: 1, green: 0.97, blue: 0.45)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 顶部标题和描述
                VStack(spacing: 8) {
                    Text("Yeah")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("请继续专注")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("迎接下一个")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                    + Text("melody")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                    + Text("时刻")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                // 中间的视频播放器
                if let player = player {
                    VideoPlayerContainer(player: player)
                        .frame(width: 300, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 300, height: 300)
                        .overlay(
                            Text("加载中...")
                                .foregroundColor(.gray)
                        )
                }
                
                // 底部按钮
                Button(action: {
                    onComplete()
                }) {
                    Text("返回主页")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.orange)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                        )
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 50)
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    // 设置视频播放器
    private func setupPlayer() {
        guard let assetURL = Bundle.main.url(forResource: "dog", withExtension: "mov") else {
            print("❌ 视频文件未找到")
            return
        }
        
        let playerItem = AVPlayerItem(url: assetURL)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // 自动播放一遍（不循环）
        newPlayer.play()
        
        self.player = newPlayer
    }
}

// 预览
struct MusicSessionView_Previews: PreviewProvider {
    static var previews: some View {
        MusicSessionView(durationMinutes: 5)
    }
}
