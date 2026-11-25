import SwiftData
import SwiftUI

/// Sheet for creating a new goal or editing an existing one.
struct AddEditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notifications

    @State private var form: GoalFormModel
    @State private var showPermissionAlert = false
    @FocusState private var isTitleFocused: Bool

    private let goal: Goal?

    init(goal: Goal? = nil, template: GoalTemplate? = nil) {
        self.goal = goal
        _form = State(initialValue: GoalFormModel(goal: goal, template: template))
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                categorySection
                durationSection
                reminderSection
            }
            .navigationTitle(form.isEditing ? Text("Edit Goal") : Text("New Goal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: {
                        form.isEditing ? Text("Save") : Text("Add")
                    }
                    .fontWeight(.semibold)
                    .disabled(!form.isValid)
                }
            }
            .task {
                guard !form.isEditing, form.title.isEmpty else { return }
                try? await Task.sleep(for: .milliseconds(450))
                isTitleFocused = true
            }
            .onChange(of: form.reminderEnabled) { _, isOn in
                guard isOn else { return }
                // Ask for permission in context, right when the user opts in.
                Task {
                    let granted = await notifications.requestAuthorizationIfNeeded()
                    if !granted { showPermissionAlert = true }
                }
            }
            .alert("Notifications Are Off", isPresented: $showPermissionAlert) {
                Button("Open Settings") { notifications.openSystemSettings() }
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("To get your daily reminder, allow notifications for Ritm in Settings.")
            }
        }
    }

    // MARK: Sections

    private var titleSection: some View {
        Section {
            TextField("e.g., \(GoalFormModel.titlePlaceholder)", text: $form.title)
                .font(.body.weight(.medium))
                .focused($isTitleFocused)
                .submitLabel(.done)
                .textInputAutocapitalization(.sentences)
        } header: {
            Text("Goal")
        } footer: {
            Text("Make it specific and doable every day.")
        }
    }

    private var categorySection: some View {
        Section("Life Category") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(GoalCategory.allCases) { category in
                    CategoryTile(category: category, isSelected: form.category == category) {
                        withAnimation(.snappy) { form.category = category }
                    }
                }
            }
            .padding(.vertical, 6)
            .sensoryFeedback(.selection, trigger: form.category)
        }
    }

    private var durationSection: some View {
        Section {
            HStack(spacing: 8) {
                ForEach(GoalFormModel.durationPresets, id: \.self) { days in
                    DurationChip(days: days, isSelected: form.targetDays == days, color: form.category.color) {
                        withAnimation(.snappy) { form.targetDays = days }
                    }
                }
            }
            .padding(.vertical, 4)
            .sensoryFeedback(.selection, trigger: form.targetDays)

            Stepper(value: $form.targetDays, in: GoalFormModel.dayRange) {
                HStack {
                    form.isCustomDuration ? Text("Custom") : Text("Fine-tune")
                    Spacer()
                    Text(form.targetDays.daysLabel)
                        .monospacedDigit()
                        .foregroundStyle(form.isCustomDuration ? form.category.color : .secondary)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                }
            }
        } header: {
            Text("Target Duration")
        } footer: {
            Text("Check in on \(form.targetDays.daysLabel) to complete the challenge — as early as \(form.earliestFinishDate(from: goal?.startDate ?? .now).formatted(.dateTime.month(.abbreviated).day())).")
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle(isOn: $form.reminderEnabled.animation(.snappy)) {
                Label("Daily Reminder", systemImage: "bell.badge.fill")
            }
            .tint(form.category.color)

            if form.reminderEnabled {
                DatePicker("Remind me at", selection: $form.reminderTime, displayedComponents: .hourAndMinute)

                if notifications.isDenied {
                    Button {
                        notifications.openSystemSettings()
                    } label: {
                        Label("Notifications are disabled. Tap to enable them in Settings.", systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                    }
                    .tint(.orange)
                }

                NotificationPreview(
                    title: form.category.reminderTitle,
                    message: form.notificationPreviewMessage,
                    time: form.reminderTime
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
        } header: {
            Text("Reminder")
        } footer: {
            if form.reminderEnabled {
                Text("You'll get a gentle nudge every day at \(form.reminderTime.formatted(date: .omitted, time: .shortened)).")
            }
        }
    }

    // MARK: Actions

    private func save() {
        guard form.isValid else { return }

        let savedGoal: Goal
        if let goal {
            form.apply(to: goal)
            savedGoal = goal
        } else {
            let newGoal = form.makeGoal()
            modelContext.insert(newGoal)
            savedGoal = newGoal
        }
        AppEvents.goalsDidChange(in: modelContext)

        Task { await notifications.scheduleReminder(for: savedGoal) }
        dismiss()
    }
}

#if DEBUG
#Preview("New Goal") {
    AddEditGoalView()
        .modelContainer(PreviewData.container)
        .environment(NotificationManager.shared)
}
#endif
