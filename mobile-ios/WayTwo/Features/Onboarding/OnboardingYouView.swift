import SwiftUI

struct OnboardingYouView: View {
    @Binding var state: OnboardingReducer.State
    let onNext: () -> Void

    private var canProceedYouStep: Bool {
        !state.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !state.gender.isEmpty
    }

    var body: some View {
        ZStack {
            AppColors.surface.ignoresSafeArea()
            FormScreenScrollContainer(topSpacing: Tokens.FormScreen.Spacing.beforeHeaderWithNavBar) {
                VStack(spacing: Tokens.FormScreen.Spacing.headerToSubheader) {
                    FormScreenTitleText(titleKey: "onboarding.you.title")
                    FormScreenSubheaderPlaceholder()
                }
            } formContent: {
                VStack(spacing: 0) {
                    VStack(spacing: Tokens.FormScreen.Spacing.onboardingStackedFieldGap) {
                        AppTextField(
                            placeholder: "onboarding.you.namePlaceholder",
                            text: $state.name
                        )
                        OnboardingGenderPickerField(selection: $state.gender)
                        OnboardingDateOfBirthField(dateString: $state.dateOfBirth)
                    }
                    Spacer().frame(height: Tokens.Spacing.x3l)
                    PrimaryButton(
                        titleKey: "onboarding.you.next",
                        isDisabled: !canProceedYouStep,
                        action: onNext
                    )
                    if let errorKey = state.errorKey {
                        Text(LocalizedStringKey(errorKey))
                            .foregroundStyle(AppColors.error)
                            .padding(.top, Tokens.Spacing.md)
                    }
                }
            }
        }
    }
}

private enum OnboardingGender: String, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    case other = "other"

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .male: "onboarding.you.genderMale"
        case .female: "onboarding.you.genderFemale"
        case .other: "onboarding.you.genderOther"
        }
    }

}

private struct OnboardingGenderPickerField: View {
    @Binding var selection: String

    private var selectedGender: OnboardingGender? {
        OnboardingGender(rawValue: selection)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(alignment: .center, spacing: Tokens.Spacing.md) {
                Group {
                    if let option = selectedGender {
                        VStack(alignment: .leading, spacing: Tokens.Spacing.xxs) {
                            Text("onboarding.you.genderLabel")
                                .font(.system(size: Tokens.FontSize.sm, weight: .regular))
                                .foregroundStyle(AppColors.textSecondary)
                            Text(LocalizedStringKey(option.titleKey))
                                .font(.system(size: Tokens.FontSize.lg, weight: .medium))
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("onboarding.you.genderLabel")
                            .font(.system(size: Tokens.FontSize.lg, weight: .medium))
                            .foregroundStyle(AppColors.textPlaceholder)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: Tokens.FontSize.lg, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .imageScale(.small)
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .frame(maxWidth: .infinity)
            .frame(height: Tokens.Size.inputHeight, alignment: .center)
            .allowsHitTesting(false)

            Menu {
                ForEach(OnboardingGender.allCases) { option in
                    Button {
                        selection = option.rawValue
                    } label: {
                        HStack {
                            Text(LocalizedStringKey(option.titleKey))
                            Spacer(minLength: Tokens.Spacing.xl)
                            if selection == option.rawValue {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .tint(AppColors.textPrimary)
        }
        .frame(height: Tokens.Size.inputHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.md)
                .stroke(AppColors.inputBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingDateOfBirthField: View {
    @Binding var dateString: String
    @State private var showPicker = false
    @State private var draftDate = OnboardingDateOfBirthField.defaultDraftDate

    private static var defaultDraftDate: Date {
        Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    }

    private static var displayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = .autoupdatingCurrent
        return f
    }

    private var parsedDate: Date? {
        Self.date(fromYMD: dateString)
    }

    private var displayLine: String? {
        guard let date = parsedDate else { return nil }
        return Self.displayFormatter.string(from: date)
    }

    private var dobRange: ClosedRange<Date> {
        let cal = Calendar.current
        let end = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .year, value: -120, to: end) ?? end
        return start...end
    }

    var body: some View {
        Button {
            draftDate = parsedDate ?? Self.defaultDraftDate
            showPicker = true
        } label: {
            VStack(alignment: .leading, spacing: Tokens.Spacing.xxs) {
                if let line = displayLine {
                    Text("onboarding.you.dobLabel")
                        .font(.system(size: Tokens.FontSize.sm, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                    Text(line)
                        .font(.system(size: Tokens.FontSize.lg, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("onboarding.you.dobPlaceholder")
                        .font(.system(size: Tokens.FontSize.lg, weight: .medium))
                        .foregroundStyle(AppColors.textPlaceholder)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .frame(height: Tokens.Size.inputHeight, alignment: .center)
            .background(AppColors.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.md)
                    .stroke(AppColors.inputBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                DatePicker(
                    "",
                    selection: $draftDate,
                    in: dobRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .navigationTitle("onboarding.you.dobLabel")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("common.cancel") { showPicker = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("common.done") {
                            dateString = Self.ymdString(from: draftDate)
                            showPicker = false
                        }
                    }
                }
                .toolbarBackground(AppColors.surface, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
            .background(AppColors.surface)
            .tint(AppColors.textPrimary)
            .presentationBackground(AppColors.surface)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private static func ymdString(from date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 0
        let m = c.month ?? 0
        let d = c.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    private static func date(fromYMD string: String) -> Date? {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var dc = DateComponents()
        dc.year = parts[0]
        dc.month = parts[1]
        dc.day = parts[2]
        return Calendar.current.date(from: dc)
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                OnboardingYouView(
                    state: .constant(OnboardingReducer.State()),
                    onNext: {}
                )
                .navigationTitle("onboarding.you.title")
                .hidesNavigationBarTitle()
            }
    }
}
