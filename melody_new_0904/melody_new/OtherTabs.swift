import SwiftUI

struct BookmarksView: View {
    var body: some View {
        Text("收藏 / 书签")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 1.0, green: 0.953, blue: 0.847)) // #FFF3D8
            .ignoresSafeArea(.all, edges: .all)
            .foregroundColor(.black)
    }
}

struct DiscoverView: View {
    var body: some View {
        Text("发现")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 1.0, green: 0.953, blue: 0.847)) // #FFF3D8
            .ignoresSafeArea(.all, edges: .all)
            .foregroundColor(.black)
    }
}

struct InsightsPageView: View {
    var body: some View {
        Text("数据洞察")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 1.0, green: 0.953, blue: 0.847)) // #FFF3D8
            .ignoresSafeArea(.all, edges: .all)
            .foregroundColor(.black)
    }
}

struct ProfilePageView: View {
    var body: some View {
        Text("我的")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 1.0, green: 0.953, blue: 0.847)) // #FFF3D8
            .ignoresSafeArea(.all, edges: .all)
            .foregroundColor(.black)
    }
} 