import SwiftUI

@main
struct KUDynamicNotchApp: App {
    // 앱이 켜질 때 AppDelegate를 연결함
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView() // 기본 설정 창 없애기
        }
    }
}

