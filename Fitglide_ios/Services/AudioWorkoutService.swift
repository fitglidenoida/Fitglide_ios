//
//  AudioWorkoutService.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 09/07/25.
//

import Foundation
import AVFoundation
import Speech

class AudioWorkoutService: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isAudioEnabled = true
    @Published var isVoiceEnabled = true
    
    override init() {
        super.init()
        setupAudioSession()
        requestSpeechPermission()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.isVoiceEnabled = status == .authorized
            }
        }
    }
    
    // MARK: - Voice Announcements
    func announceWorkoutStart(type: WorkoutType) {
        guard isAudioEnabled && isVoiceEnabled else { return }
        
        let utterance = AVSpeechUtterance(string: "Starting \(type.displayName) workout")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.1
        utterance.volume = 0.8
        
        synthesizer.speak(utterance)
    }
    
    func announceMilestone(milestone: String) {
        guard isAudioEnabled && isVoiceEnabled else { return }
        
        let utterance = AVSpeechUtterance(string: milestone)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.2
        utterance.volume = 0.9
        
        synthesizer.speak(utterance)
    }
    
    func announceDistance(distance: Double) {
        let distanceText: String
        if distance >= 1000 {
            distanceText = String(format: "%.1f kilometers", distance / 1000)
        } else {
            distanceText = String(format: "%.0f meters", distance)
        }
        
        announceMilestone(milestone: "Distance: \(distanceText)")
    }
    
    func announcePace(pace: Double) {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        let paceText = String(format: "%d minutes %d seconds per kilometer", minutes, seconds)
        
        announceMilestone(milestone: "Current pace: \(paceText)")
    }
    
    func announceHeartRate(heartRate: Double) {
        announceMilestone(milestone: "Heart rate: \(Int(heartRate)) beats per minute")
    }
    
    func announceWorkoutComplete(duration: TimeInterval, distance: Double, calories: Double) {
        let durationText = formatDuration(duration)
        let distanceText = distance >= 1000 ? String(format: "%.2f kilometers", distance / 1000) : String(format: "%.0f meters", distance)
        
        let completionText = "Workout complete! Duration: \(durationText), Distance: \(distanceText), Calories: \(Int(calories))"
        announceMilestone(milestone: completionText)
    }
    
    // MARK: - Audio Cues
    func playStartSound() {
        guard isAudioEnabled else { return }
        playSound(named: "workout_start")
    }
    
    func playLapSound() {
        guard isAudioEnabled else { return }
        playSound(named: "lap_complete")
    }
    
    func playCompleteSound() {
        guard isAudioEnabled else { return }
        playSound(named: "workout_complete")
    }
    
    func playHeartRateAlert() {
        guard isAudioEnabled else { return }
        playSound(named: "heart_rate_alert")
    }
    
    private func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            // Use system sound if custom sound not found
            AudioServicesPlaySystemSound(SystemSoundID(1005)) // System notification sound
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d hours %d minutes", hours, minutes)
        } else {
            return String(format: "%d minutes %d seconds", minutes, seconds)
        }
    }
    
    // MARK: - Public Methods
    func toggleAudio() {
        isAudioEnabled.toggle()
    }
    
    func toggleVoice() {
        isVoiceEnabled.toggle()
    }
    
    func stopAllAudio() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
    }
} 