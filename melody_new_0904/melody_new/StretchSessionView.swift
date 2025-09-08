import SwiftUI
import AVKit

struct StretchSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sessionStart: Date = Date()
    @State private var hasRecorded: Bool = false
    
    var body: some View {
        ZStack {
            // 背景色
            Color(red: 0.85, green: 0.97, blue: 0.36) // 亮黄绿色
                .ignoresSafeArea()
            
            VStack {
                // 顶部栏
                HStack(alignment: .center, spacing: 12) {
                    // 返回按钮
                    BackButton.defaultStyle {
                        dismiss()
                    }
                    
                    // 橙色条
                    Text("拉伸")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    // 右边占位，保持布局平衡
                    Spacer()
                        .frame(width: 40)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                Spacer()
                
                // 视频居中播放
                PoseVideoView(assetName: "stretch")
                    .frame(width: 240, height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 6)
                
                Spacer()

                // 完成按钮
                Button(action: { completeAndDismiss() }) {
                    Text("完成拉伸")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true) // 隐藏原生导航栏，使用自定义返回按钮
        .onAppear { sessionStart = Date() }
    }
}

// 记录逻辑
extension StretchSessionView {
    private func completeAndDismiss() {
        if !hasRecorded {
            hasRecorded = true
            let minutes = max(1, Int(Date().timeIntervalSince(sessionStart) / 60))
            RelaxStatsStore.shared.addSession(type: .stretch, duration: minutes, date: Date())
        }
        #if canImport(UIKit)
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        #endif
        dismiss()
    }
}

// 使用 AVPlayerLayer，避免黑边
fileprivate struct PoseVideoView: UIViewRepresentable {
    let assetName: String
    @State private var player: AVPlayer?

    func makeUIView(context: Context) -> VideoPlayerUIView {
        let view = VideoPlayerUIView()
        if let player = loadPlayer() {
            view.configure(player: player)
        }
        return view
    }

    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {}

    private func loadPlayer() -> AVPlayer? {
        guard let dataAsset = NSDataAsset(name: assetName) else {
            print("❌ 找不到 Assets 中名为 \(assetName) 的 dataset")
            return nil
        }
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(assetName).mp4")
        do {
            try dataAsset.data.write(to: tmpURL)
            return AVPlayer(url: tmpURL)
        } catch {
            print("❌ 写入临时文件失败: \(error)")
            return nil
        }
    }
}

// UIView 容器，强制设置 videoGravity
fileprivate class VideoPlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()

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

    func configure(player: AVPlayer) {
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill // 填充，裁掉黑边
        player.isMuted = true
        player.play()

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }
}
