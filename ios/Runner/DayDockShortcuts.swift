import AppIntents
import Foundation

@available(iOS 18.0, *)
enum PlannerDestination: String, AppEnum {
  case calendar, map, newTask, settings
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Раздел DayDock"
  static var caseDisplayRepresentations: [PlannerDestination: DisplayRepresentation] = [
    .calendar: "Календарь", .map: "Карта кампуса", .newTask: "Новая задача", .settings: "Настройки"
  ]
  var path: String {
    switch self { case .calendar: return "/"; case .map: return "/map"; case .newTask: return "/task/new"; case .settings: return "/settings" }
  }
}
@available(iOS 18.0, *)
struct OpenPlannerIntent: AppIntent {
  static var title: LocalizedStringResource = "Открыть раздел DayDock"
  static var description = IntentDescription("Открывает календарь, карту, новую задачу или настройки планировщика.")
  static var openAppWhenRun = true
  @Parameter(title: "Раздел", default: .calendar) var destination: PlannerDestination
  init() {}
  init(_ destination: PlannerDestination) { self.destination = destination }
  func perform() async throws -> some IntentResult & OpensIntent {
    .result(opensIntent: OpenURLIntent(URL(string: "daydock://\(destination.path)")!))
  }
}
@available(iOS 18.0, *)
struct DraftTaskIntent: AppIntent {
  static var title: LocalizedStringResource = "Подготовить задачу в DayDock"
  static var description = IntentDescription("Открывает редактор с произнесённым названием. Нажмите Сохранить в приложении, чтобы добавить задачу.")
  static var openAppWhenRun = true
  @Parameter(title: "Название задачи") var taskTitle: String
  func perform() async throws -> some IntentResult & OpensIntent {
    var url = URLComponents(string: "daydock:///task/new")!
    url.queryItems = [URLQueryItem(name: "title", value: taskTitle)]
    return .result(opensIntent: OpenURLIntent(url.url!))
  }
}
@available(iOS 18.0, *)
struct DayDockShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(intent: OpenPlannerIntent(.calendar), phrases: ["Открой календарь в \(.applicationName)"], shortTitle: "Календарь", systemImageName: "calendar")
    AppShortcut(intent: OpenPlannerIntent(.map), phrases: ["Открой карту в \(.applicationName)"], shortTitle: "Карта кампуса", systemImageName: "map")
    AppShortcut(intent: DraftTaskIntent(), phrases: ["Подготовь задачу в \(.applicationName)"], shortTitle: "Новая задача", systemImageName: "plus.circle")
  }
}
