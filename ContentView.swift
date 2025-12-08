import SwiftUI

// 탭 종류 정의
enum NotchTab: String, CaseIterable {
    case app = "App"
    case tray = "트레이"
    case ku = "고려대학교"
}

struct ContentView: View {
    @StateObject var mediaObserver = MediaObserver()
    @State private var isExpanded = false
    @State private var isHovering = false
    @State private var selectedTab: NotchTab = .app
    
    // 자연스러운 형태 변형을 위한 네임스페이스
    @Namespace private var animation
    
    // NotchNook 스타일의 확장 애니메이션 - 더 유기적이고 자연스럽게
    var expandAnimation: Animation {
        .interpolatingSpring(mass: 1.0, stiffness: 180, damping: 20, initialVelocity: 0)
    }

    var collapseAnimation: Animation {
        .interpolatingSpring(mass: 0.8, stiffness: 200, damping: 22, initialVelocity: 0)
    }

    var contentFadeAnimation: Animation {
        .easeOut(duration: 0.25)
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Spacer()
            
            // 메인 컨테이너
            ZStack(alignment: .top) {
                // ---------------------------------------------------------
                // 1. 배경 레이어 (검은색 유지)
                // ---------------------------------------------------------
                Group {
                    if isExpanded {
                        // 확장 상태: 둥근 사각형
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(Color.black) // 배경은 무조건 검은색
                            .matchedGeometryEffect(id: "Background", in: animation)
                            .frame(width: 500, height: 280)
                            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
                    } else {
                        // 축소 상태: 알약 모양
                        if mediaObserver.isPlaying {
                            Capsule()
                                .fill(Color.black)
                                .matchedGeometryEffect(id: "Background", in: animation)
                                .frame(width: 220, height: 36)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        } else {
                            Capsule()
                                .fill(Color.black)
                                .matchedGeometryEffect(id: "Background", in: animation)
                                .frame(width: 140, height: 30)
                        }
                    }
                }
                // 테두리 (Border)
                .overlay(
                    Group {
                        if isExpanded {
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                .matchedGeometryEffect(id: "Border", in: animation)
                        } else {
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                .matchedGeometryEffect(id: "Border", in: animation)
                        }
                    }
                )
                
                // ---------------------------------------------------------
                // 2. 콘텐츠 레이어
                // ---------------------------------------------------------
                VStack(spacing: 0) {
                    if isExpanded {
                        ExpandedDashboard(
                            isExpanded: $isExpanded,
                            selectedTab: $selectedTab,
                            media: mediaObserver,
                            animation: animation
                        )
                        .transition(
                            .asymmetric(
                                insertion: .opacity
                                    .animation(.easeIn(duration: 0.2).delay(0.1)),
                                removal: .opacity
                                    .animation(.easeOut(duration: 0.15))
                            )
                        )
                    } else {
                        CompactBar(media: mediaObserver, animation: animation)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity
                                        .animation(.easeIn(duration: 0.2)),
                                    removal: .opacity
                                        .animation(.easeOut(duration: 0.1))
                                )
                            )
                    }
                }
                .frame(
                    width: isExpanded ? 500 : (mediaObserver.isPlaying ? 220 : 140),
                    height: isExpanded ? 280 : (mediaObserver.isPlaying ? 36 : 30)
                )
                
                // ---------------------------------------------------------
                // 3. 인터랙션 레이어 (투명 버튼)
                // ---------------------------------------------------------
                Color.clear
                    .contentShape(Rectangle())
                    .frame(
                        width: isExpanded ? 500 : (mediaObserver.isPlaying ? 220 : 140),
                        height: isExpanded ? 280 : 36
                    )
                    .onTapGesture {
                        let targetAnimation = isExpanded ? collapseAnimation : expandAnimation
                        withAnimation(targetAnimation) {
                            isExpanded.toggle()
                        }
                    }
                    .allowsHitTesting(!isExpanded)
            }
            // ---------------------------------------------------------
            // 4. 제스처 및 효과
            // ---------------------------------------------------------
            .onHover { hovering in
                isHovering = hovering
                if isExpanded && !hovering {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if !self.isHovering {
                            withAnimation(self.collapseAnimation) {
                                self.isExpanded = false
                            }
                        }
                    }
                }
            }
            .scaleEffect(isExpanded ? 1.0 : (isHovering ? 1.05 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(isExpanded ? expandAnimation : collapseAnimation, value: isExpanded)
            .animation(expandAnimation, value: mediaObserver.isPlaying)
            
            Spacer()
        }
        .padding(.top, 0)
    }
}

