<div align="center">
  <h1 style="border-bottom: none; margin-bottom: 0;">ical-export</h1>
  <h3 style="margin-top: 0; font-weight: normal;">
    a macos eventkit app that dumps a date window to json, recurrences expanded
  </h3>
</div>

<br />

## 🚀 Quick Start

```bash
git clone https://github.com/stevederico/ical-export
cd ical-export
./build.sh
open ical-export.app
```

Grant Calendar access, pick calendars and a range, then **Export JSON**. The file lands on your Desktop as `ical-export-YYYY-MM-DD.json`.

Needs macOS 14+, Xcode CLT, Apple Silicon.

<br />

## ✨ What's Included

### 📅 **Date Window Export**
- **EventKit predicate** loads only events that fall in the selected range
- **Recurrences expand** in-window. Calendar AppleScript does not
- **End is exclusive**. Oct 1 to Nov 1 is October
- **No calendar is preselected**. Toggle the ones you want

### 🧰 **Developer Experience**
- **One Swift file**. No SPM. No Xcode project
- **`./build.sh`** compiles an ad-hoc signed `.app`
- **Pretty JSON** on the Desktop, Finder selects the file

<br />

## 📖 JSON Output

```json
{
  "calendars": ["Work"],
  "eventCount": 1,
  "recurringCount": 1,
  "range": {
    "start": "2026-10-01",
    "end": "2026-11-01",
    "days": 31
  },
  "events": [
    {
      "id": "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE:11111111-2222-3333-4444-555555555555",
      "calendar": "Work",
      "title": "Weekly standup",
      "start": "2026-10-06T09:00:00.000-07:00",
      "end": "2026-10-06T09:30:00.000-07:00",
      "allDay": false,
      "recurring": true,
      "location": "",
      "notes": ""
    }
  ]
}
```

Timestamps use the system time zone. `recurring` is true when the EventKit event has a recurrence rule. Each occurrence is its own row.

<br />

## 🏗️ Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| **Swift** | 6.2 | App |
| **SwiftUI** | macOS 14+ | UI |
| **EventKit** | system | Calendar store, occurrence expansion |
| **AppKit** | system | Desktop path, Privacy Settings |

<br />

## Architecture

`EKEventStore.predicateForEvents(withStart:end:calendars:)` is the whole trick. It returns occurrences that overlap the window, including repeating events whose master start is years earlier.

```swift
let pred = store.predicateForEvents(withStart: startDay, end: endDay, calendars: chosen)
let events = store.events(matching: pred)
```

AppleScript `whose start date` filters the master start, so it misses recurrences. This app does not scan the full calendar history.

<br />

## Contributing

```bash
git clone https://github.com/stevederico/ical-export
cd ical-export
./build.sh
open ical-export.app
```

<br />

## 📬 Community & Support

- **X**: [@stevederico](https://x.com/stevederico)
- **Issues**: [GitHub Issues](https://github.com/stevederico/ical-export/issues)

<br />

## 🙏 Acknowledgements

- [EventKit](https://developer.apple.com/documentation/eventkit) - Calendar store and recurrence expansion
- [SwiftUI](https://developer.apple.com/documentation/swiftui) - App UI

<br />

## 🎪 Related Projects

- [almanac](https://github.com/stevederico/almanac) - Agent-first calendar. Agents write events. Humans subscribe the feed

<br />

## 🚀 Ready to Export?

```bash
./build.sh && open ical-export.app
```

<br />

## 📄 License

MIT License. See [LICENSE](LICENSE).

<br />

---

<div align="center">
  <p>
    Built with ❤️ by <a href="https://github.com/stevederico">Steve Derico</a>
  </p>
  <p>
    <a href="https://github.com/stevederico/ical-export">Star on GitHub</a>
  </p>
</div>
