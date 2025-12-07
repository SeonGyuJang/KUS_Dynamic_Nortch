import Foundation
import SwiftUI
import AppKit

// 트레이에 저장되는 파일 아이템
struct TrayItem: Identifiable, Codable {
    let id: UUID
    let url: URL
    let name: String
    let iconName: String

    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.iconName = TrayItem.getIconName(for: url)
    }

    // 파일 확장자에 따라 SF Symbol 아이콘 반환
    static func getIconName(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()

        switch ext {
        // 문서
        case "pdf": return "doc.fill"
        case "doc", "docx": return "doc.text.fill"
        case "txt", "md": return "doc.plaintext.fill"
        case "rtf": return "doc.richtext.fill"

        // 이미지
        case "jpg", "jpeg", "png", "gif", "heic", "svg": return "photo.fill"

        // 비디오
        case "mp4", "mov", "avi", "mkv": return "video.fill"

        // 오디오
        case "mp3", "wav", "m4a", "flac": return "music.note"

        // 압축 파일
        case "zip", "rar", "7z", "tar", "gz": return "doc.zipper"

        // 코드
        case "swift", "py", "js", "ts", "java", "cpp", "c", "h": return "curlybraces"
        case "html", "css": return "globe"
        case "json", "xml": return "doc.badge.gearshape"

        // 스프레드시트
        case "xls", "xlsx", "csv": return "tablecells.fill"

        // 프레젠테이션
        case "ppt", "pptx", "key": return "play.rectangle.fill"

        // 폴더
        default:
            if url.hasDirectoryPath {
                return "folder.fill"
            }
            return "doc.fill"
        }
    }
}

class TrayManager: ObservableObject {
    @Published var items: [TrayItem] = []

    private let userDefaultsKey = "TrayItems"

    init() {
        loadItems()
    }

    // UserDefaults에서 저장된 항목 로드
    func loadItems() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let urls = try? JSONDecoder().decode([URL].self, from: data) {
            items = urls.map { TrayItem(url: $0) }
        }
    }

    // UserDefaults에 항목 저장
    func saveItems() {
        let urls = items.map { $0.url }
        if let data = try? JSONEncoder().encode(urls) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    // 파일 추가
    func addItem(url: URL) {
        // 중복 체크
        guard !items.contains(where: { $0.url == url }) else { return }

        // Security-scoped bookmark 생성 (앱 재시작 후에도 접근 가능하도록)
        if url.startAccessingSecurityScopedResource() {
            let item = TrayItem(url: url)
            items.append(item)
            saveItems()
            url.stopAccessingSecurityScopedResource()
        }
    }

    // 파일 삭제
    func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
        saveItems()
    }

    // 파일 열기
    func openItem(url: URL) {
        NSWorkspace.shared.open(url)
    }
}
