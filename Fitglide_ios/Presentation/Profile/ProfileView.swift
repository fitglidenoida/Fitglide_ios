//
//  ProfileView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 21/06/25.
//


import HealthKit
import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @ObservedObject var stravaAuthViewModel: StravaAuthViewModel
    @ObservedObject var navigationViewModel: NavigationViewModel
    let authRepository: AuthRepository
    @Environment(\.colorScheme) var colorScheme
    @State private var isPersonalDataExpanded = true
    @State private var isHealthVitalsExpanded = false
    @State private var isFitnessBridgeExpanded = false
    @State private var isSetGoalsExpanded = false
    @State private var isSettingsExpanded = false
    @State private var isLegalExpanded = false
    @State private var showDatePicker = false
    @State private var isLoading = false

    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }

    private var areHealthVitalsValid: Bool {
        viewModel.profileData.weight != nil &&
        viewModel.profileData.height != nil &&
        !(viewModel.profileData.gender?.isEmpty ?? true) &&
        !(viewModel.profileData.dob?.isEmpty ?? true) &&
        !(viewModel.profileData.activityLevel?.isEmpty ?? true)
    }

    private var areGoalsValid: Bool {
        viewModel.profileData.weightLossGoal != nil &&
        !(viewModel.profileData.weightLossStrategy?.isEmpty ?? true)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fixed header section
                headerSection
                    .background(LinearGradient(
                        colors: [colors.primary, colors.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .clipShape(TopStraightBottomRoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 2)
                    .padding(.top, 4)
                    .zIndex(1)

                // Scrollable content
                ScrollView {
                    VStack(spacing: 12) {
                        personalDataSection
                        healthVitalsSection
                        setGoalsSection
                        fitnessBridgeSection
                        settingsSection
                        legalSection
                        logoutSection
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                    .background(colors.background)
                }
            }
            .edgesIgnoringSafeArea(.top)
            .alert(item: Binding(
                get: { viewModel.uiMessage.map { IdentifiableString(value: $0) } },
                set: { _ in viewModel.uiMessage = nil }
            )) { message in
                Alert(title: Text("Profile Update"), message: Text(message.value), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            // Top Row: Avatar + Name
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(colors.onPrimary.opacity(0.2))
                        .frame(width: 70, height: 70)
                    Text(viewModel.profileData.firstName?.first.map { String($0) } ?? "U")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(colors.onPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.profileData.firstName ?? "User")
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(colors.onPrimary)
                    Text("FitGlide Member")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(colors.onPrimary.opacity(0.85))
                }

                Spacer()
            }

            // Stats
            HStack(spacing: 16) {
                statBox(title: "Weight", value: viewModel.profileData.weight.map { String(format: "%.1f", $0) } ?? "N/A")
                statBox(title: "BMI", value: viewModel.profileData.bmi.map { String(format: "%.1f", $0) } ?? "N/A")
                statBox(title: "BMR", value: viewModel.profileData.bmr.map { "\(Int($0)) kcal" } ?? "N/A")
            }

            // Weight Loss Progress
            VStack(alignment: .leading, spacing: 4) {
                Text("Weight Loss Progress")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(colors.onPrimary)

                ProgressView(value: viewModel.weightLossProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: colorScheme == .dark ? .white : .orange))
                    .frame(height: 5)
                    .background(colors.onPrimary.opacity(0.2))
                    .cornerRadius(2)
                    .animation(.easeInOut(duration: 0.4), value: viewModel.weightLossProgress)

                Text("\(viewModel.weightLost.map { String(format: "%.1f", $0) } ?? "0") / \(viewModel.profileData.weightLossGoal.map { String(format: "%.1f", $0) } ?? "0") kg lost")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(colors.onPrimary)

                Text(viewModel.motivationalMessage)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(colors.onPrimary.opacity(0.9))
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [colors.primary, colors.secondary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        )
        .padding(.horizontal, 12)
    }

    private var personalDataSection: some View {
        ExpandableSection(
            title: "Personal Data",
            isExpanded: $isPersonalDataExpanded,
            colors: colors
        ) {
            AnyView(
                VStack(spacing: 6) {
                    EditableField(
                        label: "First Name",
                        value: viewModel.profileData.firstName ?? "",
                        onValueChange: { viewModel.profileData.firstName = $0.isEmpty ? nil : $0 },
                        colors: colors,
                        isMandatory: true
                    )
                    EditableField(
                        label: "Last Name",
                        value: viewModel.profileData.lastName ?? "",
                        onValueChange: { viewModel.profileData.lastName = $0.isEmpty ? nil : $0 },
                        colors: colors,
                        isMandatory: true
                    )
                    EditableField(
                        label: "Email",
                        value: viewModel.profileData.email ?? "",
                        onValueChange: { viewModel.profileData.email = $0.isEmpty ? nil : $0 },
                        colors: colors,
                        isMandatory: true
                    )
                    Button(action: {
                        viewModel.savePersonalData()
                    }) {
                        Text("Save")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(colors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            )
        }
        .padding(.horizontal, 12)
    }

    private var healthVitalsSection: some View {
        ExpandableSection(
            title: "Health Vitals",
            isExpanded: $isHealthVitalsExpanded,
            colors: colors
        ) {
            AnyView(
                VStack(spacing: 6) {
                    EditableField(
                        label: "Weight (kg)*",
                        value: viewModel.profileData.weight.map { String(format: "%.2f", $0) } ?? "",
                        onValueChange: { viewModel.profileData.weight = Double($0) },
                        colors: colors,
                        keyboardType: .decimalPad,
                        isNumeric: true,
                        isMandatory: true
                    )
                    EditableField(
                        label: "Height (cm)*",
                        value: viewModel.profileData.height.map { String(format: "%.2f", $0) } ?? "",
                        onValueChange: { viewModel.profileData.height = Double($0) },
                        colors: colors,
                        keyboardType: .decimalPad,
                        isNumeric: true,
                        isMandatory: true
                    )
                    DropdownField(
                        label: "Gender*",
                        value: viewModel.profileData.gender ?? "",
                        options: ["", "Male", "Female"],
                        onValueChange: { viewModel.profileData.gender = $0.isEmpty ? nil : $0 },
                        colors: colors,
                        isMandatory: true
                    )
                    DatePickerField(
                        label: "DOB (YYYY-MM-DD)*",
                        value: viewModel.profileData.dob ?? "",
                        onValueChange: { viewModel.profileData.dob = $0.isEmpty ? nil : $0 },
                        colors: colors,
                        showDatePicker: showDatePicker,
                        onShowDatePicker: { showDatePicker = true },
                        onDismissDatePicker: { showDatePicker = false }
                    )
                    DropdownField(
                        label: "Activity Level*",
                        value: viewModel.profileData.activityLevel ?? "Sedentary (little/no exercise)",
                        options: [
                            "Sedentary (little/no exercise)",
                            "Light exercise (1-3 days/week)",
                            "Moderate exercise (3-5 days/week)",
                            "Heavy exercise (6-7 days/week)",
                            "Very heavy exercise (Twice/day)"
                        ],
                        onValueChange: { viewModel.profileData.activityLevel = $0 },
                        colors: colors,
                        isMandatory: true
                    )
                    Text("BMI: \(viewModel.profileData.bmi.map { String(format: "%.2f", $0) } ?? "N/A")")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(colors.onSurface)
                    Text("BMR: \(viewModel.profileData.bmr.map { "\(Int($0)) kcal" } ?? "N/A")")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(colors.onSurface)
                    Button(action: {
                        if areHealthVitalsValid {
                            viewModel.saveHealthVitals()
                        } else {
                            viewModel.uiMessage = "All fields are required"
                        }
                    }) {
                        Text("Calculate and Save")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(areHealthVitalsValid ? colors.primary : colors.primary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(!areHealthVitalsValid)
                }
            )
        }
        .padding(.horizontal, 12)
    }

    private var fitnessBridgeSection: some View {
        ExpandableSection(
            title: "Fitness Bridge",
            isExpanded: $isFitnessBridgeExpanded,
            colors: colors
        ) {
            AnyView(
                VStack(spacing: 6) {
                    FitnessBridgeToggle(
                        label: "Strava",
                        isEnabled: $stravaAuthViewModel.isStravaConnected,
                        colors: colors,
                        onToggle: { enabled in
                            if enabled {
                                stravaAuthViewModel.initiateStravaAuth()
                            } else {
                                stravaAuthViewModel.disconnectStrava()
                            }
                        }
                    )
                    if stravaAuthViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: colors.primary))
                            .padding(.vertical, 6)
                    }
                }
            )
        }
        .padding(.horizontal, 12)
    }

    private var setGoalsSection: some View {
        ExpandableSection(
            title: "Set Goals",
            isExpanded: $isSetGoalsExpanded,
            colors: colors
        ) {
            AnyView(
                VStack(spacing: 6) {
                    EditableField(
                        label: "Weight Loss Goal (kg)*",
                        value: viewModel.profileData.weightLossGoal.map { String(format: "%.2f", $0) } ?? "",
                        onValueChange: { viewModel.profileData.weightLossGoal = Double($0) },
                        colors: colors,
                        keyboardType: .decimalPad,
                        isNumeric: true,
                        isMandatory: true
                    )
                    DropdownField(
                        label: "Weight Loss Strategy*",
                        value: viewModel.profileData.weightLossStrategy ?? "",
                        options: ["", "Lean-(0.25 kg/week)", "Aggressive-(0.5 kg/week)", "Custom"],
                        onValueChange: { viewModel.profileData.weightLossStrategy = $0.isEmpty ? nil : $0 },
                        colors: colors,
                        isMandatory: true
                    )
                    Text("Step Goal: \(viewModel.profileData.stepGoal.map { "\($0)" } ?? "N/A")")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(colors.onSurface)
                    Text("Water Goal: \(viewModel.profileData.waterGoal.map { String(format: "%.2f", $0) } ?? "N/A") L")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(colors.onSurface)
                    Text("Calorie Goal: \(viewModel.profileData.calorieGoal.map { "\($0)" } ?? "N/A") cal")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(colors.onSurface)
                    Button(action: {
                        if areGoalsValid && viewModel.profileData.tdee != nil {
                            viewModel.saveGoals()
                        } else {
                            viewModel.uiMessage = "All fields are required"
                        }
                    }) {
                        Text("Save")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(areGoalsValid && viewModel.profileData.tdee != nil ? colors.primary : colors.primary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(!(areGoalsValid && viewModel.profileData.tdee != nil))
                }
            )
        }
        .padding(.horizontal, 12)
    }

    private var settingsSection: some View {
        ExpandableSection(
            title: "Settings",
            isExpanded: $isSettingsExpanded,
            colors: colors
        ) {
            AnyView(
                VStack(spacing: 6) {
                    Toggle(isOn: Binding(
                        get: { viewModel.profileData.notificationsEnabled },
                        set: { viewModel.profileData.notificationsEnabled = $0; viewModel.savePersonalData() }
                    )) {
                        Text("Notifications")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(colors.onSurface)
                    }
                    .padding(.vertical, 4)
                    Toggle(isOn: Binding(
                        get: { viewModel.profileData.maxGreetingsEnabled },
                        set: { viewModel.profileData.maxGreetingsEnabled = $0; viewModel.savePersonalData() }
                    )) {
                        Text("Max Greetings")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(colors.onSurface)
                    }
                    .padding(.vertical, 4)
                }
            )
        }
        .padding(.horizontal, 12)
    }

    private var legalSection: some View {
        ExpandableSection(
            title: "Legal",
            isExpanded: $isLegalExpanded,
            colors: colors
        ) {
            AnyView(
                VStack(spacing: 6) {
                    Button(action: {
                        if let url = URL(string: "https://fitglide.in/privacy.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Privacy Policy")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(colors.onSurface)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 12))
                                .foregroundColor(colors.primary)
                        }
                    }
                    .padding(.vertical, 4)

                    Button(action: {
                        if let url = URL(string: "https://fitglide.in/terms-conditions.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Terms of Service")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(colors.onSurface)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 12))
                                .foregroundColor(colors.primary)
                        }
                    }
                    .padding(.vertical, 4)

                    Divider()
                        .padding(.vertical, 4)

                    // Account Management
                    Button(action: {
                        Task {
                            await viewModel.deleteAccount()
                        }
                    }) {
                        HStack {
                            Text("Delete Account")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            )
        }
        .padding(.horizontal, 12)
    }

    private var logoutSection: some View {
        Button(action: {
            authRepository.logout()
            navigationViewModel.navigateToLogin()
        }) {
            Text("Logout")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
    
    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(colors.onPrimary)
            Text(title)
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundColor(colors.onPrimary.opacity(0.9))
        }
    }

}

struct TopStraightBottomRoundedRectangle: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}


struct ExpandableSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let colors: FitGlideTheme.Colors
    let content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(colors.surface)
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
            VStack {
                HStack {
                    Text(title)
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundColor(colors.onSurface)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(colors.onSurface)
                        .imageScale(.medium)
                }
                .padding(.vertical, 6)
                .onTapGesture { isExpanded.toggle() }

                if isExpanded {
                    content()
                        .padding(.top, 6)
                }
            }
            .padding(12)
        }
    }
}

struct EditableField: View {
    let label: String
    let value: String
    let onValueChange: (String) -> Void
    let colors: FitGlideTheme.Colors
    let keyboardType: UIKeyboardType
    let isNumeric: Bool
    let isMandatory: Bool
    @State private var text: String

    init(
        label: String,
        value: String,
        onValueChange: @escaping (String) -> Void,
        colors: FitGlideTheme.Colors,
        keyboardType: UIKeyboardType = .default,
        isNumeric: Bool = false,
        isMandatory: Bool = false
    ) {
        self.label = label
        self.value = value
        self.onValueChange = onValueChange
        self.colors = colors
        self.keyboardType = keyboardType
        self.isNumeric = isNumeric
        self.isMandatory = isMandatory
        self._text = State(initialValue: value)
    }

    var body: some View {
        TextField(label + (isMandatory ? " *" : ""), text: $text)
            .font(.custom("Poppins-Regular", size: 12))
            .foregroundColor(.black)
            .padding(8)
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .keyboardType(keyboardType)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(colors.onSurface.opacity(0.2), lineWidth: 0.5)
            )
            .onChange(of: text) { _, newValue in
                if isNumeric {
                    let regex = keyboardType == .decimalPad ? "^[0-9]*\\.?[0-9]*$" : "^[0-9]*$"
                    if newValue.matches(regex: regex) {
                        onValueChange(newValue)
                    } else {
                        text = value
                    }
                } else {
                    onValueChange(newValue)
                }
            }
    }
}

