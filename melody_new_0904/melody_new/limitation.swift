import SwiftUI
import EventKit

struct EntryView: View {
    @State private var granted = false
    @State private var checked = false
    @State private var showAlert = false  // 控制是否显示弹窗
    
    let eventStore = EKEventStore()
    
    var body: some View {
        Group {
            if granted {
                // ✅ 已授权 → 进入主页面
                RelaxPlannerView()
            } else {
                // ❌ 未授权 → 请求权限页面
                VStack(spacing: 20) {
                    Text("需要访问日历权限")
                        .font(.title2)
                        .padding()
                    
                    Button("获取日历权限") {
                        requestCalendarAccess()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("需要日历权限"),
                        message: Text("请在设置中启用日历权限，以便使用完整功能"),
                        primaryButton: .default(Text("去设置")) {
                            openAppSettings()
                        },
                        secondaryButton: .cancel(Text("取消"))
                    )
                }
            }
        }
        .onAppear {
            checkCalendarAccess()
        }
    }
    
    // 检查权限
    private func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            granted = true
        default:
            granted = false
        }
        checked = true
    }
    
    // 请求权限
    private func requestCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            // 首次请求
            eventStore.requestAccess(to: .event) { accessGranted, error in
                DispatchQueue.main.async {
                    if accessGranted {
                        granted = true
                    } else {
                        showAlert = true
                    }
                }
            }
        case .denied, .restricted:
            // 用户拒绝过 → 弹窗提示去设置
            showAlert = true
        default:
            break
        }
    }
    
    // 跳转到系统设置
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

#Preview {
    EntryView()
}
