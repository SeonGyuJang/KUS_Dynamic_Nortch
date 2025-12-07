import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatWindow: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. 윈도우 크기 및 스타일 설정
        // 노치가 확장될 때를 대비해 미리 넉넉하게(600x450) 잡음
        let windowSize = NSSize(width: 600, height: 450)
        let screenSize = NSScreen.main?.frame.size ?? .zero
        
        // 화면 정중앙 상단 좌표 계산
        let xPos = (screenSize.width - windowSize.width) / 2
        let yPos = screenSize.height - windowSize.height + 10 // 상단에 바짝 붙임 (+10은 노치 숨김 보정)
        
        let panel = NSPanel(
            contentRect: NSRect(origin: NSPoint(x: xPos, y: yPos), size: windowSize),
            styleMask: [.borderless, .nonactivatingPanel], // 테두리 없음
            backing: .buffered, defer: false
        )
        
        // 2. 투명하게 만들기
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .mainMenu + 1 // 메뉴바보다 위에
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 3. SwiftUI 뷰 연결
        panel.contentView = NSHostingView(rootView: ContentView())
        
        self.floatWindow = panel
        panel.orderFrontRegardless() // 화면 맨 앞으로 강제 소환
    }
}
