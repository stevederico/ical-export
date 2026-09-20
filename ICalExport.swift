import AppKit
import EventKit
import SwiftUI

@main
struct ICalExportApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 420, minHeight: 480)
    }
    .windowResizability(.contentSize)
  }
}

@Observable
final class ExportModel {
  let store = EKEventStore()
  var isAuthorized = false
  var status = "Grant Calendar access to export."
  var calendars: [EKCalendar] = []
  var selected = Set<String>()
  var start: Date
  var end: Date
  var lastPath = ""

  init() {
    let cal = Calendar.current
    let now = Date()
    let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
    start = monthStart
    end = cal.date(byAdding: .month, value: 1, to: monthStart) ?? now
  }

  func requestAccess() {
    store.requestFullAccessToEvents { [weak self] granted, error in
      DispatchQueue.main.async {
        guard let self else { return }
        self.isAuthorized = granted
        if let error {
          self.status = error.localizedDescription
          return
        }
        if !granted {
          self.status = "Calendar access denied. Enable it in System Settings."
          return
        }
        self.reloadCalendars()
      }
    }
  }

  func reloadCalendars() {
    calendars = store.calendars(for: .event).sorted { $0.title < $1.title }
    status = calendars.isEmpty ? "No calendars." : "Pick calendars and a date range."
  }

  func exportJSON() {
    let cal = Calendar.current
    let startDay = cal.startOfDay(for: start)
    let endDay = cal.startOfDay(for: end)
    let days = cal.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    if days < 1 {
      status = "End must be after Start."
      return
    }
    let chosen = calendars.filter { selected.contains($0.calendarIdentifier) }
    if chosen.isEmpty {
      status = "Select at least one calendar."
      return
    }

    let pred = store.predicateForEvents(withStart: startDay, end: endDay, calendars: chosen)
    let events = store.events(matching: pred).sorted { $0.startDate < $1.startDate }

    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    iso.timeZone = TimeZone.current

    let dayFmt = DateFormatter()
    dayFmt.calendar = cal
    dayFmt.timeZone = TimeZone.current
    dayFmt.dateFormat = "yyyy-MM-dd"

    var rows: [[String: Any]] = []
    rows.reserveCapacity(events.count)
    var recurringCount = 0
    for event in events {
      if event.hasRecurrenceRules { recurringCount += 1 }
      var row: [String: Any] = [
        "id": event.eventIdentifier ?? "",
        "calendar": event.calendar?.title ?? "",
        "title": event.title ?? "",
        "start": iso.string(from: event.startDate),
        "end": iso.string(from: event.endDate),
        "allDay": event.isAllDay,
        "recurring": event.hasRecurrenceRules,
        "location": event.location ?? "",
        "notes": event.notes ?? "",
      ]
      if event.isAllDay {
        row["startDay"] = dayFmt.string(from: event.startDate)
      }
      rows.append(row)
    }

    let payload: [String: Any] = [
      "range": [
        "start": dayFmt.string(from: startDay),
        "end": dayFmt.string(from: endDay),
        "days": days,
      ],
      "calendars": chosen.map(\.title),
      "eventCount": rows.count,
      "recurringCount": recurringCount,
      "events": rows,
    ]

    guard JSONSerialization.isValidJSONObject(payload),
          let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    else {
      status = "JSON encode failed."
      return
    }

    let name = "ical-export-\(dayFmt.string(from: startDay)).json"
    let url = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Desktop")
      .appendingPathComponent(name)
    do {
      try data.write(to: url, options: .atomic)
      lastPath = url.path
      status = "Wrote \(rows.count) events (\(recurringCount) recurring) to Desktop/\(name)"
      NSWorkspace.shared.activateFileViewerSelecting([url])
    } catch {
      status = error.localizedDescription
    }
  }
}

struct ContentView: View {
  @State private var model = ExportModel()

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("ical-export")
        .font(.title2.bold())
      Text("EventKit date window only. Recurrences expand. JSON lands on Desktop.")
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      if !model.isAuthorized {
        Button("Grant Access") { model.requestAccess() }
          .keyboardShortcut(.defaultAction)
        Button("Open Privacy Settings") { openPrivacySettings() }
      } else {
        DatePicker("Start Date", selection: $model.start, displayedComponents: .date)
        DatePicker("End Date", selection: $model.end, displayedComponents: .date)
        Text("End is exclusive. Oct 1 to Nov 1 is October.")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("Calendars")
          .font(.headline)
        ScrollView {
          VStack(alignment: .leading, spacing: 6) {
            ForEach(model.calendars, id: \.calendarIdentifier) { calendar in
              Toggle(isOn: Binding(
                get: { model.selected.contains(calendar.calendarIdentifier) },
                set: { on in
                  if on { model.selected.insert(calendar.calendarIdentifier) }
                  else { model.selected.remove(calendar.calendarIdentifier) }
                }
              )) {
                Text(calendar.title)
              }
            }
          }
        }
        .frame(maxHeight: 180)

        Button("Export JSON") { model.exportJSON() }
          .keyboardShortcut(.defaultAction)
      }

      Text(model.status)
        .font(.callout)
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
    }
    .padding(20)
    .onAppear { model.requestAccess() }
  }
}

private func openPrivacySettings() {
  let url = URL(string: "x-apple.systemsettings:com.apple.settings.PrivacySecurity.extension?Privacy_Calendars")
  if let url {
    NSWorkspace.shared.open(url)
  }
}
