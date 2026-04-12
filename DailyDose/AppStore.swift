import Foundation
import UserNotifications

@MainActor
final class AppStore: ObservableObject {
    struct DailyProgress: Identifiable {
        let date: Date
        let total: Int
        let taken: Int

        var id: Date { date }

        var percentage: Int {
            guard total > 0 else { return 0 }
            return Int((Double(taken) / Double(total) * 100).rounded())
        }
    }

    @Published var medications: [Medication] {
        didSet {
            save()
            Task { await NotificationManager.shared.reschedule(for: medications) }
        }
    }

    @Published var history: [DoseLog] {
        didSet { save() }
    }

    private let medicationsKey = "DailyDose.medications"
    private let historyKey = "DailyDose.history"
    private let seededKey = "DailyDose.seededPrototypeDefaults"

    init() {
        let decoder = JSONDecoder()

        if let medicationData = UserDefaults.standard.data(forKey: medicationsKey),
           let savedMedications = try? decoder.decode([Medication].self, from: medicationData) {
            medications = Self.sorted(savedMedications)
        } else if UserDefaults.standard.bool(forKey: seededKey) {
            medications = []
        } else {
            medications = Self.sampleMedications()
            UserDefaults.standard.set(true, forKey: seededKey)
        }

        if let historyData = UserDefaults.standard.data(forKey: historyKey),
           let savedHistory = try? decoder.decode([DoseLog].self, from: historyData) {
            history = savedHistory.sorted { $0.takenAt > $1.takenAt }
        } else {
            history = []
        }

        Task { await NotificationManager.shared.reschedule(for: medications) }
    }

    var activeMedications: [Medication] {
        medications
            .filter { $0.isActiveToday }
            .sorted { $0.scheduledDate(on: Date()) < $1.scheduledDate(on: Date()) }
    }

    var todayScheduledCount: Int {
        activeMedications.count
    }

    var todayTakenCount: Int {
        activeMedications.filter { todayLog(for: $0)?.status == .taken }.count
    }

    var todayMissedCount: Int {
        activeMedications.filter { todayLog(for: $0)?.status == .missed }.count
    }

    var todayRemainingCount: Int {
        max(todayScheduledCount - todayTakenCount - todayMissedCount, 0)
    }

    var adherence7DayPercentage: Int {
        let progress = last7DaysProgress
        let totalScheduled = progress.reduce(0) { $0 + $1.total }
        let totalTaken = progress.reduce(0) { $0 + $1.taken }
        guard totalScheduled > 0 else { return 0 }
        return Int((Double(totalTaken) / Double(totalScheduled) * 100).rounded())
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0

        for offset in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { break }
            let scheduled = scheduledCount(on: day)
            if scheduled == 0 { continue }

            let taken = takenCount(on: day)
            if taken == scheduled {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    var last7DaysProgress: [DailyProgress] {
        let calendar = Calendar.current

        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let total = scheduledCount(on: day)
            let taken = takenCount(on: day)
            return DailyProgress(date: day, total: total, taken: min(taken, total))
        }
    }

    func addMedication(
        name: String,
        dosage: String,
        time: Date,
        startDate: Date?,
        endDate: Date?,
        notes: String,
        reminderEnabled: Bool
    ) {
        let medication = Medication(
            name: name,
            dosage: dosage,
            time: time,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            reminderEnabled: reminderEnabled
        )

        medications = Self.sorted(medications + [medication])
    }

    func updateMedication(
        id: UUID,
        name: String,
        dosage: String,
        time: Date,
        startDate: Date?,
        endDate: Date?,
        notes: String,
        reminderEnabled: Bool
    ) {
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }

        medications[index].name = name
        medications[index].dosage = dosage
        medications[index].time = time
        medications[index].startDate = startDate
        medications[index].endDate = endDate
        medications[index].notes = notes
        medications[index].reminderEnabled = reminderEnabled
        medications = Self.sorted(medications)
    }

    func removeMedication(_ medication: Medication) {
        medications.removeAll { $0.id == medication.id }
    }

    func todayLog(for medication: Medication) -> DoseLog? {
        let calendar = Calendar.current

        return history.first {
            calendar.isDate($0.takenAt, inSameDayAs: Date()) &&
            (($0.medicationId == medication.id) || ($0.medicationId == nil && $0.medicationName == medication.name))
        }
    }