// MARK: - 1. 축소 상태 (CompactBar)
struct CompactBar: View {
    @ObservedObject var media: MediaObserver
    var animation: Namespace.ID
    
    var body: some View {
        HStack(spacing: 12) {
            if media.isPlaying {
                // 앨범 아트
                if let data = media.artworkData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24).clipShape(Circle())
                        .matchedGeometryEffect(id: "Artwork", in: animation)
                } else {
                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 24, height: 24)
                        .matchedGeometryEffect(id: "Artwork", in: animation)
                }
                
                // 제목
                Text("\(media.title) - \(media.artist)")
                    .font(.system(size: 13, weight: .medium)).foregroundColor(.white).lineLimit(1)
                    .matchedGeometryEffect(id: "Title", in: animation)
                
                Spacer()
                
                // 파형
                HStack(spacing: 3) {
                    ForEach(0..<4) { i in WaveBar(isPlaying: true, delay: Double(i) * 0.1, maxHeight: 12) }
                }.matchedGeometryEffect(id: "Wave", in: animation)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 9)
    }
}

// MARK: - 2. 확장 상태 (ExpandedDashboard) - [탭 고정 & 스크롤 가능]
struct ExpandedDashboard: View {
    @Binding var isExpanded: Bool
    @Binding var selectedTab: NotchTab
    @ObservedObject var media: MediaObserver
    var animation: Namespace.ID