struct DropdownField: View {
    let label: String
    let value: String
    let options: [String]
    let onValueChange: (String) -> Void
    let colors: FitGlideTheme.Colors
    let isMandatory: Bool
    @State private var isExpanded = false

    var body: some View {
        ZStack {
            TextField(label + (isMandatory ? " *" : ""), text: .constant(value), onEditingChanged: { _ in isExpanded = true })
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.black)
                .padding(8)
                .background(colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .disabled(true)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(colors.onSurface.opacity(0.2), lineWidth: 0.5)
                )
            HStack {
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(colors.onSurfaceVariant)
                    .padding(.trailing, 8)
            }
        }
        .onTapGesture { isExpanded = true }
        .overlay {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        onValueChange(option)
                        isExpanded = false
                    }) {
                        Text(option)
                            .font(.custom("Poppins-Regular", size: 12))
                    }
                }
            } label: {
                Color.clear
            }
            .opacity(isExpanded ? 1 : 0)
        }
    }
}

struct DatePickerField: View {
    let label: String
    let value: String
    let onValueChange: (String) -> Void
    let colors: FitGlideTheme.Colors
    let showDatePicker: Bool
    let onShowDatePicker: () -> Void
    let onDismissDatePicker: () -> Void
    @State private var selectedDate = Date()

