# DailyDose — Final Implementation

DailyDose is a SwiftUI medication reminder app that helps users manage their daily schedule, log whether doses were taken or missed, review medication history, and monitor adherence over time.

This project extends the early prototype into a more complete final implementation with stronger data handling, better daily scheduling logic, editing support, progress tracking, and reminder support.

## Final implementation highlights

- Daily schedule screen with:
  - summary cards for scheduled, taken, and remaining medications
  - search and segmented filtering
  - automatic grouping into Overdue, Due Now, Upcoming, Taken, and Missed sections
- Add Medication screen with:
  - input validation
  - optional start and end dates
  - optional notes
  - daily reminder toggle
  - preview section before saving
- Edit existing medications from the Today screen
- Delete medications from the Today screen
- Mark medications as **Taken** or **Missed**
- Reset the current day’s status for a medication
- History screen with:
  - grouped daily logs
  - search and Taken/Missed filtering
  - delete individual history records
  - clear all history option
- Insights screen with:
  - today summary
  - 7-day adherence percentage
  - current streak
  - last 7 days progress view
  - reminder count overview
- Local persistence using `UserDefaults`
- Local notification scheduling for medications with reminders enabled
- Backward-compatible model decoding so older prototype data can still load safely

## Important improvement from prototype

A key issue in the early prototype was that medication times were stored as full `Date` values and then compared directly against the current moment. That approach can break daily schedules after the calendar day changes.

The final implementation fixes this by treating the saved medication time as a recurring daily hour/minute and rebuilding the scheduled time for **today** before showing Due Now, Overdue, or Upcoming states.

## Project structure

```text
DailyDose/
├── AddMedicationView.swift
├── AppStore.swift
├── ContentView.swift
├── DailyDoseApp.swift
├── DoseLog.swift
├── DoseRowView.swift
├── HistoryRowView.swift
├── Info.plist
├── Medication.swift
├── MedicationHistoryView.swift
├── SplashView.swift
├── TodayScheduleView.swift
└── Assets.xcassets/
```

## Main files and responsibilities

- `AppStore.swift`
  - app state management
  - local persistence
  - medication CRUD logic
  - daily log handling
  - adherence calculations
  - notification scheduling
- `Medication.swift`
  - medication model
  - schedule/date activity logic
  - backward-compatible decoding defaults
- `DoseLog.swift`
  - history log model for Taken and Missed events
- `TodayScheduleView.swift`
  - daily dashboard with grouped medication sections
- `AddMedicationView.swift`
  - add and edit medication form
- `MedicationHistoryView.swift`
  - searchable and filterable medication history
- `ContentView.swift`
  - tab navigation and Insights screen

## How to run

1. Open `DailyDose.xcodeproj` in Xcode.
2. Select an iPhone simulator or a physical iPhone.
3. Build and run the project with `⌘R`.
4. When prompted, allow notifications if you want reminder support.

## Suggested testing checklist

- Add a new medication and confirm it appears in **Today**.
- Edit a medication and verify the updated details appear correctly.
- Swipe a medication row and test **Taken**, **Missed**, and **Delete** actions.
- Reset a Taken or Missed status and confirm the row becomes pending again.
- Enable a reminder and verify notification permission is requested.
- Check that logs appear in **History** after marking items Taken or Missed.
- Use the **Insights** tab to verify the 7-day adherence numbers update.
- Close and relaunch the app to confirm medications and history persist.

## Notes

- Data is stored locally on device using `UserDefaults`.
- Notifications are local notifications scheduled on the device.
- The project targets iOS 16 and uses SwiftUI.