    var body: some View {
        VStack(spacing: 0) {
            // [고정] 상단 탭 네비게이션 - 항상 상단에 고정
            HStack {
                HStack(spacing: 5) {
                    ForEach(NotchTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedTab == tab ? .white : .gray.opacity(0.7))
                                .padding(.vertical, 7)
                                .padding(.horizontal, 14)
                                .background(
                                    Capsule()
                                        .fill(selectedTab == tab ? Color.white.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color.black) // 배경 추가로 콘텐츠가 겹치지 않도록
            .zIndex(10) // 항상 위에 표시

            // [스크롤 가능] 탭별 콘텐츠 영역
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if selectedTab == .app {
                        if media.isPlaying || !media.title.isEmpty {
                            MediaPlayerView(media: media, animation: animation)
                                .padding(.top, 8)
                        } else {
                            PlaceholderView(icon: "music.note.list", text: "재생 중인 미디어 없음")
                                .frame(height: 180)
                        }
                    } else if selectedTab == .tray {
                        TrayView()
                            .frame(minHeight: 200)
                    } else {
                        KUWidgetView()
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - 3. 미디어 플레이어 상세
struct MediaPlayerView: View {
    @ObservedObject var media: MediaObserver
    var animation: Namespace.ID
    @State private var isAlbumHovering = false
    @State private var currentProgress: Double = 0.0
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                if let data = media.artworkData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140).cornerRadius(24)
                        .shadow(radius: isAlbumHovering ? 20 : 10)
                        .matchedGeometryEffect(id: "Artwork", in: animation)
                        .scaleEffect(isAlbumHovering ? 1.05 : 1.0)
                } else {
                    RoundedRectangle(cornerRadius: 24).fill(Color.gray.opacity(0.3))
                        .frame(width: 140, height: 140).matchedGeometryEffect(id: "Artwork", in: animation)
                        .scaleEffect(isAlbumHovering ? 1.05 : 1.0)
                }
            }
            .onHover { isAlbumHovering = $0 }
            .onTapGesture { media.activateApp() }
            
            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                Text(media.title).font(.system(size: 22, weight: .bold)).foregroundColor(.white).lineLimit(1)
                    .matchedGeometryEffect(id: "Title", in: animation)
                Text(media.artist).font(.system(size: 16, weight: .medium)).foregroundColor(.gray).lineLimit(1)
                Spacer().frame(height: 16)
                
                HStack(spacing: 4) {
                    ForEach(0..<16) { i in WaveBar(isPlaying: media.isPlaying, delay: Double(i) * 0.05, maxHeight: 24, minHeight: 4) }
                }
                .frame(height: 24)
                .mask(LinearGradient(colors: [.white.opacity(0.2), .white, .white.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
                .matchedGeometryEffect(id: "Wave", in: animation, anchor: .leading)
                
                VStack(spacing: 4) {
                    ProgressView(value: currentProgress, total: media.duration)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white)).scaleEffect(y: 0.5)
                    HStack {
                        Text(formatTime(currentProgress))
                        Spacer()
                        Text(formatTime(media.duration))
                    }.font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                }.padding(.top, 4)
                
                HStack(spacing: 28) {
                    Button(action: { media.previousTrack() }) { Image(systemName: "backward.fill").font(.title3).foregroundColor(.white) }.buttonStyle(.plain)
                    Button(action: { media.togglePlayPause() }) { Image(systemName: media.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 44)).foregroundColor(.white).shadow(radius: 5) }.buttonStyle(.plain)
                    Button(action: { media.nextTrack() }) { Image(systemName: "forward.fill").font(.title3).foregroundColor(.white) }.buttonStyle(.plain)
                }.padding(.top, 4)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.onReceive(timer) { _ in
            if media.isPlaying {
                let now = Date(); let diff = now.timeIntervalSince(media.timestamp)
                currentProgress = min(media.elapsedTime + diff, media.duration)
            } else { currentProgress = media.elapsedTime }
        }
    }
    func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        return String(format: "%d:%02d", Int(seconds)/60, Int(seconds)%60)
    }
}

// MARK: - 4. [완전 재디자인] 고려대학교 위젯 - 애플스럽고 가시성 극대화
struct KUWidgetView: View {
    @StateObject private var shuttleManager = ShuttleManager()
    @State private var direction: ShuttleManager.Direction = .toStation
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    // 고려대 크림슨 컬러
    let kuRed = Color(red: 152/255, green: 30/255, blue: 50/255)

    var body: some View {
        VStack(spacing: 14) {
            // 메인 셔틀버스 카드 - 가시성 최우선
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    colors: [kuRed, kuRed.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(20)
                .shadow(color: kuRed.opacity(0.3), radius: 12, x: 0, y: 6)

                VStack(spacing: 12) {
                    // 상단: 아이콘 + 방향 선택
                    HStack {
                        // 버스 아이콘
                        Image(systemName: "bus.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())

                        Spacer()

                        // 방향 선택 Picker
                        Menu {
                            Button(action: {
                                withAnimation(.spring()) {
                                    direction = .toStation
                                    shuttleManager.updateNextBus(direction: .toStation)
                                }
                            }) {
                                HStack {
                                    Text("학교 ➔ 조치원역")
                                    if direction == .toStation {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }

                            Button(action: {
                                withAnimation(.spring()) {
                                    direction = .toSchool
                                    shuttleManager.updateNextBus(direction: .toSchool)
                                }
                            }) {
                                HStack {
                                    Text("조치원역 ➔ 학교")
                                    if direction == .toSchool {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(direction == .toStation ? "조치원역 방면" : "학교 방면")
                                    .font(.system(size: 13, weight: .semibold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    Spacer()

                    // 중앙: 남은 시간 (매우 크고 명확하게)
                    if shuttleManager.isServiceEnded {
                        VStack(spacing: 4) {
                            Text("운행종료")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("내일 첫차를 이용해주세요")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        VStack(spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(shuttleManager.timeRemaining.replacingOccurrences(of: "분", with: ""))
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                if shuttleManager.timeRemaining.contains("분") {
                                    Text("분")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            Text("\(shuttleManager.nextBusTime) 출발")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }

                    Spacer()

                    // 하단: 세종캠퍼스 라벨
                    Text("세종캠퍼스 셔틀버스")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 18)
                }
            }
            .frame(height: 180)

            // 빠른 링크 - 4개 아이콘
            HStack(spacing: 10) {
                QuickLinkButton(
                    icon: "graduationcap.fill",
                    title: "포털",
                    url: "https://portal.korea.ac.kr",
                    color: .blue
                )

                QuickLinkButton(
                    icon: "book.fill",
                    title: "LMS",
                    url: "https://kulms.korea.ac.kr",
                    color: .green
                )

                QuickLinkButton(
                    icon: "building.columns.fill",
                    title: "도서관",
                    url: "https://library.korea.ac.kr",
                    color: .orange
                )

                QuickLinkButton(
                    icon: "calendar",
                    title: "학사일정",
                    url: "https://www.korea.ac.kr/mbshome/mbs/university/subview.do?id=university_010701000000",
                    color: .purple
                )
            }
        }
        .onAppear { shuttleManager.updateNextBus(direction: direction) }
        .onReceive(timer) { _ in shuttleManager.updateNextBus(direction: direction) }
    }
}

// 바로가기 링크 버튼 - 애플스러운 디자인
struct QuickLinkButton: View {
    let icon: String
    let title: String
    let url: String
    let color: Color
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        }) {
            VStack(spacing: 8) {
                // 아이콘
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(color.opacity(isHovering ? 0.2 : 0.15))
                    )

                // 타이틀
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isHovering ? Color.white.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .scaleEffect(isHovering ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
    }
}

// MARK: - 트레이 뷰 (파일 관리)
struct TrayView: View {
    @StateObject private var trayManager = TrayManager()
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 0) {
            // 드롭 존 또는 파일 그리드
            if trayManager.items.isEmpty {
                // 빈 상태: 드래그 앤 드롭 안내
                VStack(spacing: 16) {
                    Image(systemName: isDragging ? "arrow.down.doc.fill" : "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(isDragging ? .white : .gray)

                    Text(isDragging ? "파일을 여기에 놓으세요" : "자주 쓰는 파일을 드래그하세요")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isDragging ? .white : .gray)

                    Text("Finder에서 파일을 끌어다 놓으면\n빠르게 접근할 수 있습니다")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                        .foregroundColor(isDragging ? .white.opacity(0.6) : .gray.opacity(0.3))
                )
                .scaleEffect(isDragging ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            } else {
                // 파일 그리드
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 90, maximum: 110), spacing: 16)
                    ], spacing: 16) {
                        ForEach(trayManager.items) { item in
                            TrayItemView(item: item, trayManager: trayManager)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                if let url = url {
                    DispatchQueue.main.async {
                        trayManager.addItem(url: url)
                    }
                }
            }
        }
        return true
    }
}

// 트레이 아이템 뷰
struct TrayItemView: View {
    let item: TrayItem
    @ObservedObject var trayManager: TrayManager
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // 파일 아이콘
                VStack(spacing: 6) {
                    Image(systemName: item.iconName)
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )

                    // 파일 이름
                    Text(item.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 90)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isHovering ? Color.white.opacity(0.08) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isHovering ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                )

                // 삭제 버튼 (호버 시에만 표시)
                if isHovering {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            trayManager.removeItem(id: item.id)
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red.opacity(0.9))
                            .background(
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 16, height: 16)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            trayManager.openItem(url: item.url)
        }
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
    }
}

// 공통 컴포넌트
struct WaveBar: View {
    var isPlaying: Bool; var delay: Double; var maxHeight: CGFloat; var minHeight: CGFloat = 3
    @State private var height: CGFloat = 3
    var body: some View {
        RoundedRectangle(cornerRadius: 10).fill(Color.white).frame(width: 4, height: height)
            .onChange(of: isPlaying) { _, p in if p { startAnim() } else { height = minHeight } }
            .onAppear { if isPlaying { startAnim() } }
    }
    func startAnim() { withAnimation(.easeInOut(duration: Double.random(in: 0.4...0.7)).repeatForever().delay(delay)) { height = CGFloat.random(in: minHeight...maxHeight) } }
}
struct PlaceholderView: View {
    let icon: String; let text: String
    var body: some View { VStack(spacing: 15) { Image(systemName: icon).font(.largeTitle).foregroundColor(.gray); Text(text).foregroundColor(.gray) } }
}
struct SpectrumView: View {
    var isPlaying: Bool; let barCount = 20
    var body: some View { HStack(spacing: 3) { ForEach(0..<barCount, id: \.self) { i in WaveBar(isPlaying: isPlaying, delay: Double(i) * 0.05, maxHeight: 24, minHeight: 4) } } }
}
