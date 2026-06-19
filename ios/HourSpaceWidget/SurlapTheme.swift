import SwiftUI

// MARK: - Surlap 위젯 디자인 토큰
// 모든 위젯 / Live Activity / Dynamic Island 공유 색·그라데이션.
// (Material You 변형은 Android 측에서 system_accent / system_neutral 토큰 사용.)
enum SurlapTheme {
    static let surfaceTop = Color(hex: "#1E1638")
    static let surfaceBottom = Color(hex: "#150F29")
    static let accent = Color(hex: "#A98BFF")        // 라벤더 — 시간/현재 강조
    static let labelMuted = Color(hex: "#8E8C97")    // "지금"/"다음" 캡션
    static let caption = Color(hex: "#A4A2AD")       // "종료까지 N분"

    // 미래 교시 기본 팔레트 — 과목 색이 없을 때 폴백.
    static let jewelPalette: [Color] = [
        Color(hex: "#3A3A78"),
        Color(hex: "#2F4E7A"),
        Color(hex: "#1F5A5A"),
        Color(hex: "#243A6E"),
        Color(hex: "#3E2E72"),
        Color(hex: "#5A2E62"),
        Color(hex: "#5A2E4E"),
    ]

    static var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [surfaceTop, surfaceBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
