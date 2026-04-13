import SwiftUI

struct TodayScheduleView: View {
    @EnvironmentObject private var store: AppStore

    @State private var searchText = ""
    @State private var filter: ScheduleFilter = .all
    @State private var medicationToEdit: Medication?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            TinySummaryCard(title: "Scheduled", value: store.todayScheduledCount, systemImage: "calendar.badge.clock")
                            TinySummaryCard(title: "Taken", value: store.todayTakenCount, systemImage: "checkmark.circle.fill")
                            TinySummaryCard(title: "Remaining", value: store.todayRemainingCount, systemImage: "hourglass")
                        }

                        Picker("Filter", selection: $filter) {
                            ForEach(ScheduleFilter.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                }

                if displayedMedications.isEmpty {
                    Section {
                        EmptyStateSection(
                            title: searchText.isEmpty ? "No medications for today" : "No matching medications",
                            systemImage: searchText.isEmpty ? "calendar.badge.exclamationmark" : "magnifyingglass",
                            message: searchText.isEmpty ? "Add a medication to build your schedule." : "Try a different name or filter."
                        )
                    }
                } else {
                    ForEach(sections) { section in
                        if !section.items.isEmpty {
                            Section(section.title) {
                                ForEach(section.items) { medication in
                                    row(for: medication)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(todayTitle)
            .searchable(text: $searchText, prompt: "Search medications")
            .sheet(item: $medicationToEdit) { medication in
                AddMedicationView(medicationToEdit: medication)
            }
        }
    }

    private func row(for medication: Medication) -> some View {
        let scheduledFor = medication.scheduledDate(on: Date())
        let currentStatus = status(for: medication)

        return DoseRowView(
            med: medication,
            status: currentStatus,
            scheduledFor: scheduledFor,
            todayLog: store.todayLog(for: medication),
            onTaken: { store.markTaken(medication) },
            onMissed: { store.markMissed(medication) },
            onReset: { store.resetTodayStatus(for: medication) }
        )
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button("Edit") {
                medicationToEdit = medication
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if currentStatus != .taken {
                Button("Taken") {
                    store.markTaken(medication)
                }
                .tint(.green)
            }

            if currentStatus != .missed {
                Button("Missed") {
                    store.markMissed(medication)
                }
                .tint(.orange)
            }

            Button("Delete", role: .destructive) {
                store.removeMedication(medication)
            }
        }
    }

    private var displayedMedications: [Medication] {
        store.activeMedications.filter { medication in
            let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                medication.name.localizedCaseInsensitiveContains(searchText) ||
                medication.dosage.localizedCaseInsensitiveContains(searchText)

            guard matchesSearch else { return false }

            switch filter {
            case .all:
                return true
            case .actionNeeded:
                return store.todayLog(for: medication) == nil
            case .completed:
                if let log = store.todayLog(for: medication) {
                    return log.status == .taken
                }
                return false
            case .missed:
                if let log = store.todayLog(for: medication) {
                    return log.status == .missed
                }
                return false
            }
        }
    }

    private var sections: [ScheduleSection] {
        let overdue = displayedMedications.filter { status(for: $0) == .overdue }
        let dueNow = displayedMedications.filter { status(for: $0) == .dueNow }
        let upcoming = displayedMedications.filter { status(for: $0) == .upcoming }
        let taken = displayedMedications.filter { status(for: $0) == .taken }
        let missed = displayedMedications.filter { status(for: $0) == .missed }

        return [
            ScheduleSection(title: "Overdue", items: overdue),
            ScheduleSection(title: "Due Now", items: dueNow),
            ScheduleSection(title: "Upcoming", items: upcoming),
            ScheduleSection(title: "Taken", items: taken),
            ScheduleSection(title: "Missed", items: missed)
        ]
    }

    private func status(for medication: Medication) -> DoseRowView.MedStatus {
        if let todayLog = store.todayLog(for: medication) {
            return todayLog.status == .taken ? .taken : .missed
        }

        let now = Date()
        let scheduled = medication.scheduledDate(on: now)
        let difference = scheduled.timeIntervalSince(now)

        if abs(difference) <= 15 * 60 { return .dueNow }
        if difference < -15 * 60 { return .overdue }
        return .upcoming
    }

    private var todayTitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}

private struct ScheduleSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [Medication]
}

private struct TinySummaryCard: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
            Text("\(value)")
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private enum ScheduleFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case actionNeeded = "Pending"
    case completed = "Taken"
    case missed = "Missed"

    var id: String { rawValue }
}


private struct EmptyStateSection: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 30))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}
