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
    
    // 애플 스타일의 쫀득한 물리 애니메이션
    var springAnim: Animation {
        .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
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
                        // 콘텐츠가 자연스럽게 나타나도록 페이드 적용
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    } else {
                        CompactBar(media: mediaObserver, animation: animation)
                            .transition(.opacity.animation(.easeInOut(duration: 0.1)))
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
                        withAnimation(springAnim) {
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if !self.isHovering {
                            withAnimation(springAnim) {
                                self.isExpanded = false
                            }
                        }
                    }
                }
            }
            .scaleEffect(isExpanded ? 1.0 : (isHovering ? 1.03 : 1.0))
            .animation(springAnim, value: isHovering)
            .animation(springAnim, value: isExpanded)
            .animation(springAnim, value: mediaObserver.isPlaying)
            
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

// MARK: - 2. 확장 상태 (ExpandedDashboard) - [레이아웃 수정됨]
struct ExpandedDashboard: View {
    @Binding var isExpanded: Bool
    @Binding var selectedTab: NotchTab
    @ObservedObject var media: MediaObserver
    var animation: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0) {
            // [고정] 상단 탭 네비게이션
            // 상단바가 절대 밀리지 않도록 고정 높이 부여
            HStack {
                HStack(spacing: 5) {
                    ForEach(NotchTab.allCases, id: \.self) { tab in
                        Button(action: { withAnimation { selectedTab = tab } }) {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(selectedTab == tab ? Color.white.opacity(0.2) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .padding(20)
            .frame(height: 60) // 상단바 높이 고정
            
            // [유동] 탭별 콘텐츠 영역
            // 아래쪽으로 확장되도록 Spacer나 Frame 조정 필요 없음 (VStack이라 자동 배치)
            ZStack {
                if selectedTab == .app {
                    if media.isPlaying || !media.title.isEmpty {
                        MediaPlayerView(media: media, animation: animation)
                    } else {
                        PlaceholderView(icon: "music.note.list", text: "재생 중인 미디어 없음")
                    }
                } else if selectedTab == .tray {
                    PlaceholderView(icon: "folder.fill", text: "파일 트레이")
                } else {
                    // [변경] 디자인이 수정된 고려대 위젯
                    KUWidgetView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
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

// MARK: - 4. [수정됨] 고려대학교 셔틀버스 위젯 (Dark Theme)
struct KUWidgetView: View {
    @StateObject private var shuttleManager = ShuttleManager()
    @State private var direction: ShuttleManager.Direction = .toStation
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    // 고려대 크림슨 컬러 그라데이션 (카드용)
    let kuGradient = LinearGradient(
        colors: [Color(red: 136/255, green: 0, blue: 0), Color(red: 180/255, green: 30, blue: 30)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    var body: some View {
        HStack(spacing: 0) {
            // [카드 영역] 시간 정보
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(kuGradient) // 카드 배경은 붉은색
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .shadow(color: Color(red: 136/255, green: 0, blue: 0).opacity(0.4), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 0) {
                    // 헤더
                    HStack {
                        Image(systemName: "bus.fill").font(.system(size: 16)).foregroundColor(.white.opacity(0.9))
                        Text("Shuttle").font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.8)).textCase(.uppercase)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                    
                    Spacer()
                    
                    // 남은 시간
                    if shuttleManager.isServiceEnded {
                        Text("운행종료").font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                    } else {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(shuttleManager.timeRemaining.replacingOccurrences(of: "분", with: ""))
                                .font(.system(size: 54, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            if shuttleManager.timeRemaining.contains("분") {
                                Text("min").font(.system(size: 20, weight: .bold)).foregroundColor(.white.opacity(0.8)).padding(.bottom, 6)
                            }
                        }
                    }
                    
                    // 출발 시간
                    HStack {
                        Image(systemName: "clock.fill").font(.system(size: 12))
                        Text(shuttleManager.isServiceEnded ? "내일 첫차" : "\(shuttleManager.nextBusTime) 출발")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9)).padding(.bottom, 20)
                }
            }
            .frame(width: 220, height: 180)
            
            // [컨트롤 영역] 방향 전환 (Dark Theme 적용: 글자색 흰색)
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("세종캠퍼스").font(.headline).foregroundColor(.white) // 흰색 텍스트
                    Text("셔틀버스 도착 정보").font(.caption).foregroundColor(.gray)
                }
                
                Divider().background(Color.white.opacity(0.3)) // 구분선도 밝게
                
                VStack(spacing: 12) {
                    DirectionButton(title: "학교 ➔ 조치원역", isSelected: direction == .toStation) {
                        withAnimation(.spring()) {
                            direction = .toStation
                            shuttleManager.updateNextBus(direction: .toStation)
                        }
                    }
                    DirectionButton(title: "조치원역 ➔ 학교", isSelected: direction == .toSchool) {
                        withAnimation(.spring()) {
                            direction = .toSchool
                            shuttleManager.updateNextBus(direction: .toSchool)
                        }
                    }
                }
                Spacer()
            }
            .padding(.leading, 24).padding(.vertical, 10)
        }
        .onAppear { shuttleManager.updateNextBus(direction: direction) }
        .onReceive(timer) { _ in shuttleManager.updateNextBus(direction: direction) }
    }
}

// 방향 선택 버튼 (Dark Theme)
struct DirectionButton: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white) // 텍스트 흰색
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1))
        }.buttonStyle(.plain)
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
