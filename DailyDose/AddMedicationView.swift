import SwiftUI

struct AddMedicationView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let medicationToEdit: Medication?
    let onSaved: (() -> Void)?

    @State private var name: String
    @State private var dosage: String
    @State private var time: Date
    @State private var useStartEnd: Bool
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var reminderEnabled: Bool
    @State private var showSavedAlert = false

    init(medicationToEdit: Medication? = nil, onSaved: (() -> Void)? = nil) {
        self.medicationToEdit = medicationToEdit
        self.onSaved = onSaved

        let defaultEnd = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        _name = State(initialValue: medicationToEdit?.name ?? "")
        _dosage = State(initialValue: medicationToEdit?.dosage ?? "")
        _time = State(initialValue: medicationToEdit?.time ?? Date())
        _useStartEnd = State(initialValue: medicationToEdit?.startDate != nil || medicationToEdit?.endDate != nil)
        _startDate = State(initialValue: medicationToEdit?.startDate ?? Date())
        _endDate = State(initialValue: medicationToEdit?.endDate ?? defaultEnd)
        _notes = State(initialValue: medicationToEdit?.notes ?? "")
        _reminderEnabled = State(initialValue: medicationToEdit?.reminderEnabled ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Info") {
                    TextField("Medication name", text: $name)
                    TextField("Dosage (e.g., 500 mg)", text: $dosage)
                    DatePicker("Daily time", selection: $time, displayedComponents: .hourAndMinute)
                    Toggle("Enable reminder", isOn: $reminderEnabled)
                }

                Section("Schedule") {
                    Toggle("Use start & end date", isOn: $useStartEnd)

                    if useStartEnd {
                        DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Preview") {
                    LabeledContent("Name", value: previewName)
                    LabeledContent("Dosage", value: previewDosage)
                    LabeledContent("Time", value: timeString(time))
                    LabeledContent("Reminder", value: reminderEnabled ? "On" : "Off")
                    if useStartEnd {
                        LabeledContent("Active", value: "\(dateString(startDate)) – \(dateString(endDate))")
                    } else {
                        LabeledContent("Active", value: "Every day")
                    }
                }

                Section {
                    Button {
                        save()
                    } label: {
                        Text(isEditing ? "Update Medication" : "Save Medication")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(saveDisabled)
                }
            }
            .navigationTitle(isEditing ? "Edit Medication" : "Add Medication")
            .alert(isEditing ? "Medication Updated" : "Medication Saved", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {
                    if isEditing {
                        dismiss()
                    }
                }
            } message: {
                Text(isEditing ? "Your changes were saved successfully." : "Medication saved and added to Today’s Schedule.")
            }
        }
    }

    private var isEditing: Bool {
        medicationToEdit != nil
    }

    private var previewName: String {
        cleanedName.isEmpty ? "—" : cleanedName
    }

    private var previewDosage: String {
        cleanedDosage.isEmpty ? "—" : cleanedDosage
    }

    private var cleanedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanedDosage: String {
        dosage.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var saveDisabled: Bool {
        cleanedName.isEmpty || cleanedDosage.isEmpty
    }

    private func save() {
        if let medicationToEdit {
            store.updateMedication(
                id: medicationToEdit.id,
                name: cleanedName,
                dosage: cleanedDosage,
                time: time,
                startDate: useStartEnd ? startDate : nil,
                endDate: useStartEnd ? endDate : nil,
                notes: cleanedNotes,
                reminderEnabled: reminderEnabled
            )
        } else {
            store.addMedication(
                name: cleanedName,
                dosage: cleanedDosage,
                time: time,
                startDate: useStartEnd ? startDate : nil,
                endDate: useStartEnd ? endDate : nil,
                notes: cleanedNotes,
                reminderEnabled: reminderEnabled
            )
        }

        onSaved?()

        if isEditing {
            showSavedAlert = true
        } else {
            resetForm()
            showSavedAlert = true
        }
    }

    private func resetForm() {
        name = ""
        dosage = ""
        time = Date()
        useStartEnd = false
        startDate = Date()
        endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        notes = ""
        reminderEnabled = false
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
