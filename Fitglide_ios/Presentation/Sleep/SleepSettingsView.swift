//
//  SleepSettingsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 14/06/25.
//

import Foundation
import SwiftUI
import AVFoundation

struct SleepSettingsView: View {
    @ObservedObject var viewModel: SleepViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var syncEnabled: Bool
    @State private var sleepGoal: Float
    @State private var selectedSound: String
    @State private var selectedAlarmTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var audioPlayer: AVAudioPlayer?

    let sounds = ["Rain", "Forest", "Waves", "Noise"]

    init(viewModel: SleepViewModel) {
        self.viewModel = viewModel
        _syncEnabled = State(initialValue: viewModel.syncEnabled)
        _sleepGoal = State(initialValue: viewModel.sleepGoal)
        _selectedSound = State(initialValue: viewModel.selectedSound)
    }

    var body: some View {
        let colors = FitGlideTheme.colors(for: colorScheme)

        ZStack {
            colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [colors.primary, colors.secondary]), startPoint: .leading, endPoint: .trailing)
                        .frame(height: 140)
                        .ignoresSafeArea(edges: .top)

                    HStack {
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                                .padding(8)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 16)

                        Text("Sleep Settings")
                            .font(.custom("Poppins-Bold", size: 28))
                            .foregroundColor(.white)
                            .padding(.leading, 8)

                        Spacer()
                    }
                    .padding(.top, 40)
                }

                ScrollView {
                    VStack(spacing: 24) {
                        // Sync Toggle
                        CardView {
                            HStack {
                                Text("Sync with Clock")
                                    .font(.custom("Poppins-SemiBold", size: 18))
                                    .foregroundColor(colors.onSurface)
                                Spacer()
                                Toggle("", isOn: $syncEnabled)
                                    .tint(colors.primary)
                                    .labelsHidden()
                            }
                            .padding(20)
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                        // Sleep Goal Slider
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sleep Goal: \(String(format: "%.1f", sleepGoal))h")
                                    .font(.custom("Poppins-Medium", size: 16))
                                    .foregroundColor(colors.onSurface)
                                Slider(value: $sleepGoal, in: 6...10, step: 0.5)
                                    .accentColor(colors.primary)
                                    .padding(.horizontal)
                            }
                            .padding(20)
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                        // Alarm Picker
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Set Alarm Time")
                                    .font(.custom("Poppins-Medium", size: 16))
                                    .foregroundColor(colors.onSurfaceVariant)
                                DatePicker("", selection: $selectedAlarmTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                    .accentColor(colors.primary)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(20)
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                        // Sound Selection
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Soothing Sound")
                                    .font(.custom("Poppins-Medium", size: 16))
                                    .foregroundColor(colors.onSurfaceVariant)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(sounds, id: \.self) { sound in
                                            SoundChip(
                                                title: sound,
                                                isSelected: selectedSound == sound,
                                                action: {
                                                    selectedSound = sound
                                                    playSound(named: sound)
                                                }
                                            )
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                }
                            }
                            .padding(20)
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                        // Save Button
                        Button(action: {
                            Task {
                                await viewModel.updateSettings(
                                    syncEnabled: syncEnabled,
                                    sleepGoal: sleepGoal,
                                    selectedSound: selectedSound
                                )
                                scheduleAlarm(for: selectedAlarmTime)
                                await MainActor.run { dismiss() }
                            }
                        }) {
                            Text("Save Changes")
                                .font(.custom("Poppins-SemiBold", size: 18))
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [colors.primary, colors.secondary]), startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private func playSound(named name: String) {
        guard let url = Bundle.main.url(forResource: name.lowercased(), withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }

    private func scheduleAlarm(for date: Date) {
        // Placeholder: Implement native alarm scheduling or notification
        print("Alarm scheduled for: \(date)")
    }
}