    var body: some View {
        TextField(label, text: .constant(value))
            .font(.custom("Poppins-Regular", size: 12))
            .foregroundColor(.black)
            .padding(8)
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .disabled(true)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(colors.onSurface.opacity(0.2), lineWidth: 0.5)
            )
            .overlay(alignment: .trailing) {
                Image(systemName: "calendar")
                    .foregroundColor(colors.onSurfaceVariant)
                    .padding(.trailing, 8)
            }
            .onTapGesture { onShowDatePicker() }
            .sheet(isPresented: .constant(showDatePicker)) {
                VStack(spacing: 10) {
                    DatePicker("Select Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(8)
                    HStack(spacing: 8) {
                        Button("Cancel") { onDismissDatePicker() }
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(colors.primary)
                            .padding(6)
                        Spacer()
                        Button("OK") {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            onValueChange(formatter.string(from: selectedDate))
                            onDismissDatePicker()
                        }
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(8)
                .background(colors.background)
                .cornerRadius(10)
            }
    }
}

struct FitnessBridgeToggle: View {
    let label: String
    @Binding var isEnabled: Bool
    let colors: FitGlideTheme.Colors
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(colors.onSurface)
            Spacer()
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    isEnabled = newValue
                    onToggle(newValue)
                }
            ))
            .tint(colors.primary)
        }
        .padding(.vertical, 4)
    }
}

extension String {
    func matches(regex: String) -> Bool {
        range(of: regex, options: .regularExpression) != nil
    }
}

struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}
