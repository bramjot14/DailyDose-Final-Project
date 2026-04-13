import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayScheduleView()
                .tabItem { Label("Today", systemImage: "calendar") }

            AddMedicationView()
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }

            MedicationHistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
    }
}

private struct InsightsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        StatCard(title: "Medications", value: "\(store.medications.count)", subtitle: "total saved", systemImage: "pills.fill")
                        StatCard(title: "7-Day Adherence", value: "\(store.adherence7DayPercentage)%", subtitle: "completion rate", systemImage: "chart.line.uptrend.xyaxis")
                    }

                    HStack(spacing: 12) {
                        StatCard(title: "Today Remaining", value: "\(store.todayRemainingCount)", subtitle: "still pending", systemImage: "hourglass")
                        StatCard(title: "Current Streak", value: "\(store.currentStreak)", subtitle: "perfect days", systemImage: "flame.fill")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today Summary")
                            .font(.headline)

                        SummaryStrip(
                            items: [
                                ("Scheduled", "\(store.todayScheduledCount)", "calendar.badge.clock"),
                                ("Taken", "\(store.todayTakenCount)", "checkmark.circle.fill"),
                                ("Missed", "\(store.todayMissedCount)", "xmark.circle.fill")
                            ]
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 7 Days")
                            .font(.headline)

                        if store.last7DaysProgress.allSatisfy({ $0.total == 0 }) {
                            EmptyChartStateView(
                                title: "No schedule data yet",
                                systemImage: "chart.bar.xaxis",
                                message: "Add a medication to start tracking progress."
                            )
                        } else {
                            ForEach(store.last7DaysProgress) { day in
                                ProgressRow(progress: day)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reminder Status")
                            .font(.headline)

                        let remindersEnabled = store.medications.filter(\.reminderEnabled).count
                        Label("\(remindersEnabled) medication reminder(s) enabled", systemImage: "bell.badge.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Local daily reminders are scheduled when reminders are enabled for a medication.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding()
            }
            .navigationTitle("Insights")
            .toolbar {
                if !store.medications.isEmpty || !store.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Reset App Data", role: .destructive) {
                            showResetAlert = true
                        }
                    }
                }
            }
            .alert("Reset all data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.clearAllData()
                }
            } message: {
                Text("This removes all medications and history stored on the device.")
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct SummaryStrip: View {
    let items: [(String, String, String)]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(items, id: \.0) { item in
                VStack(spacing: 8) {
                    Image(systemName: item.2)
                        .font(.title3)
                    Text(item.1)
                        .font(.headline)
                    Text(item.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

private struct ProgressRow: View {
    let progress: AppStore.DailyProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dayLabel)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(progress.taken)/\(progress.total) • \(progress.percentage)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(progress.taken), total: Double(max(progress.total, 1)))
        }
        .padding(.vertical, 4)
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: progress.date)
    }
}


private struct EmptyChartStateView: View {
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
        .padding(.vertical, 24)
    }
}
