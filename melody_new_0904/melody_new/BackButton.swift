import SwiftUI

// MARK: - 统一返回按钮组件
// 采用个人中心的设计风格，支持自定义配置
struct BackButton: View {
    // MARK: - 自定义配置选项
    let action: () -> Void
    var iconName: String = "chevron.left"
    var iconColor: Color = .orange
    var backgroundColor: Color = .white
    var shadowRadius: CGFloat = 2
    var shadowColor: Color = .black.opacity(0.1)
    var buttonSize: CGFloat = 40  // 按钮的大小
    var iconSize: Font = .title2
    
    // MARK: - 预设配置
    // 默认配置（与个人中心一致）
    static func defaultStyle(action: @escaping () -> Void) -> BackButton {
        BackButton(action: action)
    }
    
    // 大尺寸配置
    static func large(action: @escaping () -> Void) -> BackButton {
        BackButton(
            action: action,
            buttonSize: 48,
            iconSize: .title
        )
    }
    
    // 小尺寸配置
    static func small(action: @escaping () -> Void) -> BackButton {
        BackButton(
            action: action,
            buttonSize: 32,
            iconSize: .body
        )
    }
    
    // 深色主题配置
    static func dark(action: @escaping () -> Void) -> BackButton {
        BackButton(
            action: action,
            iconColor: .white,
            backgroundColor: .black.opacity(0.8)
        )
    }
    
    // 自定义颜色配置
    static func customColor(
        action: @escaping () -> Void,
        iconColor: Color,
        backgroundColor: Color
    ) -> BackButton {
        BackButton(
            action: action,
            iconColor: iconColor,
            backgroundColor: backgroundColor
        )
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(iconSize)
                .foregroundColor(iconColor)
                .padding(8)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius,
                    x: 0,
                    y: shadowRadius / 2
                )
        }
        .frame(width: buttonSize, height: buttonSize)
        .contentShape(Circle()) // 确保整个圆形区域都可点击
    }
}

// MARK: - 便捷的Dismiss版本
// 使用环境dismiss的版本，更便于使用
struct DismissBackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var iconName: String = "chevron.left"
    var iconColor: Color = .orange
    var backgroundColor: Color = .white
    var shadowRadius: CGFloat = 2
    var shadowColor: Color = .black.opacity(0.1)
    var buttonSize: CGFloat = 40
    var iconSize: Font = .title2
    
    // 预设配置方法
    static var defaultStyle: DismissBackButton {
        DismissBackButton()
    }
    
    static var large: DismissBackButton {
        DismissBackButton(buttonSize: 48, iconSize: .title)
    }
    
    static var small: DismissBackButton {
        DismissBackButton(buttonSize: 32, iconSize: .body)
    }
    
    static var dark: DismissBackButton {
        DismissBackButton(iconColor: .white, backgroundColor: .black.opacity(0.8))
    }
    
    static func customColor(iconColor: Color, backgroundColor: Color) -> DismissBackButton {
        DismissBackButton(iconColor: iconColor, backgroundColor: backgroundColor)
    }
    
    var body: some View {
        BackButton(
            action: { dismiss() },
            iconName: iconName,
            iconColor: iconColor,
            backgroundColor: backgroundColor,
            shadowRadius: shadowRadius,
            shadowColor: shadowColor,
            buttonSize: buttonSize,
            iconSize: iconSize
        )
    }
}

// MARK: - 预览
#Preview("默认样式") {
    VStack(spacing: 20) {
        BackButton.defaultStyle {
            print("返回")
        }
        
        BackButton.large {
            print("大按钮")
        }
        
        BackButton.small {
            print("小按钮")
        }
        
        BackButton.dark {
            print("深色按钮")
        }
        
        BackButton.customColor(
            action: { print("自定义") },
            iconColor: .white,
            backgroundColor: .green
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Dismiss版本") {
    NavigationView {
        VStack {
            DismissBackButton.defaultStyle
            DismissBackButton.large
            DismissBackButton.small
            DismissBackButton.dark
        }
        .padding()
    }
}
