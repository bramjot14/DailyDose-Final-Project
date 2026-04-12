import Foundation

struct DoseLog: Identifiable, Codable, Equatable {
    enum Status: String, Codable, CaseIterable {
        case taken = "Taken"
        case missed = "Missed"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case medicationId
        case medicationName
        case dosage
        case scheduledFor
        case takenAt
        case status
    }

    let id: UUID
    var medicationId: UUID?
    var medicationName: String
    var dosage: String
    var scheduledFor: Date?
    var takenAt: Date
    var status: Status

    init(
        id: UUID = UUID(),
        medicationId: UUID? = nil,
        medicationName: String,
        dosage: String,
        scheduledFor: Date? = nil,
        takenAt: Date,
        status: Status
    ) {
        self.id = id
        self.medicationId = medicationId
        self.medicationName = medicationName
        self.dosage = dosage
        self.scheduledFor = scheduledFor
        self.takenAt = takenAt
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        medicationId = try container.decodeIfPresent(UUID.self, forKey: .medicationId)
        medicationName = try container.decode(String.self, forKey: .medicationName)
        dosage = try container.decode(String.self, forKey: .dosage)
        scheduledFor = try container.decodeIfPresent(Date.self, forKey: .scheduledFor)
        takenAt = try container.decode(Date.self, forKey: .takenAt)
        status = try container.decode(Status.self, forKey: .status)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(medicationId, forKey: .medicationId)
        try container.encode(medicationName, forKey: .medicationName)
        try container.encode(dosage, forKey: .dosage)
        try container.encodeIfPresent(scheduledFor, forKey: .scheduledFor)
        try container.encode(takenAt, forKey: .takenAt)
        try container.encode(status, forKey: .status)
    }
}