    func markTaken(_ medication: Medication) {
        upsertLog(for: medication, status: .taken)

        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index].lastTakenAt = Date()
        }
    }

    func markMissed(_ medication: Medication) {
        upsertLog(for: medication, status: .missed)
    }

    func resetTodayStatus(for medication: Medication) {
        let calendar = Calendar.current
        history.removeAll {
            calendar.isDate($0.takenAt, inSameDayAs: Date()) &&
            (($0.medicationId == medication.id) || ($0.medicationId == nil && $0.medicationName == medication.name))
        }

        if let index = medications.firstIndex(where: { $0.id == medication.id }),
           let lastTakenAt = medications[index].lastTakenAt,
           calendar.isDateInToday(lastTakenAt) {
            medications[index].lastTakenAt = nil
        }
    }

    func deleteLog(_ log: DoseLog) {
        history.removeAll { $0.id == log.id }
    }

    func clearHistory() {
        history.removeAll()
    }

    func clearAllData() {
        medications.removeAll()
        history.removeAll()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    func requestNotificationPermission() {
        Task { _ = await NotificationManager.shared.requestAuthorization() }
    }

    private func upsertLog(for medication: Medication, status: DoseLog.Status) {
        let scheduledTime = medication.scheduledDate(on: Date())
        let calendar = Calendar.current

        if let existingIndex = history.firstIndex(where: {
            calendar.isDate($0.takenAt, inSameDayAs: Date()) &&
            (($0.medicationId == medication.id) || ($0.medicationId == nil && $0.medicationName == medication.name))
        }) {
            history[existingIndex].status = status
            history[existingIndex].takenAt = Date()
            history[existingIndex].scheduledFor = scheduledTime
            history[existingIndex].dosage = medication.dosage
            history[existingIndex].medicationName = medication.name
            history[existingIndex].medicationId = medication.id
        } else {
            history.insert(
                DoseLog(
                    medicationId: medication.id,
                    medicationName: medication.name,
                    dosage: medication.dosage,
                    scheduledFor: scheduledTime,
                    takenAt: Date(),
                    status: status
                ),
                at: 0
            )
        }

        history.sort { $0.takenAt > $1.takenAt }
    }

    private func scheduledCount(on day: Date) -> Int {
        medications.filter { $0.isActive(on: day) }.count
    }

    private func takenCount(on day: Date) -> Int {
        let calendar = Calendar.current
        let matchingLogs = history.filter {
            calendar.isDate($0.takenAt, inSameDayAs: day) && $0.status == .taken
        }

        let ids = Set(matchingLogs.compactMap { $0.medicationId })
        let nameCount = Set(matchingLogs.filter { $0.medicationId == nil }.map { $0.medicationName }).count
        return ids.count + nameCount
    }

    private func save() {
        let encoder = JSONEncoder()

        if let medicationData = try? encoder.encode(medications) {
            UserDefaults.standard.set(medicationData, forKey: medicationsKey)
        }

        if let historyData = try? encoder.encode(history) {
            UserDefaults.standard.set(historyData, forKey: historyKey)
        }
    }

    private static func sorted(_ medications: [Medication]) -> [Medication] {
        medications.sorted { $0.scheduledDate(on: Date()) < $1.scheduledDate(on: Date()) }
    }

    private static func sampleMedications() -> [Medication] {
        let calendar = Calendar.current
        let now = Date()
        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        let noon = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now) ?? now
        let night = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now) ?? now

        return [
            Medication(
                name: "Vitamin D",
                dosage: "1000 IU",
                time: morning,
                notes: "Take after breakfast.",
                reminderEnabled: true
            ),
            Medication(
                name: "Omega 3",
                dosage: "1 capsule",
                time: noon,
                notes: "Take with lunch."
            ),
            Medication(
                name: "Magnesium",
                dosage: "250 mg",
                time: night,
                notes: "Use before bedtime for consistency."
            )
        ]
    }
}

actor NotificationManager {
    static let shared = NotificationManager()
    private let identifierPrefix = "DailyDose.medication."

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func reschedule(for medications: [Medication]) async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let existingIDs = requests.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: existingIDs)

        for medication in medications where medication.reminderEnabled && medication.isActiveToday {
            let granted = await requestAuthorization()
            guard granted else { continue }

            let scheduled = medication.scheduledDate(on: Date())
            let components = Calendar.current.dateComponents([.hour, .minute], from: scheduled)

            let content = UNMutableNotificationContent()
            content.title = medication.name
            content.body = "It’s time to take \(medication.dosage)."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: identifierPrefix + medication.id.uuidString,
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }
}
