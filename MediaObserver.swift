import Foundation
import AppKit
import Combine
import Darwin

class MediaObserver: ObservableObject {
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var isPlaying: Bool = false
    @Published var artworkData: Data? = nil
    
    // 시간 정보
    @Published var duration: Double = 1.0
    @Published var elapsedTime: Double = 0.0
    @Published var timestamp: Date = Date()
    
    // [추가] 앱 실행을 위한 Bundle ID 저장 (예: com.apple.Music, com.google.Chrome)
    @Published var hostBundleID: String = ""

    // C언어 함수 포인터
    typealias MRRegisterFunc = @convention(c) (DispatchQueue) -> Void
    typealias MRGetInfoFunc = @convention(c) (DispatchQueue, @escaping (CFDictionary?) -> Void) -> Void
    typealias MRSendCommandFunc = @convention(c) (Int, AnyObject?) -> Bool

    var mrRegister: MRRegisterFunc?
    var mrGetInfo: MRGetInfoFunc?
    var mrSendCommand: MRSendCommandFunc?

    init() {
        let frameworkPath = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        guard let handle = dlopen(frameworkPath, RTLD_NOW) else { return }

        let registerSym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications")
        let getInfoSym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo")
        let sendCommandSym = dlsym(handle, "MRMediaRemoteSendCommand")

        if let registerSym = registerSym, let getInfoSym = getInfoSym, let sendCommandSym = sendCommandSym {
            self.mrRegister = unsafeBitCast(registerSym, to: MRRegisterFunc.self)
            self.mrGetInfo = unsafeBitCast(getInfoSym, to: MRGetInfoFunc.self)
            self.mrSendCommand = unsafeBitCast(sendCommandSym, to: MRSendCommandFunc.self)
        }
        
        self.mrRegister?(DispatchQueue.main)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateInfo),
            name: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil
        )
        updateInfo()
    }
    
    @objc func updateInfo() {
        self.mrGetInfo?(DispatchQueue.main) { [weak self] infoRef in
            guard let self = self, let infoRef = infoRef else { return }
            let dict = infoRef as NSDictionary
            
            DispatchQueue.main.async {
                self.title = (dict["kMRMediaRemoteNowPlayingInfoTitle"] as? String) ?? ""
                self.artist = (dict["kMRMediaRemoteNowPlayingInfoArtist"] as? String) ?? ""
                
                // [추가] 재생 중인 앱의 Bundle ID 저장
                if let bundleID = dict["kMRMediaRemoteNowPlayingInfoParentAppBundleIdentifier"] as? String {
                    self.hostBundleID = bundleID
                }
                
                let playbackRate = dict["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0.0
                self.isPlaying = (playbackRate > 0.0)
                
                self.duration = dict["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 1.0
                self.elapsedTime = dict["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0.0
                self.timestamp = Date()
                
                if let artwork = dict["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                    self.artworkData = artwork
                } else {
                    self.artworkData = nil
                }
            }
        }
    }
    
    // MARK: - 기능 제어
    func togglePlayPause() { _ = self.mrSendCommand?(2, nil) }
    func nextTrack() { _ = self.mrSendCommand?(4, nil) }
    func previousTrack() { _ = self.mrSendCommand?(5, nil) }
    
    // [추가] 해당 앱을 최상단으로 실행시키는 함수
    func activateApp() {
        guard !hostBundleID.isEmpty else { return }
        // Bundle ID로 앱 URL 찾기
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: hostBundleID) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true // 앱을 활성화(맨 앞으로)
            NSWorkspace.shared.openApplication(at: appUrl, configuration: config, completionHandler: nil)
        }
    }
}
