import SwiftUI

// MARK: - 교시 세그먼트 바 (홈 위젯 / Live Activity / Dynamic Island 공유)
// 과거 = 어둑, 현재 = SurlapTheme.accent + 가운데 흰 3px 플레이헤드 틱, 미래 = 주얼톤.
struct PeriodBar: View {
    let segments: [Color]
    let current: Int           // -1 이면 진행 중 교시 없음

    var body: some View {
        HStack(spacing: 4) {
            ForEach(segments.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 6)
                    .fill(i == current ? SurlapTheme.accent : segments[i])
                    .frame(maxWidth: .infinity)
                    .layoutPriority(i == current ? 1.7 : 1)
                    .overlay {
                        if i == current {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(.white)
                                .frame(width: 3)
                        }
                    }
            }
        }
        .frame(height: 20)
    }
}
