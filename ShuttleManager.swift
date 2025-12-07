import Foundation

struct BusTime: Identifiable {
    let id = UUID()
    let hour: Int
    let minute: Int
    let type: String // "Weekday" (평일) or "Sunday" (일요일/주말)
    
    // 현재 시간과 비교를 위해 오늘의 Date 객체로 변환
    func toDate() -> Date? {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)
    }
}

class ShuttleManager: ObservableObject {
    // 방향 정의
    enum Direction: String, CaseIterable {
        case toStation = "학교 ➔ 조치원역"
        case toSchool = "조치원역 ➔ 학교"
    }
    
    @Published var nextBusTime: String = "정보 없음"
    @Published var timeRemaining: String = "---"
    @Published var isServiceEnded: Bool = false
    
    // ------------------------------------------------------------------
    // [데이터] bus_time.csv 기반 시간표 데이터 (평일 & 일요일)
    // ------------------------------------------------------------------
    
    // 1. 학교 -> 조치원역 (School_to_Station)
    private let schoolToStation: [BusTime] = [
        // [평일]
        BusTime(hour: 8, minute: 50, type: "Weekday"), BusTime(hour: 9, minute: 10, type: "Weekday"),
        BusTime(hour: 9, minute: 30, type: "Weekday"), BusTime(hour: 9, minute: 40, type: "Weekday"),
        BusTime(hour: 9, minute: 50, type: "Weekday"), BusTime(hour: 10, minute: 10, type: "Weekday"),
        BusTime(hour: 10, minute: 30, type: "Weekday"), BusTime(hour: 10, minute: 40, type: "Weekday"),
        BusTime(hour: 11, minute: 0, type: "Weekday"), BusTime(hour: 11, minute: 20, type: "Weekday"),
        BusTime(hour: 11, minute: 40, type: "Weekday"), BusTime(hour: 12, minute: 10, type: "Weekday"),
        BusTime(hour: 12, minute: 30, type: "Weekday"), BusTime(hour: 12, minute: 40, type: "Weekday"),
        BusTime(hour: 13, minute: 10, type: "Weekday"), BusTime(hour: 13, minute: 30, type: "Weekday"),
        BusTime(hour: 13, minute: 50, type: "Weekday"), BusTime(hour: 14, minute: 10, type: "Weekday"),
        BusTime(hour: 14, minute: 30, type: "Weekday"), BusTime(hour: 15, minute: 0, type: "Weekday"),
        BusTime(hour: 15, minute: 10, type: "Weekday"), BusTime(hour: 15, minute: 30, type: "Weekday"),
        BusTime(hour: 15, minute: 50, type: "Weekday"), BusTime(hour: 16, minute: 10, type: "Weekday"),
        BusTime(hour: 16, minute: 30, type: "Weekday"), BusTime(hour: 16, minute: 50, type: "Weekday"),
        BusTime(hour: 17, minute: 10, type: "Weekday"), BusTime(hour: 17, minute: 25, type: "Weekday"),
        BusTime(hour: 17, minute: 40, type: "Weekday"), BusTime(hour: 18, minute: 0, type: "Weekday"),
        BusTime(hour: 18, minute: 25, type: "Weekday"), BusTime(hour: 18, minute: 40, type: "Weekday"),
        BusTime(hour: 19, minute: 10, type: "Weekday"), BusTime(hour: 19, minute: 40, type: "Weekday"),
        BusTime(hour: 20, minute: 10, type: "Weekday"), BusTime(hour: 20, minute: 50, type: "Weekday"),
        
        // [일요일/주말]
        BusTime(hour: 17, minute: 0, type: "Sunday"), BusTime(hour: 17, minute: 40, type: "Sunday"),
        BusTime(hour: 18, minute: 40, type: "Sunday"), BusTime(hour: 19, minute: 0, type: "Sunday"),
        BusTime(hour: 19, minute: 40, type: "Sunday"), BusTime(hour: 20, minute: 20, type: "Sunday"),
        BusTime(hour: 21, minute: 10, type: "Sunday")
    ]
    
