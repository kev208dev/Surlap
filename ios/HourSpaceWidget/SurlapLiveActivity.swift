import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity attributes
// 정적: schoolClass 등 화면 동안 변하지 않는 값.
// 동적: 현재/다음 과목 이름·시간·세그먼트 + minutesRemaining.
public struct SurlapAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var nowName: String
        public var nowTime: String
        public var nextName: String
        public var nextTime: String
        public var remaining: String
        public var segmentsHex: [String]   // ["#3A3A78", ...]
        public var current: Int            // -1 이면 진행 중 교시 없음

        public init(nowName: String, nowTime: String, nextName: String,
                    nextTime: String, remaining: String,
                    segmentsHex: [String], current: Int) {
            self.nowName = nowName
            self.nowTime = nowTime
            self.nextName = nextName
            self.nextTime = nextTime
            self.remaining = remaining
            self.segmentsHex = segmentsHex
            self.current = current
        }
    }

    public var schoolClass: String

    public init(schoolClass: String) {
        self.schoolClass = schoolClass
    }
}

// MARK: - Live Activity widget (Lock Screen + Dynamic Island)
@available(iOS 16.1, *)
struct SurlapLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SurlapAttributes.self) { ctx in
            // 잠금화면 / 배너 뷰 — 4.2 NowNextCard 그대로.
            NowNextCard(
                nowName: ctx.state.nowName,
                nowTime: ctx.state.nowTime,
                nextName: ctx.state.nextName,
                nextTime: ctx.state.nextTime,
                segments: ctx.state.segmentsHex.map { Color(hex: $0) },
                current: ctx.state.current,
                remainingText: ctx.state.remaining
            )
            .padding(12)
            .background(SurlapTheme.surfaceGradient)
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    NowNextCard(
                        nowName: ctx.state.nowName,
                        nowTime: ctx.state.nowTime,
                        nextName: ctx.state.nextName,
                        nextTime: ctx.state.nextTime,
                        segments: ctx.state.segmentsHex.map { Color(hex: $0) },
                        current: ctx.state.current,
                        remainingText: ctx.state.remaining
                    )
                }
            } compactLeading: {
                Label {
                    Text(ctx.state.remaining)
                } icon: {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(SurlapTheme.accent)
                }
            } compactTrailing: {
                Text(ctx.state.nowName)
                    .fontWeight(.heavy)
                    .foregroundStyle(SurlapTheme.accent)
            } minimal: {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(SurlapTheme.accent)
            }
        }
    }
}

// MARK: - 사용 가이드
// 1) 수업 시작 시: Activity.request(attributes:..., content:.init(state:..., staleDate:nil))
// 2) 매 분/교시 전환마다: await activity.update(.init(state:..., staleDate:nil))
// 3) 학교 일과 종료 시: await activity.end(...)
// Flutter 측에서는 home_widget로 데이터 push 후 method channel 로 시작/갱신/종료 트리거.
