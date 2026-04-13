import SwiftUI

struct DoseRowView: View {
    let med: Medication
    let status: MedStatus
    let scheduledFor: Date
    let todayLog: DoseLog?
    let onTaken: () -> Void
    let onMissed: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "pills.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(med.name)
                                .font(.headline)
                            Text("\(timeString(scheduledFor)) • \(med.dosage)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        StatusBadge(status: status)
                    }

                    if !med.trimmedNotes.isEmpty {
                        Text(med.trimmedNotes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let todayLog {
                        Text(logSummary(todayLog))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 10) {
                switch status {
                case .taken, .missed:
                    Button("Reset") {
                        onReset()
                    }
                    .buttonStyle(.bordered)
                default:
                    Button("Taken") {
                        onTaken()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Missed") {
                        onMissed()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
        }
        .padding(.vertical, 6)
    }

    enum MedStatus {
        case dueNow
        case overdue
        case upcoming
        case taken
        case missed
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func logSummary(_ log: DoseLog) -> String {
        let recordedAt = timeString(log.takenAt)
        switch log.status {
        case .taken:
            return "Marked as taken at \(recordedAt)"
        case .missed:
            return "Marked as missed at \(recordedAt)"
        }
    }
}

private struct StatusBadge: View {
    let status: DoseRowView.MedStatus

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .dueNow: return "Due Now"
        case .overdue: return "Overdue"
        case .upcoming: return "Upcoming"
        case .taken: return "Taken"
        case .missed: return "Missed"
        }
    }

    private var background: Color {
        switch status {
        case .dueNow: return Color.orange.opacity(0.18)
        case .overdue: return Color.red.opacity(0.18)
        case .upcoming: return Color.blue.opacity(0.16)
        case .taken: return Color.green.opacity(0.18)
        case .missed: return Color.gray.opacity(0.22)
        }
    }

    private var foreground: Color {
        switch status {
        case .dueNow: return .orange
        case .overdue: return .red
        case .upcoming: return .blue
        case .taken: return .green
        case .missed: return .gray
        }
    }
}