    // 2. 조치원역 -> 학교 (Station_to_School)
    private let stationToSchool: [BusTime] = [
        // [평일]
        BusTime(hour: 8, minute: 20, type: "Weekday"), BusTime(hour: 8, minute: 45, type: "Weekday"),
        BusTime(hour: 9, minute: 0, type: "Weekday"), BusTime(hour: 9, minute: 20, type: "Weekday"),
        BusTime(hour: 9, minute: 40, type: "Weekday"), BusTime(hour: 9, minute: 50, type: "Weekday"),
        BusTime(hour: 10, minute: 0, type: "Weekday"), BusTime(hour: 10, minute: 20, type: "Weekday"),
        BusTime(hour: 10, minute: 40, type: "Weekday"), BusTime(hour: 10, minute: 50, type: "Weekday"),
        BusTime(hour: 11, minute: 10, type: "Weekday"), BusTime(hour: 11, minute: 30, type: "Weekday"),
        BusTime(hour: 11, minute: 50, type: "Weekday"), BusTime(hour: 12, minute: 20, type: "Weekday"),
        BusTime(hour: 12, minute: 40, type: "Weekday"), BusTime(hour: 12, minute: 50, type: "Weekday"),
        BusTime(hour: 13, minute: 20, type: "Weekday"), BusTime(hour: 13, minute: 40, type: "Weekday"),
        BusTime(hour: 14, minute: 0, type: "Weekday"), BusTime(hour: 14, minute: 20, type: "Weekday"),
        BusTime(hour: 14, minute: 40, type: "Weekday"), BusTime(hour: 15, minute: 10, type: "Weekday"),
        BusTime(hour: 15, minute: 20, type: "Weekday"), BusTime(hour: 15, minute: 40, type: "Weekday"),
        BusTime(hour: 16, minute: 0, type: "Weekday"), BusTime(hour: 16, minute: 20, type: "Weekday"),
        BusTime(hour: 16, minute: 40, type: "Weekday"), BusTime(hour: 17, minute: 0, type: "Weekday"),
        BusTime(hour: 17, minute: 20, type: "Weekday"), BusTime(hour: 17, minute: 35, type: "Weekday"),
        BusTime(hour: 17, minute: 50, type: "Weekday"), BusTime(hour: 18, minute: 10, type: "Weekday"),
        BusTime(hour: 18, minute: 50, type: "Weekday"), BusTime(hour: 19, minute: 20, type: "Weekday"),
        BusTime(hour: 19, minute: 50, type: "Weekday"), BusTime(hour: 20, minute: 20, type: "Weekday"),
        BusTime(hour: 21, minute: 0, type: "Weekday"),
        
        // [일요일/주말]
        BusTime(hour: 16, minute: 30, type: "Sunday"), BusTime(hour: 17, minute: 10, type: "Sunday"),
        BusTime(hour: 17, minute: 50, type: "Sunday"), BusTime(hour: 18, minute: 50, type: "Sunday"),
        BusTime(hour: 19, minute: 10, type: "Sunday"), BusTime(hour: 19, minute: 50, type: "Sunday"),
        BusTime(hour: 20, minute: 35, type: "Sunday"), BusTime(hour: 21, minute: 20, type: "Sunday")
    ]
    
    // ------------------------------------------------------------------
    // [로직] 다음 버스 계산
    // ------------------------------------------------------------------
    func updateNextBus(direction: Direction) {
        let now = Date()
        let calendar = Calendar.current
        
        // 1. 오늘의 요일 확인 (주말 여부)
        let isWeekend = calendar.isDateInWeekend(now)
        let currentType = isWeekend ? "Sunday" : "Weekday"
        
        // 2. 방향에 따른 전체 시간표 선택
        let fullSchedule = direction == .toStation ? schoolToStation : stationToSchool
        
        // 3. 오늘 요일에 맞는 시간표 필터링
        let todaySchedule = fullSchedule.filter { $0.type == currentType }
        
        // 4. 현재 시간보다 나중인 버스 찾기
        if let nextBus = todaySchedule.first(where: {
            guard let busDate = $0.toDate() else { return false }
            return busDate > now
        }) {
            // [상태 1] 오늘 남은 버스가 있을 때
            guard let busDate = nextBus.toDate() else { return }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            self.nextBusTime = formatter.string(from: busDate)
            
            let diff = busDate.timeIntervalSince(now)
            let minutes = Int(diff) / 60
            
            if minutes < 1 {
                self.timeRemaining = "곧 도착"
            } else {
                self.timeRemaining = "\(minutes)분"
            }
            self.isServiceEnded = false
            
        } else {
            // [상태 2] 오늘 운행 종료 -> 내일 첫차 정보 표시
            // 내일 요일 계산 (오늘이 평일 금요일이면 내일은 주말, 일요일이면 내일은 평일 등)
            // 간단하게: 주말이면 -> 평일 첫차, 평일이면 -> 평일 첫차 (금요일밤 제외) 등 로직이 복잡할 수 있으나,
            // 여기서는 심플하게 '전체 시간표'의 첫 번째 차를 내일 첫차로 가정하고 표시하거나 '운행 종료' 띄움.
            
            self.nextBusTime = "--:--"
            self.timeRemaining = "운행종료"
            self.isServiceEnded = true
        }
    }
}
