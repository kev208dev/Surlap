import WidgetKit
import SwiftUI

// MARK: - Models

struct EventLine: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let end: String
    let color: Color
    let emoji: String
    let sport: Bool
    var isNext: Bool = false
}

struct AllDayLine: Identifiable {
    let id = UUID()
    let title: String
    let color: Color
    let emoji: String
}

struct TodoLine: Identifiable {
    let id = UUID()
    let title: String
    let done: Bool
    let priority: Int
}

struct HSEntry: TimelineEntry {
    let date: Date
    let dateLabel: String
    let dayNum: Int
    let weekday: Int
    let year: Int
    let month: Int
    let allDay: [AllDayLine]
    let timed: [EventLine]
    let todos: [TodoLine]
    let todoCount: Int
    let todoDone: Int
    let eventCount: Int

    static let placeholder = HSEntry(
        date: Date(),
        dateLabel: "6월 8일 (월)",
        dayNum: 8, weekday: 1, year: 2026, month: 6,
        allDay: [AllDayLine(title: "엄마 생신", color: Color(hex: "#F05995"), emoji: "🎂")],
        timed: [
            EventLine(title: "팀 회의", time: "14:00", end: "15:00", color: Color(hex: "#8B7FF5"), emoji: "", sport: false, isNext: true),
            EventLine(title: "T1 vs GEN", time: "17:00", end: "", color: Color(hex: "#6C63FF"), emoji: "🎮", sport: true),
        ],
        todos: [
            TodoLine(title: "운동 가기", done: false, priority: 1),
            TodoLine(title: "장보기", done: true, priority: 0),
        ],
        todoCount: 2, todoDone: 1, eventCount: 3
    )
}

// MARK: - Color hex

extension Color {
    init(hex: String) {
        let s = hex.replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b: Double
        if s.count == 6 {
            r = Double((v >> 16) & 0xFF) / 255
            g = Double((v >> 8) & 0xFF) / 255
            b = Double(v & 0xFF) / 255
        } else {
            r = 0.55; g = 0.50; b = 0.96
        }
        self = Color(red: r, green: g, blue: b)
    }
}

let accent = Color(hex: "#8B7FF5")

// MARK: - Shared data read

enum WidgetStore {
    static let appGroup = "group.com.spacehour.spacehour"
    static let key = "hs_widget"

    static func empty() -> HSEntry {
        let now = Date()
        let c = Calendar.current.dateComponents([.year, .month, .day, .weekday], from: now)
        return HSEntry(
            date: now, dateLabel: "", dayNum: c.day ?? 1,
            weekday: ((c.weekday ?? 1) + 5) % 7 + 1,
            year: c.year ?? 2026, month: c.month ?? 1,
            allDay: [], timed: [], todos: [],
            todoCount: 0, todoDone: 0, eventCount: 0
        )
    }

    static func read() -> HSEntry {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let raw = defaults.string(forKey: key),
            let data = raw.data(using: .utf8),
            let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return empty() }

        let nextIndex = o["nextIndex"] as? Int ?? -1

        let allDay = (o["allDay"] as? [[String: Any]] ?? []).map {
            AllDayLine(
                title: $0["title"] as? String ?? "",
                color: Color(hex: $0["color"] as? String ?? "#8B7FF5"),
                emoji: $0["emoji"] as? String ?? ""
            )
        }
        let timed = (o["timed"] as? [[String: Any]] ?? []).enumerated().map { (i, e) in
            EventLine(
                title: e["title"] as? String ?? "",
                time: e["time"] as? String ?? "",
                end: e["end"] as? String ?? "",
                color: Color(hex: e["color"] as? String ?? "#8B7FF5"),
                emoji: e["emoji"] as? String ?? "",
                sport: e["sport"] as? Bool ?? false,
                isNext: i == nextIndex
            )
        }
        let todos = (o["todos"] as? [[String: Any]] ?? []).map {
            TodoLine(
                title: $0["title"] as? String ?? "",
                done: $0["done"] as? Bool ?? false,
                priority: $0["priority"] as? Int ?? 0
            )
        }

        let dateStr = o["date"] as? String ?? "2026-01-01"
        let parts = dateStr.split(separator: "-").map { Int($0) ?? 0 }

        return HSEntry(
            date: Date(),
            dateLabel: o["dateLabel"] as? String ?? "",
            dayNum: parts.count > 2 ? parts[2] : 1,
            weekday: o["weekday"] as? Int ?? 1,
            year: parts.count > 0 ? parts[0] : 2026,
            month: parts.count > 1 ? parts[1] : 1,
            allDay: allDay, timed: timed, todos: todos,
            todoCount: o["todoCount"] as? Int ?? todos.count,
            todoDone: o["todoDone"] as? Int ?? 0,
            eventCount: o["eventCount"] as? Int ?? 0
        )
    }
}

