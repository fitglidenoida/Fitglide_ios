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
    @State private var showDatePicker = false
    @State private var animateContent = false
    @State private var showSleepWisdom = false
    @State private var showSmartAlarmSetup = false
    @State private var sleepGoal: Float = 8.0
    @State private var syncWithClock = true
    @State private var selectedSound = "Rain"
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let colors = FitGlideTheme.colors(for: colorScheme)
        NavigationView {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Modern Header Section
                        modernHeaderSection
                        
                        // Indian Sleep Wisdom
                        if showSleepWisdom {
                            indianSleepWisdomCard
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        
                        // Smart Alarm Setup Card
                        smartAlarmSetupCard
                        
                        // Sleep Score Overview
                        sleepScoreOverview
                        
                        // Sleep Metrics Grid
                        sleepMetricsGrid
                        
                        // Sleep Quality Insights
                        sleepQualityInsights
                        
                        // Meditation & Relaxation
                        meditationRelaxationSection
                        
                        // Sleep Schedule
                        sleepScheduleSection
                        
                        // Quick Actions
                        modernQuickActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
                
                // Show sleep wisdom after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showSleepWisdom = true
                    }
                }
            }
            .sheet(isPresented: $showSmartAlarmSetup) {
                SmartAlarmSetupView(
                    sleepGoal: $sleepGoal,
                    syncWithClock: $syncWithClock,
                    selectedSound: $selectedSound,
                    onSave: saveSmartAlarmSettings
                )
            }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep & Wellness 😴")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Rest well, live well")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Settings Button
                Button(action: { showSmartAlarmSetup = true }) {
                                ZStack {
                        Circle()
                            .fill(FitGlideTheme.colors(for: colorScheme).surface)
                            .frame(width: 44, height: 44)
                            .shadow(color: FitGlideTheme.colors(for: colorScheme).onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                    }
                }
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1.0 : 0.0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Date Selector
            modernDateSelector
        }
        .padding(.bottom, 16)
        .background(
            FitGlideTheme.colors(for: colorScheme).background
                .shadow(color: FitGlideTheme.colors(for: colorScheme).onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Modern Date Selector
    var modernDateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(-3...3, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    let isToday = Calendar.current.isDateInToday(date)
                    let isSelected = Calendar.current.isDate(selectedDate, inSameDayAs: date)
                    
                    Button(action: { selectedDate = date }) {
                        VStack(spacing: 4) {
                            Text(dayOfWeek(for: date))
                                .font(FitGlideTheme.caption)
                                .fontWeight(.medium)
                                .foregroundColor(isSelected ? FitGlideTheme.colors(for: colorScheme).onPrimary : FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                            
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? FitGlideTheme.colors(for: colorScheme).onPrimary : FitGlideTheme.colors(for: colorScheme).onSurface)
                        }
                        .frame(width: 50, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? FitGlideTheme.colors(for: colorScheme).primary : (isToday ? FitGlideTheme.colors(for: colorScheme).primary.opacity(0.1) : FitGlideTheme.colors(for: colorScheme).surface))
                        )
                                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isToday && !isSelected ? FitGlideTheme.colors(for: colorScheme).primary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(offset + 3) * 0.05), value: animateContent)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Indian Sleep Wisdom Card
    var indianSleepWisdomCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                
                Spacer()
                
                Text("Sleep Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
            }
            
            Text(indianSleepWisdom.randomElement() ?? indianSleepWisdom[0])
                .font(FitGlideTheme.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FitGlideTheme.colors(for: colorScheme).surface)
                .shadow(color: FitGlideTheme.colors(for: colorScheme).onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Smart Alarm Setup Card
    var smartAlarmSetupCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Smart Alarm")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                
                Spacer()
                
                Button(action: { showSmartAlarmSetup = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                        Text("Settings")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                    }
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Sleep Goal")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("\(Int(sleepGoal)) hours")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                }
                
                Toggle("Sync with Clock", isOn: $syncWithClock)
                    .toggleStyle(SwitchToggleStyle(tint: FitGlideTheme.colors(for: colorScheme).primary))
                
                if !syncWithClock {
                    Picker("Sound", selection: $selectedSound) {
                        ForEach(smartAlarmSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FitGlideTheme.colors(for: colorScheme).surface)
                .shadow(color: FitGlideTheme.colors(for: colorScheme).onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
    
    // MARK: - Sleep Score Overview
    var sleepScoreOverview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sleep Score")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                
                Spacer()
                
                            if let sleepData = viewModel.sleepData {
                    Text("\(sleepData.score)/100")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                }
            }
            
            // Sleep Score Circle
                            if let sleepData = viewModel.sleepData {
                                ZStack {
                    Circle()
                        .stroke(FitGlideTheme.colors(for: colorScheme).surfaceVariant, lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(sleepData.score) / 100.0)
                        .stroke(
                            LinearGradient(
                                colors: [FitGlideTheme.colors(for: colorScheme).primary, FitGlideTheme.colors(for: colorScheme).secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
                    
                    VStack(spacing: 2) {
                        Text("\(sleepData.score)")
                            .font(FitGlideTheme.titleLarge)
                            .fontWeight(.bold)
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                        
                        Text("Score")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FitGlideTheme.colors(for: colorScheme).surface)
                .shadow(color: FitGlideTheme.colors(for: colorScheme).onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
        .onTapGesture {
            showDetails = true
        }
    }
    
    // MARK: - Sleep Metrics Grid
    var sleepMetricsGrid: some View {
        HStack(spacing: 12) {
            ModernSleepMetricCard(
                title: "Sleep Time",
                value: sleepTimeText,
                unit: "hours",
                icon: "moon.fill",
                color: .purple,
                theme: FitGlideTheme.colors(for: colorScheme),
                animateContent: $animateContent,
                delay: 0.2
            )
            
            ModernSleepMetricCard(
                title: "Sleep Debt",
                value: viewModel.sleepData?.debt ?? "0",
                unit: "hours",
                icon: "clock.fill",
                color: .orange,
                theme: FitGlideTheme.colors(for: colorScheme),
                animateContent: $animateContent,
                delay: 0.3
            )
            
            ModernSleepMetricCard(
                title: "Deep Sleep",
                value: "\(Int((viewModel.sleepData?.actualSleepTime ?? 0) * 0.25))",
                unit: "hours",
                icon: "brain.head.profile",
                color: .blue,
                theme: FitGlideTheme.colors(for: colorScheme),
                animateContent: $animateContent,
                delay: 0.4
            )
        }
    }
    
    // MARK: - Sleep Quality Insights
    var sleepQualityInsights: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sleep Quality Insights")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                SleepQualityInsightCard(
                    title: "Sleep Efficiency",
                    value: "\(Int((viewModel.sleepData?.actualSleepTime ?? 0) / (viewModel.sleepData?.restTime ?? 1) * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.5
                )
                
                SleepQualityInsightCard(
                    title: "Sleep Consistency",
                    value: "Good",
                    icon: "calendar",
                    color: .blue,
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.6
                )
                
                SleepQualityInsightCard(
                    title: "Recovery Score",
                    value: "\(viewModel.sleepData?.score ?? 0)/100",
                    icon: "heart.fill",
                    color: .red,
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.7
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateContent)
    }
    
    // MARK: - Meditation & Relaxation Section
    var meditationRelaxationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Meditation & Relaxation")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                
                Spacer()
                
                Button("View All") {
                    // Show all meditation content
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(indianMeditationPractices, id: \.self) { practice in
                        IndianMeditationCard(
                            title: practice.title,
                            duration: practice.duration,
                            icon: practice.icon,
                            color: practice.color,
                            theme: FitGlideTheme.colors(for: colorScheme),
                            animateContent: $animateContent,
                            delay: 0.8 + Double(indianMeditationPractices.firstIndex(of: practice) ?? 0) * 0.1
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateContent)
    }
    
    // MARK: - Sleep Schedule Section
    var sleepScheduleSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sleep Schedule")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SleepScheduleCard(
                    title: "Bedtime",
                    time: "10:30 PM",
                    icon: "bed.double.fill",
                    color: .purple,
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.9
                )
                
                SleepScheduleCard(
                    title: "Wake Time",
                    time: "6:30 AM",
                    icon: "sunrise.fill",
                    color: .orange,
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 1.0
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9), value: animateContent)
    }
    
    // MARK: - Modern Quick Actions Section
    var modernQuickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ModernSleepQuickActionButton(
                    title: "Start Meditation",
                    icon: "brain.head.profile",
                    color: FitGlideTheme.colors(for: colorScheme).primary,
                    action: { /* Start meditation */ },
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 1.1
                )
                
                ModernSleepQuickActionButton(
                    title: "Sleep Timer",
                    icon: "timer",
                    color: .blue,
                    action: { /* Set sleep timer */ },
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 1.2
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.1), value: animateContent)
    }
    
    // MARK: - Helper Properties
    private var sleepTimeText: String {
        if let sleepData = viewModel.sleepData {
            return String(format: "%.1f", sleepData.actualSleepTime)
        }
        return "0.0"
    }
    
    private var indianSleepWisdom: [String] {
        [
            "Early to bed and early to rise makes a person healthy, wealthy, and wise.",
            "Sleep is the best meditation - Dalai Lama",
            "A good night's sleep is the foundation of a productive day.",
            "Your body heals and repairs while you sleep peacefully.",
            "Quality sleep is the key to mental and physical wellness."
        ]
    }
    
    private var indianMeditationPractices: [IndianMeditationPractice] {
        [
            IndianMeditationPractice(title: "Pranayama", duration: "10 min", icon: "lungs.fill", color: .blue),
            IndianMeditationPractice(title: "Yoga Nidra", duration: "20 min", icon: "moon.stars.fill", color: .purple),
            IndianMeditationPractice(title: "Mindfulness", duration: "15 min", icon: "brain.head.profile", color: .green),
            IndianMeditationPractice(title: "Deep Breathing", duration: "5 min", icon: "wind", color: .cyan)
        ]
    }

    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func saveSmartAlarmSettings() {
        // Save settings to UserDefaults or viewModel
        print("Smart Alarm Settings Saved:")
        print("Sleep Goal: \(sleepGoal) hours")
        print("Sync with Clock: \(syncWithClock)")
        print("Selected Sound: \(selectedSound)")
    }

    private var smartAlarmSounds: [String] {
        ["Rain", "Nature", "Birds", "Ocean"]
    }
}

// MARK: - Smart Alarm Setup View
struct SmartAlarmSetupView: View {
    @Binding var sleepGoal: Float
    @Binding var syncWithClock: Bool
    @Binding var selectedSound: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var animateContent = false
    @State private var showIndianWisdom = false
    
    private var colors: FitGlideTheme.Colors { FitGlideTheme.colors(for: colorScheme) }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with Indian wellness gradient
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3),
                        colors.primary.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Modern Header
                        modernHeaderSection
                        
                        // Indian Wellness Quote
                        if showIndianWisdom {
                            indianWellnessQuoteCard
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        
                        // Sleep Goal Card
                        sleepGoalCard
                        
                        // Clock Sync Card
                        clockSyncCard
                        
                        // Sound Selection Card
                        if !syncWithClock {
                            soundSelectionCard
                        }
                        
                        // Smart Alarm Preview
                        smartAlarmPreviewCard
                        
                        // Quick Actions
                        quickActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurfaceVariant)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.primary)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
                
                // Show Indian wisdom after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showIndianWisdom = true
                    }
                }
            }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Alarm Setup 🌙")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Optimize your sleep with intelligent alarm timing")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding(.bottom, 16)
        .background(
            colors.background
                .shadow(color: colors.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Indian Wellness Quote Card
    var indianWellnessQuoteCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
                
                Spacer()
                
                Text("Sleep Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            Text("Nidra hi paramam sukham, shanti cha paramam dhanam")
                .font(FitGlideTheme.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(colors.onSurface)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Sleep Goal Card
    var sleepGoalCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
                
                Text("Sleep Goal")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Text("\(Int(sleepGoal))h")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.primary)
            }
            
            VStack(spacing: 12) {
                Slider(value: $sleepGoal, in: 6...10, step: 0.5)
                    .accentColor(colors.primary)
                
                HStack {
                    Text("6h")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("10h")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Clock Sync Card
    var clockSyncCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
                
                Text("Clock Integration")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Toggle("Sync with iOS Clock", isOn: $syncWithClock)
                    .toggleStyle(SwitchToggleStyle(tint: colors.primary))
                
                if syncWithClock {
                    Text("Smart alarms will automatically sync with your iOS clock and focus modes")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Sound Selection Card
    var soundSelectionCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
                
                Text("Alarm Sound")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(smartAlarmSounds, id: \.self) { sound in
                    Button(action: { selectedSound = sound }) {
                        HStack(spacing: 8) {
                            Image(systemName: selectedSound == sound ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedSound == sound ? colors.primary : colors.onSurfaceVariant)
                            
                            Text(sound)
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurface)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedSound == sound ? colors.primary.opacity(0.1) : colors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedSound == sound ? colors.primary.opacity(0.3) : colors.onSurface.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Smart Alarm Preview Card
    var smartAlarmPreviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "alarm.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
                
                Text("Smart Alarm Preview")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Optimal Wake Time")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("6:30 AM")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(colors.primary)
                }
                
                HStack {
                    Text("Sleep Focus")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("Auto-enabled")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.secondary)
                }
                
                HStack {
                    Text("Sleep Quality")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("Predicted: 85%")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Quick Actions Section
    var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: { /* Test alarm sound */ }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Test Sound")
                            .font(FitGlideTheme.bodyMedium)
                    }
                    .foregroundColor(colors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colors.primary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(colors.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
                
                Button(action: { /* Reset to defaults */ }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text("Reset")
                            .font(FitGlideTheme.bodyMedium)
                    }
                    .foregroundColor(colors.onSurfaceVariant)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(colors.onSurface.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    private var smartAlarmSounds: [String] {
        ["Rain", "Nature", "Birds", "Ocean"]
    }
}

// MARK: - Modern Sleep Metric Card
struct ModernSleepMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

        var body: some View {
        VStack(spacing: 12) {
                ZStack {
                    Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text(unit)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text(title)
                .font(FitGlideTheme.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

// MARK: - Sleep Quality Insight Card
struct SleepQualityInsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

        var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(value)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

// MARK: - Indian Meditation Card
struct IndianMeditationCard: View {
    let title: String
    let duration: String
    let icon: String
        let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

        var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                Text(duration)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text(title)
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
                .lineLimit(1)
        }
        .padding(16)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

// MARK: - Sleep Schedule Card
struct SleepScheduleCard: View {
    let title: String
    let time: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

        var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(time)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
            }
            
            Spacer()
            
            Button("Edit") {
                // Edit schedule
            }
            .font(FitGlideTheme.caption)
            .foregroundColor(theme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

// MARK: - Modern Sleep Quick Action Button
struct ModernSleepQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

        var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

// MARK: - Supporting Data Structures
struct IndianMeditationPractice: Hashable {
    let title: String
    let duration: String
    let icon: String
    let color: Color
}
