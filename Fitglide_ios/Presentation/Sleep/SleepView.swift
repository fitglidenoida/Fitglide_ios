//
//  SleepView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 14/06/25.
//

import SwiftUI

struct SleepView: View {
    @ObservedObject var viewModel: SleepViewModel
    @State private var selectedDate = Date()
    @State private var showDetails = false
    @State private var showSettings = false
    @State private var showDatePicker = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let colors = FitGlideTheme.colors(for: colorScheme)
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                VStack(spacing: 12) {
                    // Header with Greeting, Date, and Gear Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.surface.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Text("\(viewModel.firstname ?? "User")! Aaram ka time!")
                                    .font(.custom("Poppins-Bold", size: 20))
                                    .foregroundColor(colors.onSurface)
                                    .padding(.top, 8)
                                HStack(spacing: 12) {
                                    Button(action: {
                                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .font(.custom("Poppins-Semibold", size: 16))
                                            .foregroundColor(colors.primary)
                                    }
                                    Text(formattedDate(selectedDate))
                                        .font(.custom("Poppins-Semibold", size: 16))
                                        .foregroundColor(colors.onSurface)
                                        .underline()
                                    Button(action: {
                                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .font(.custom("Poppins-Semibold", size: 16))
                                            .foregroundColor(colors.primary)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(colors.primary)
                                    .font(.system(size: 24, weight: .medium))
                                    .padding(5)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 8)
                        }
                    }
                    .frame(height: 80)

                    // Scrollable content
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Sleep Score
                            if let sleepData = viewModel.sleepData {
                                SleepScoreArc(
                                    score: sleepData.score,
                                    debt: sleepData.debt,
                                    injuryRisk: sleepData.injuryRisk,
                                    onClick: { showDetails = true },
                                    colorScheme: colorScheme
                                )
                                .frame(width: 180, height: 180)
                                .padding(.vertical, 16)
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                .background(colors.surface.opacity(0.1))
                            } else {
                                Text("No sleep data available")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(colors.onSurface)
                                    .padding(.vertical, 16)
                            }

                            // Suggested and Actual Sleep Arcs
                            if let sleepData = viewModel.sleepData {
                                HStack(alignment: .center, spacing: 30) {
                                    SleepTimeArc(label: "Suggested", value: sleepData.restTime, max: 10.0, color: colors.primary, colorScheme: colorScheme)
                                    SleepTimeArc(label: "Slept", value: sleepData.actualSleepTime, max: max(sleepData.restTime, 1), color: colors.secondary, colorScheme: colorScheme)
                                }
                                .padding(.top, 4)
                                .padding(.bottom, 12)
                            }

                            // Streak (moved below SleepTimeArcs)
                            if let sleepData = viewModel.sleepData, sleepData.streak > 0 {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(LinearGradient(colors: [colors.primary, colors.secondary], startPoint: .leading, endPoint: .trailing))
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 12)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    HStack(alignment: .center, spacing: 8) {
                                        Image(systemName: "shield.fill")
                                            .foregroundColor(.white)
                                        Text("Streak: \(sleepData.streak) days - \(getStreakTitle(sleepData.streak))")
                                            .font(.custom("Poppins-Semibold", size: 14))
                                            .foregroundColor(.white)
                                    }
                                    .padding(12)
                                }
                                .frame(height: 50)
                                .padding(.bottom, 12)
                            }

