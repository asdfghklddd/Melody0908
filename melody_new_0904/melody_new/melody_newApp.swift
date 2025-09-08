//
//  melody_newApp.swift
//  melody_new
//
//  Created by Tutu on 2025/8/2.
//

import SwiftUI
import AVKit
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

@main
struct melody_newApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var showSplash = true
    @State private var showOnboarding = false
    @State private var showMainApp = false
    
    // 检查是否为首次启动
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            // 主应用视图
            if showMainApp {
                MelodyAppView()
                    .zIndex(0)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            
            // Onboarding视图
            if showOnboarding {
                OnboardingView {
                    // onboarding完成回调
                    completeOnboarding()
                }
                .zIndex(1)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            // 启动动画
            if showSplash {
                SplashView(onFinished: {
                    withAnimation(.easeOut(duration: 0.8)) {
                        showSplash = false
                        if hasCompletedOnboarding {
                            showMainApp = true
                        } else {
                            showOnboarding = true
                        }
                    }
                })
                    .zIndex(2)
                    .transition(.opacity)
            }
        }
        .background(Color(red: 1.0, green: 0.953, blue: 0.847)) // #FFF3D8
        .ignoresSafeArea(.all, edges: .all)
        
        
    }
    
    // MARK: - 完成Onboarding
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            showOnboarding = false
            showMainApp = true
        }
    }
}

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var didNotifyFinish: Bool = false
    let onFinished: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center, spacing: 24) {
                // 顶部：Logo 与中文标语、标题（居中，填充上方 1/3）
                VStack(alignment: .center, spacing: 14) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 13.2, style: .continuous))
                        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
                        .blur(radius: 0.6)
                    Text("“专注每一刻，轻松每一刻”")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color.gray.opacity(0.35))
                        .frame(width: 200, height: 4)
                    Text("Melody · 乐伴")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: geo.size.height * 0.33, alignment: .center)
                .padding(.top, 40)
                .padding(.horizontal, 28)
                
                Spacer(minLength: 12)
                
                // 中下方：加载动画视频，尽可能填充
                Group {
                    #if os(iOS)
                    SplashDataAssetVideoView(assetName: "loading_animation") {
                        if !didNotifyFinish { didNotifyFinish = true; onFinished() }
                    }
                    .frame(width: geo.size.width - 48,
                           height: min(geo.size.height * 0.45, 420))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
                    #else
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.6))
                        .frame(width: geo.size.width - 48,
                               height: min(geo.size.height * 0.45, 420))
                    #endif
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .offset(y: -40)
                .padding(.bottom, 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    logoScale = 1.0
                }
                withAnimation(.easeIn(duration: 0.4)) {
                    logoOpacity = 1.0
                }
            }
        }
        .background(Color(red: 1, green: 0.95, blue: 0.85))
        .ignoresSafeArea(.all, edges: .all)
    }
}

// MARK: - Splash 加载动画（使用与 StretchSession 相同的 AVPlayerLayer 方案）
#if os(iOS)
fileprivate struct SplashDataAssetVideoView: UIViewRepresentable {
    let assetName: String
    let onFinished: () -> Void

    func makeUIView(context: Context) -> SplashVideoPlayerUIView {
        let view = SplashVideoPlayerUIView()
        if let player = loadPlayer() {
            view.configure(player: player, onFinished: onFinished)
        }
        return view
    }

    func updateUIView(_ uiView: SplashVideoPlayerUIView, context: Context) {}

    private func loadPlayer() -> AVPlayer? {
        // 优先从 Assets data set 读取
        if let dataAsset = NSDataAsset(name: assetName) {
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(assetName).mov")
            do {
                try dataAsset.data.write(to: tmpURL)
                return AVPlayer(url: tmpURL)
            } catch {
                // 回退 mp4 扩展名
                let mp4URL = FileManager.default.temporaryDirectory.appendingPathComponent("\(assetName).mp4")
                do { try dataAsset.data.write(to: mp4URL); return AVPlayer(url: mp4URL) } catch { }
            }
        }
        // 回退到 bundle
        if let url = Bundle.main.url(forResource: assetName, withExtension: "mov") { return AVPlayer(url: url) }
        if let url = Bundle.main.url(forResource: assetName, withExtension: "mp4") { return AVPlayer(url: url) }
        return nil
    }
}

fileprivate class SplashVideoPlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var onFinished: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(playerLayer)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(playerLayer)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    func configure(player: AVPlayer, onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        player.isMuted = true
        NotificationCenter.default.addObserver(self, selector: #selector(didFinish), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        player.play()
    }
    @objc private func didFinish() { onFinished?() }
}
#endif

// 本地播放器容器，避免跨文件依赖导致的作用域问题
#if os(iOS)
struct SplashVideoPlayerContainer: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
#endif

// （已移除 KVO 方案，直接播放以确保加载页动画可靠播放）