// MARK: - Timeline

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HSEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (HSEntry) -> Void) {
        completion(context.isPreview ? .placeholder : WidgetStore.read())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HSEntry>) -> Void) {
        let entry = WidgetStore.read()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Mascot

func mascotImage() -> Image? {
    if let ui = UIImage(named: "mascot") { return Image(uiImage: ui) }
    return nil
}

struct Mascot: View {
    var size: CGFloat = 50
    var body: some View {
        if let m = mascotImage() {
            m.resizable().scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
        }
    }
}

// MARK: - Pieces

struct AllDayPill: View {
    let item: AllDayLine
    var body: some View {
        HStack(spacing: 3) {
            if !item.emoji.isEmpty {
                Text(item.emoji).font(.system(size: 9))
            } else {
                Circle().fill(item.color).frame(width: 5, height: 5)
            }
            Text(item.title).font(.system(size: 10, weight: .semibold))
                .foregroundColor(item.color)
                .lineLimit(1)
        }
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(item.color.opacity(0.14))
        .clipShape(Capsule())
    }
}

struct EventRowView: View {
    let e: EventLine
    var body: some View {
        HStack(spacing: 7) {
            Text(e.time.isEmpty ? "—" : e.time)
                .font(.system(size: 11, weight: e.isNext ? .bold : .semibold))
                .foregroundColor(e.isNext ? accent : .secondary)
                .frame(width: 38, alignment: .leading)
            RoundedRectangle(cornerRadius: 2).fill(e.color).frame(width: 3, height: 14)
            if !e.emoji.isEmpty { Text(e.emoji).font(.system(size: 11)) }
            Text(e.title)
                .font(.system(size: 12.5, weight: e.isNext ? .semibold : .regular))
                .foregroundColor(.primary).lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 1.5)
        .background(
            e.isNext ? accent.opacity(0.08) : Color.clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
    }
}

struct TodoRowView: View {
    let t: TodoLine
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: t.done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12)).foregroundColor(t.done ? accent : .secondary)
            Text(t.title)
                .font(.system(size: 12.5))
                .strikethrough(t.done, color: .secondary)
                .foregroundColor(t.done ? .secondary : .primary).lineLimit(1)
            Spacer(minLength: 0)
        }.padding(.vertical, 1)
    }
}

struct HeaderRow: View {
    let entry: HSEntry
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(entry.dayNum)")
                .font(.system(size: 22, weight: .heavy)).foregroundColor(accent)
            Text(entry.dateLabel.replacingOccurrences(of: "\(entry.month)월 \(entry.dayNum)일 ", with: ""))
                .font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
            Spacer()
            Text("할 일 \(entry.todoDone)/\(entry.todoCount)")
                .font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
        }
    }
}

// MARK: - Small

struct SmallView: View {
    let entry: HSEntry
    var next: EventLine? { entry.timed.first(where: { $0.isNext }) ?? entry.timed.first }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: -2) {
                    Text("\(entry.dayNum)").font(.system(size: 30, weight: .heavy)).foregroundColor(accent)
                    Text(weekdayKo(entry.weekday)).font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                }
                Spacer()
            }
            Spacer(minLength: 0)
            if let n = next {
                HStack(spacing: 4) {
                    if !n.emoji.isEmpty { Text(n.emoji).font(.system(size: 10)) }
                    else { Circle().fill(n.color).frame(width: 5, height: 5) }
                    Text(n.time).font(.system(size: 11, weight: .bold)).foregroundColor(accent)
                }
                Text(n.title).font(.system(size: 12, weight: .semibold)).foregroundColor(.primary).lineLimit(2)
            } else if !entry.allDay.isEmpty {
                Text(entry.allDay[0].emoji.isEmpty ? entry.allDay[0].title : "\(entry.allDay[0].emoji) \(entry.allDay[0].title)")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(entry.allDay[0].color).lineLimit(2)
            } else {
                Text("할 일 \(entry.todoDone)/\(entry.todoCount)")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(accent)
                Text("일정 없음").font(.system(size: 11)).foregroundColor(.secondary)
            }
        }
        .overlay(alignment: .topTrailing) { Mascot(size: 42).offset(x: 6, y: -8) }
    }
}

// MARK: - Medium

