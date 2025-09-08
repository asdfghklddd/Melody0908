import SwiftUI
import AVKit

struct SessionEndView: View {
    @Environment(\.dismiss) var dismiss
    
    // 视频播放器
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            // 背景颜色
            Color(red: 1, green: 0.97, blue: 0.45)
                .ignoresSafeArea()
            
            VStack {
                // 顶部区域 - 返回按钮
                HStack {
                    BackButton.defaultStyle {
                        dismiss()
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 20)
                
                Spacer()
                
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
                
                Spacer()
                
                // 中间的视频播放器
                if let player = player {
                    VideoPlayerContainer(player: player)
                        .frame(width: 300, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                } else {
                    Text("无法加载视频")
                        .foregroundColor(.gray)
                        .frame(width: 300, height: 300)
                }
                
                Spacer()
                
                // 底部按钮
                Button(action: {
                    // 先关闭当前结束页
                    dismiss()
                    // 再异步再退一层，确保回到主页
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        dismiss()
                    }
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
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true) // 隐藏原生导航栏
        .onAppear {
            setupPlayer()
        }
    }
    
    // 设置视频播放器
    private func setupPlayer() {
        // 确保你的视频文件 (dog.mov) 已经添加到项目中
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

// 使用 UIViewControllerRepresentable 来控制填充模式
struct VideoPlayerContainer: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill // 填充整个区域，没有黑边
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// 预览
struct SessionEndView_Previews: PreviewProvider {
    static var previews: some View {
        // 为了预览 NavigationLink 的效果，将视图嵌入到 NavigationView 中
        NavigationView {
            SessionEndView()
        }
    }
}
