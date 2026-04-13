import SwiftUI

struct HistoryRowView: View {
    let log: DoseLog

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.status == .taken ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(log.status == .taken ? .green : .orange)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(log.medicationName)
                        .font(.headline)
                    Spacer()
                    Text(log.status.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((log.status == .taken ? Color.green : Color.orange).opacity(0.15))
                        .foregroundStyle(log.status == .taken ? .green : .orange)
                        .clipShape(Capsule())
                }

                Text(log.dosage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let scheduledFor = log.scheduledFor {
                    Text("Scheduled: \(timeString(scheduledFor))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Recorded: \(timeString(log.takenAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
