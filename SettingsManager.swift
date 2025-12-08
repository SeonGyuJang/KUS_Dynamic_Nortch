import SwiftUI

class SettingsManager: ObservableObject {
    @Published var notchWidth: CGFloat {
        didSet {
            UserDefaults.standard.set(notchWidth, forKey: "notchWidth")
        }
    }

    @Published var notchHeight: CGFloat {
        didSet {
            UserDefaults.standard.set(notchHeight, forKey: "notchHeight")
        }
    }

    init() {
        // Load saved values or use defaults
        let savedWidth = UserDefaults.standard.object(forKey: "notchWidth") as? CGFloat
        let savedHeight = UserDefaults.standard.object(forKey: "notchHeight") as? CGFloat

        self.notchWidth = savedWidth ?? 500
        self.notchHeight = savedHeight ?? 280
    }

    func resetToDefaults() {
        notchWidth = 500
        notchHeight = 280
    }
}