struct MediumView: View {
    let entry: HSEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HeaderRow(entry: entry)
            if !entry.allDay.isEmpty {
                HStack(spacing: 5) {
                    ForEach(entry.allDay.prefix(3)) { AllDayPill(item: $0) }
                    Spacer(minLength: 0)
                }
            }
            if entry.timed.isEmpty && entry.allDay.isEmpty {
                Spacer()
                EmptyToday()
                Spacer()
            } else {
                ForEach(entry.timed.prefix(3)) { EventRowView(e: $0) }
                if entry.timed.isEmpty {
                    ForEach(entry.todos.prefix(2)) { TodoRowView(t: $0) }
                }
                Spacer(minLength: 0)
            }
        }
        .overlay(alignment: .topTrailing) { Mascot(size: 46).offset(x: 8, y: -10) }
    }
}

// MARK: - Large (calendar + agenda)

struct LargeView: View {
    let entry: HSEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(entry.month)월").font(.system(size: 17, weight: .heavy)).foregroundColor(.primary)
                Spacer()
                Text("할 일 \(entry.todoDone)/\(entry.todoCount) · 일정 \(entry.eventCount)")
                    .font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
            }
            MiniMonth(year: entry.year, month: entry.month, today: entry.dayNum)
            Divider()
            // 아젠다
            if !entry.allDay.isEmpty {
                HStack(spacing: 5) {
                    ForEach(entry.allDay.prefix(4)) { AllDayPill(item: $0) }
                    Spacer(minLength: 0)
                }
            }
            if entry.timed.isEmpty && entry.allDay.isEmpty {
                Spacer(); HStack { Spacer(); EmptyToday(); Spacer() }; Spacer()
            } else {
                ForEach(entry.timed.prefix(4)) { EventRowView(e: $0) }
                ForEach(entry.todos.prefix(2)) { TodoRowView(t: $0) }
                Spacer(minLength: 0)
            }
        }
        .overlay(alignment: .topTrailing) { Mascot(size: 50).offset(x: 8, y: -12) }
    }
}

struct MiniMonth: View {
    let year: Int
    let month: Int
    let today: Int

    var body: some View {
        let cal = Calendar(identifier: .gregorian)
        let first = cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let firstWeekday = cal.component(.weekday, from: first) // 1=Sun
        let days = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let cells = Array(repeating: 0, count: firstWeekday - 1) + Array(1...days)
        let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        let heads = ["일", "월", "화", "수", "목", "금", "토"]

        return LazyVGrid(columns: cols, spacing: 3) {
            ForEach(0..<7, id: \.self) { i in
                Text(heads[i])
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(i == 0 ? Color(hex: "#F05995") : (i == 6 ? accent : .secondary))
            }
            ForEach(Array(cells.enumerated()), id: \.offset) { (idx, d) in
                if d == 0 {
                    Text("").font(.system(size: 11))
                } else {
                    let isToday = d == today
                    let col = idx % 7
                    Text("\(d)")
                        .font(.system(size: 11, weight: isToday ? .bold : .regular))
                        .foregroundColor(isToday ? .white : (col == 0 ? Color(hex: "#F05995") : (col == 6 ? accent : .primary)))
                        .frame(maxWidth: .infinity)
                        .frame(height: 18)
                        .background(isToday ? accent : Color.clear, in: Circle())
                }
            }
        }
    }
}

struct EmptyToday: View {
    var body: some View {
        VStack(spacing: 5) {
            if let m = mascotImage() { m.resizable().scaledToFit().frame(width: 54, height: 54) }
            Text("오늘은 여유로운 하루").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
        }
    }
}

func weekdayKo(_ w: Int) -> String {
    let names = ["월", "화", "수", "목", "금", "토", "일"]
    let i = max(1, min(7, w)) - 1
    return names[i] + "요일"
}

// MARK: - Entry view

struct HourSpaceWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: HSEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall: SmallView(entry: entry)
            case .systemLarge: LargeView(entry: entry)
            default: MediumView(entry: entry)
            }
        }
    }
}

// MARK: - Widget

struct HourSpaceWidget: Widget {
    let kind = "HourSpaceWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                HourSpaceWidgetEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
                    .widgetURL(URL(string: "spacehour://widget"))
            } else {
                HourSpaceWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
                    .widgetURL(URL(string: "spacehour://widget"))
            }
        }
        .configurationDisplayName("오늘 일정")
        .description("오늘의 종일·일정·할 일과 이번 달 달력을 한눈에.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct HourSpaceWidgetBundle: WidgetBundle {
    var body: some Widget {
        HourSpaceWidget()
    }
}
