import Foundation

struct Medication: Identifiable, Equatable, Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case dosage
        case time
        case startDate
        case endDate
        case lastTakenAt
        case notes
        case reminderEnabled
        case isArchived
        case createdAt
    }

    let id: UUID
    var name: String
    var dosage: String
    var time: Date
    var startDate: Date?
    var endDate: Date?
    var lastTakenAt: Date?
    var notes: String
    var reminderEnabled: Bool
    var isArchived: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        dosage: String,
        time: Date,
        startDate: Date? = nil,
        endDate: Date? = nil,
        lastTakenAt: Date? = nil,
        notes: String = "",
        reminderEnabled: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.time = time
        self.startDate = startDate
        self.endDate = endDate
        self.lastTakenAt = lastTakenAt
        self.notes = notes
        self.reminderEnabled = reminderEnabled
        self.isArchived = isArchived
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        dosage = try container.decode(String.self, forKey: .dosage)
        time = try container.decode(Date.self, forKey: .time)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        lastTakenAt = try container.decodeIfPresent(Date.self, forKey: .lastTakenAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(dosage, forKey: .dosage)
        try container.encode(time, forKey: .time)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(lastTakenAt, forKey: .lastTakenAt)
        try container.encode(notes, forKey: .notes)
        try container.encode(reminderEnabled, forKey: .reminderEnabled)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(createdAt, forKey: .createdAt)
    }

    var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func scheduledDate(on date: Date, using calendar: Calendar = .current) -> Date {
        let baseDay = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.hour, .minute], from: time)

        return calendar.date(
            bySettingHour: components.hour ?? 9,
            minute: components.minute ?? 0,
            second: 0,
            of: baseDay
        ) ?? date
    }

    func isActive(on date: Date = Date(), using calendar: Calendar = .current) -> Bool {
        if isArchived { return false }

        let targetDay = calendar.startOfDay(for: date)

        if let startDate, calendar.startOfDay(for: startDate) > targetDay {
            return false
        }

        if let endDate, calendar.startOfDay(for: endDate) < targetDay {
            return false
        }

        return true
    }

    var isActiveToday: Bool {
        isActive(on: Date())
    }
}