                            // Sleep Stages
                            if let sleepData = viewModel.sleepData {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colors.surface.opacity(0.9))
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 12)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    VStack(spacing: 6) {
                                        Text("Sleep Stages")
                                            .font(.custom("Poppins-Bold", size: 16))
                                            .foregroundColor(colors.onBackground)
                                        SleepStagesArcs(stages: sleepData.stages, colorScheme: colorScheme)
                                    }
                                    .padding(12)
                                }
                                .padding(.bottom, 12)
                            }

                            // Actual Sleep Data
                            if let sleepData = viewModel.sleepData {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colors.surface.opacity(0.9))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(colors.primary, lineWidth: 1)
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 12)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    VStack(spacing: 6) {
                                        HStack(alignment: .center, spacing: 8) {
                                            Image(systemName: "bed.double.fill")
                                                .foregroundColor(colors.primary)
                                                .frame(width: 20, height: 20)
                                            Text("Actual Sleep Data")
                                                .font(.custom("Poppins-Bold", size: 16))
                                                .foregroundColor(colors.onBackground)
                                        }
                                        Spacer().frame(height: 4)
                                        HStack(alignment: .center, spacing: 12) {
                                            Text("Bedtime: \(sleepData.bedtime)")
                                                .font(.custom("Poppins-Regular", size: 14))
                                                .foregroundColor(colors.onSurface)
                                            Text("Wake Time: \(sleepData.alarm)")
                                                .font(.custom("Poppins-Regular", size: 14))
                                                .foregroundColor(colors.onSurface)
                                        }
                                    }
                                    .padding(12)
                                }
                                .padding(.bottom, 12)
                            }

                            // Sleep Score Explanation
                            if let sleepData = viewModel.sleepData {
                                Text("Sleep Score")
                                    .font(.custom("Poppins-Bold", size: 18))
                                    .foregroundColor(colors.onBackground)
                                Text(sleepData.scoreLegend.overallScoreDescription.isEmpty ? "No data" : sleepData.scoreLegend.overallScoreDescription)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(colors.onSurface)
                                    .padding(8)
                                Spacer().frame(height: 12)
                            }

                            // Insights
                            if let sleepData = viewModel.sleepData {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colors.surface.opacity(0.9))
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 12)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    VStack(spacing: 6) {
                                        Text("Insights")
                                            .font(.custom("Poppins-Bold", size: 16))
                                            .foregroundColor(colors.onBackground)
                                        if sleepData.insights.isEmpty {
                                            Text("Nothing to show here")
                                                .font(.custom("Poppins-Regular", size: 14))
                                                .foregroundColor(colors.onSurfaceVariant)
                                                .padding(12)
                                        } else {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                VStack(alignment: .leading, spacing: 1) {
                                                    ForEach(sleepData.insights, id: \.self) { insight in
                                                        Text(insight)
                                                            .font(.custom("Poppins-Regular", size: 12))
                                                            .foregroundColor(colors.onSurface)
                                                            .padding(.vertical, 5)
                                                            .padding(.horizontal, 12)
                                                            .onTapGesture {
                                                                if insight.localizedCaseInsensitiveContains("date of birth") {
                                                                    print("Navigate to profile")
                                                                }
                                                            }
                                                    }
                                                }
                                                .padding(.horizontal, 12)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .padding(12)                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showSettings) {
            SleepSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showDetails) {
            if let sleepData = viewModel.sleepData {
                SleepDetailsOverlay(sleepData: sleepData, onDismiss: { showDetails = false }, colorScheme: colorScheme)
            }
        }
        .task(id: selectedDate) {
            await viewModel.fetchSleepData(for: selectedDate)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }

    private func getStreakTitle(_ streak: Int) -> String {
        switch streak {
        case 14...Int.max: return "Dream Master"
        case 7...13: return "Rest King"
        case 3...6: return "Sleep Star"
        default: return ""
        }
    }

    struct SleepScoreArc: View {
        let score: Float
        let debt: String
        let injuryRisk: Float
        let onClick: () -> Void
        let colorScheme: ColorScheme

        var body: some View {
            let colors = FitGlideTheme.colors(for: colorScheme)
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: 300.0 / 360.0)
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .opacity(0.3)
                        .foregroundColor(colors.surfaceVariant)
                        .rotationEffect(.degrees(-240))
                    Circle()
                        .trim(from: 0, to: min(CGFloat(score / 100) * (300.0 / 360.0), 300.0 / 360.0))
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .foregroundColor(colors.primary)
                        .rotationEffect(.degrees(-240))
                    VStack(spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(colors.secondary)
                        Text("\(Int(score))")
                            .font(.custom("Poppins-Bold", size: 22))
                            .foregroundColor(colors.onSurface)
                    }
                }
                .frame(width: 180, height: 180)
                .padding(16)
                .contentShape(Circle())
                .onTapGesture(perform: onClick)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                .padding(.bottom, 3)

                Text("Debt: \(debt) | Risk: \(Int(injuryRisk))%")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(colors.onSurface)
                    .padding(.bottom, 8)
            }
        }
    }

    struct SleepStagesArcs: View {
        let stages: [SleepStage]
        let colorScheme: ColorScheme

        var body: some View {
            let colors = FitGlideTheme.colors(for: colorScheme)
            let expectedStages = ["Light", "Deep", "REM"]
            let normalizedStages: [SleepStage] = expectedStages.map { type in
                stages.first(where: { $0.type == type }) ?? SleepStage(duration: 0, type: type)
            }

            HStack(spacing: 10) {
                ForEach(normalizedStages, id: \.type) { stage in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(colors.surfaceVariant.opacity(0.3))
                                .frame(width: 70, height: 70)
                            Text("\(stage.duration)m")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(colors.onSurface)
                        }
                        Text(stage.type)
                            .font(.custom("Poppins-Regular", size: 10))
                            .foregroundColor(colors.onSurface)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    struct SleepTimeArc: View {
        let label: String
        let value: Float
        let max: Float
        let color: Color
        let colorScheme: ColorScheme

        var body: some View {
            let colors = FitGlideTheme.colors(for: colorScheme)
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: 300.0 / 360.0)
                        .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .opacity(0.3)
                        .foregroundColor(colors.surfaceVariant)
                        .rotationEffect(.degrees(-240))
                    Circle()
                        .trim(from: 0, to: min(max > 0 ? CGFloat(value / max) * (300.0 / 360.0) : 0, 300.0 / 360.0))
                        .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .foregroundColor(color)
                        .rotationEffect(.degrees(-240))
                    Text(label == "Slept" ? "\(Int(value))h" : String(format: "%.1fh", value))
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(colors.onSurface)
                }
                .frame(width: 90, height: 90)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                Text(label)
                    .font(.custom("Poppins-Regular", size: 10))
                    .foregroundColor(colors.onSurface)
            }
        }
    }

    struct SleepDetailsOverlay: View {
        let sleepData: SleepDataUi
        let onDismiss: () -> Void
        let colorScheme: ColorScheme

        var body: some View {
            let colors = FitGlideTheme.colors(for: colorScheme)
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismiss)

                VStack(spacing: 12) {
                    Text("Sleep Details")
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(colors.onBackground)
                    Text("Debt: \(sleepData.debt)")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(colors.onSurface)
                    Text("Injury Risk: \(Int(sleepData.injuryRisk))%")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(colors.onSurface)
                    Text("Rest Tonight: \(String(format: "%.1fh", sleepData.restTime))")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(colors.onSurface)
                    Text("Slept Last Night: \(Int(sleepData.actualSleepTime))h")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(colors.onSurface)
                    Text("Score Explanation")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(colors.onBackground)
                    Text(sleepData.scoreLegend.overallScoreDescription)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(colors.onSurface)
                    Button("Close") {
                        onDismiss()
                    }
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colors.primary)
                    .cornerRadius(8)
                }
                .padding(16)
                .background(colors.surface)
                .cornerRadius(12)
                .frame(width: 280)
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
            }
        }
    }

    struct InsightCard: View {
        let text: String
        let onClick: () -> Void
        let colorScheme: ColorScheme

        var body: some View {
            let colors = FitGlideTheme.colors(for: colorScheme)
            Text(text)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(colors.onSurface)
                .padding(12)
                .background(colors.surface.opacity(0.9))
                .cornerRadius(8)
                .frame(width: 180)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .onTapGesture(perform: onClick)
        }
    }

    struct SleepViewPreviewWrapper: View {
        @State private var viewModel: SleepViewModel?

        var body: some View {
            VStack {
                if let viewModel = viewModel {
                    SleepView(viewModel: viewModel)
                } else {
                    ProgressView("Loading preview...")
                        .tint(FitGlideTheme.colors(for: .light).primary)
                }
            }
            .task {
                let appleAuthManager = await MainActor.run { AppleAuthManager() }
                let authRepository = AuthRepository(appleAuthManager: appleAuthManager)
                let strapiApi = StrapiApiClient()
                let strapiRepository = StrapiRepository(api: strapiApi, authRepository: authRepository)

                let viewModel = await SleepViewModel(
                    strapiRepository: strapiRepository,
                    authRepository: authRepository
                )
                await MainActor.run {
                    self.viewModel = viewModel
                }
            }
        }
    }

    struct SleepView_Previews: PreviewProvider {
        static var previews: some View {
            SleepViewPreviewWrapper()
                .previewDisplayName("Sleep View Preview")
        }
    }
}
