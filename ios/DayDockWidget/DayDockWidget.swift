import SwiftUI
import WidgetKit

struct DayEntry: TimelineEntry { let date: Date }
struct DayProvider: TimelineProvider {
  func placeholder(in context: Context) -> DayEntry { DayEntry(date: Date()) }
  func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) { completion(DayEntry(date: Date())) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
    let now = Date()
    let next = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now))!
    completion(Timeline(entries: [DayEntry(date: now)], policy: .after(next)))
  }
}
struct DayWidgetView: View {
  let entry: DayEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("DayDock").font(.headline).foregroundStyle(.indigo)
      Text(entry.date, format: .dateTime.weekday(.wide)).font(.subheadline)
      Text(entry.date, format: .dateTime.day().month(.wide)).font(.title2.bold())
      Spacer(minLength: 0)
      Label("Открыть задачи", systemImage: "calendar").font(.caption)
    }.frame(maxWidth: .infinity, alignment: .leading)
      .widgetURL(URL(string: "daydock:///"))
      .containerBackground(.background, for: .widget)
  }
}
struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DayDockToday", provider: DayProvider()) { DayWidgetView(entry: $0) }
      .configurationDisplayName("Сегодня").description("Дата и переход к задачам дня.")
      .supportedFamilies([.systemSmall, .systemMedium])
  }
}
struct MonthWidgetView: View {
  let date: Date
  private var dates: [Int] {
    var calendar = Calendar.current
    calendar.firstWeekday = 2
    let first = calendar.date(from: calendar.dateComponents([.year,.month], from: date))!
    let offset = (calendar.component(.weekday, from: first) + 5) % 7
    return Array(repeating: 0, count: offset) + Array(calendar.range(of: .day, in: .month, for: date)!)
  }
  var body: some View {
    VStack(spacing: 4) {
      Text(date, format: .dateTime.month(.wide).year()).font(.headline).foregroundStyle(.indigo)
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 3) {
        ForEach(Array(["П","В","С","Ч","П","С","В"].enumerated()), id: \.offset) { _, day in Text(day).font(.caption2).foregroundStyle(.secondary) }
        ForEach(Array(dates.enumerated()), id: \.offset) { _, day in
          Text(day == 0 ? " " : "\(day)").font(.caption2.weight(.semibold))
            .frame(maxWidth: .infinity).padding(.vertical, 2)
            .background(day == Calendar.current.component(.day, from: date) ? Color.indigo.opacity(0.25) : .clear, in: Capsule())
        }
      }
    }.widgetURL(URL(string: "daydock:///"))
      .containerBackground(.background, for: .widget)
  }
}
struct MonthWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DayDockMonth", provider: DayProvider()) { MonthWidgetView(date: $0.date) }
      .configurationDisplayName("Календарь месяца").description("Месяц целиком, текущий день и переход к планировщику.")
      .supportedFamilies([.systemSmall,.systemMedium])
  }
}
struct ActionWidgetView: View {
  let title: String
  let subtitle: String
  let symbol: String
  let destination: String
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: symbol).font(.largeTitle).foregroundStyle(.indigo)
      Spacer(minLength: 0)
      Text(title).font(.headline)
      Text(subtitle).font(.caption).foregroundStyle(.secondary)
    }.frame(maxWidth: .infinity, alignment: .leading)
      .widgetURL(URL(string: "daydock:///\(destination)"))
      .containerBackground(.background, for: .widget)
  }
}
struct NewTaskWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DayDockNewTask", provider: DayProvider()) { _ in
      ActionWidgetView(title: "Новая задача", subtitle: "Добавить в планировщик", symbol: "plus.circle.fill", destination: "task/new")
    }.configurationDisplayName("Добавить задачу").description("Открывает редактор новой задачи.")
      .supportedFamilies([.systemSmall])
  }
}
struct SettingsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DayDockPreferences", provider: DayProvider()) { _ in
      ActionWidgetView(title: "Внешний вид", subtitle: "Настройки темы", symbol: "circle.lefthalf.filled", destination: "settings")
    }.configurationDisplayName("Внешний вид").description("Быстрый переход к теме приложения.")
      .supportedFamilies([.systemSmall])
  }
}
struct NotificationsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DayDockReminders", provider: DayProvider()) { _ in
      ActionWidgetView(title: "Напоминания", subtitle: "Настроить время и звук", symbol: "bell.badge", destination: "settings")
    }.configurationDisplayName("Напоминания").description("Открывает настройки напоминаний.")
      .supportedFamilies([.systemSmall])
  }
}
struct CampusWidgetView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Label("Кампус", systemImage: "map.fill").font(.headline).foregroundStyle(.indigo)
      Canvas { context, size in
        for building in campusBuildings {
          let rect = CGRect(x: building.x / 1500 * size.width, y: building.y / 1500 * size.height, width: max(3, building.width / 1500 * size.width), height: max(3, building.height / 1500 * size.height))
          context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(.indigo.opacity(0.65)))
        }
      }.background(Color.indigo.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
      Text("Открыть интерактивную карту").font(.caption2).foregroundStyle(.secondary)
    }.widgetURL(URL(string: "daydock:///map"))
      .containerBackground(.background, for: .widget)
  }
}
struct CampusWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DayDockCampus", provider: DayProvider()) { _ in CampusWidgetView() }
      .configurationDisplayName("Карта кампуса").description("Схема зданий кампуса и переход к полной карте.")
      .supportedFamilies([.systemSmall,.systemMedium,.systemLarge])
  }
}
@main
struct DayDockWidgets: WidgetBundle {
  var body: some Widget {
    TodayWidget()
    MonthWidget()
    NewTaskWidget()
    CampusWidget()
    NotificationsWidget()
    SettingsWidget()
  }
}

private struct CampusBuilding { let x, y, width, height: Double }
private let campusBuildings: [CampusBuilding] = [
CampusBuilding(x: 462, y: 410, width: 26, height: 110),
CampusBuilding(x: 304, y: 540, width: 122, height: 48),
CampusBuilding(x: 114, y: 398, width: 92, height: 138),
CampusBuilding(x: 115, y: 566, width: 91, height: 138),
CampusBuilding(x: 150, y: 1156, width: 148, height: 140),
CampusBuilding(x: 809, y: 217, width: 55, height: 64),
CampusBuilding(x: 548, y: 500, width: 89, height: 68),
CampusBuilding(x: 111, y: 744, width: 33, height: 72),
CampusBuilding(x: 326, y: 1122, width: 83, height: 68),
CampusBuilding(x: 181, y: 1107, width: 97, height: 73),
CampusBuilding(x: 1186, y: 374, width: 182, height: 140),
CampusBuilding(x: 1229, y: 140, width: 97, height: 130),
CampusBuilding(x: 1112, y: 506, width: 24, height: 104),
CampusBuilding(x: 1127, y: 612, width: 25, height: 98),
CampusBuilding(x: 758, y: 710, width: 319, height: 34),
CampusBuilding(x: 852, y: 576, width: 168, height: 58),
CampusBuilding(x: 814, y: 787, width: 60, height: 102),
CampusBuilding(x: 812, y: 937, width: 53, height: 59),
CampusBuilding(x: 916, y: 927, width: 28, height: 195),
CampusBuilding(x: 917, y: 1124, width: 105, height: 90),
CampusBuilding(x: 822, y: 1124, width: 94, height: 46)
]
