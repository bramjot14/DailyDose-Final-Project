import SwiftUI

struct MedicationHistoryView: View {
    @EnvironmentObject private var store: AppStore

    @State private var searchText = ""
    @State private var filter: HistoryFilter = .all
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("History Filter", selection: $filter) {
                        ForEach(HistoryFilter.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if filteredLogs.isEmpty {
                    Section {
                        HistoryEmptyStateView(
                            title: "No history yet",
                            systemImage: "clock.arrow.circlepath",
                            message: "Mark a dose as taken or missed to see it here."
                        )
                    }
                } else {
                    ForEach(sectionDates, id: \.self) { day in
                        Section(sectionTitle(for: day)) {
                            ForEach(groupedLogs[day] ?? []) { log in
                                HistoryRowView(log: log)
                                    .swipeActions {
                                        Button("Delete", role: .destructive) {
                                            store.deleteLog(log)
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search history")
            .toolbar {
                if !store.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            showClearAlert = true
                        }
                    }
                }
            }
            .alert("Clear all history?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    store.clearHistory()
                }
            } message: {
                Text("This removes all taken and missed logs from the device.")
            }
        }
    }

    private var filteredLogs: [DoseLog] {
        store.history.filter { log in
            let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                log.medicationName.localizedCaseInsensitiveContains(searchText) ||
                log.dosage.localizedCaseInsensitiveContains(searchText)

            guard matchesSearch else { return false }

            switch filter {
            case .all:
                return true
            case .taken:
                return log.status == .taken
            case .missed:
                return log.status == .missed
            }
        }
    }

    private var groupedLogs: [Date: [DoseLog]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredLogs) { calendar.startOfDay(for: $0.takenAt) }
    }

    private var sectionDates: [Date] {
        groupedLogs.keys.sorted(by: >)
    }

    private func sectionTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private enum HistoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case taken = "Taken"
    case missed = "Missed"

    var id: String { rawValue }
}


private struct HistoryEmptyStateView: View {
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
