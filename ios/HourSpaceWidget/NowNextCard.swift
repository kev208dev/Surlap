import SwiftUI

// MARK: - "지금 / 다음" 카드 (Medium 위젯 + Live Activity 공유 모듈)
// 폰트는 Pretendard 번들 후 .custom("Pretendard-Bold", size:)로 교체 권장.
struct NowNextCard: View {
    let nowName: String
    let nowTime: String
    let nextName: String
    let nextTime: String
    let segments: [Color]
    let current: Int
    let remainingText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("지금").foregroundStyle(SurlapTheme.labelMuted)
                Spacer()
                Text("다음").foregroundStyle(SurlapTheme.labelMuted)
            }
            .font(.system(size: 13.5, weight: .semibold))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(nowName)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(nowTime)
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundStyle(SurlapTheme.accent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(nextName)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(nextTime)
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundStyle(SurlapTheme.accent)
                }
            }
            .padding(.top, 4)

            PeriodBar(segments: segments, current: current)
                .padding(.top, 14)

            Text(remainingText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SurlapTheme.caption)
                .frame(maxWidth: .infinity)
                .padding(.top, 11)
        }
        .padding(18)
        .background(SurlapTheme.surfaceGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
