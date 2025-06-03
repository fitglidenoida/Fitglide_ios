//
//  WorkoutDetailView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 12/07/25.
//

import Foundation
import SwiftUI
import MapKit

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let workoutId: String
    let strapiRepository: StrapiRepository
    let authRepository: AuthRepository
    let healthService: HealthService  // Assuming HealthService is the iOS equivalent of HealthConnectManager
    
    @State private var workoutLog: WorkoutLogEntry? = nil
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationStack {
            if let log = workoutLog {
                List {
                    if let route = log.route, !route.isEmpty {
                        Section {
                            MapView(route: parseRoute(route))
                                .frame(height: 250)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                    }
                    
                    Section(header: Text("Workout Stats").font(.headline)) {
                        DetailRow(title: "Type", content: log.type ?? "Unknown")
                        DetailRow(title: "Calories Burned", content: "\(Int(log.calories ?? 0)) kcal")
                        DetailRow(title: "Average Heart Rate", content: "\(log.heartRateAverage ?? 0) bpm")
                        DetailRow(title: "Max Heart Rate", content: "\(log.heartRateMaximum ?? 0) bpm")
                        DetailRow(title: "Min Heart Rate", content: "\(log.heartRateMinimum ?? 0) bpm")
                        DetailRow(title: "Distance", content: "\(log.distance ?? 0) km")
                        DetailRow(title: "Duration", content: formatDuration(log.totalTime ?? 0))
                        DetailRow(title: "Pace", content: calculatePace(log))
                        DetailRow(title: "Notes", content: log.notes ?? "No notes available")
                    }
                    
                    if let distance = log.distance, distance > 0 {
                        Section(header: Text("Splits (Per Kilometer)").font(.headline)) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    let kmCount = Int(distance) + (distance.truncatingRemainder(dividingBy: 1) > 0 ? 1 : 0)
                                    ForEach(1...kmCount, id: \.self) { km in
                                        VStack {
                                            Text("KM \(km)")
                                                .fontWeight(.bold)
                                            Text(formatSplitTime(log, km: km))
                                                .font(.subheadline)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    
                    if log.heartRateAverage ?? 0 > 0 {
                        Section(header: Text("Heart Rate Zones").font(.headline)) {
                            DetailRow(title: "Low Zone (50-70%)", content: heartRateZone(log, low: 0.5, high: 0.7))
                            DetailRow(title: "Moderate Zone (70-85%)", content: heartRateZone(log, low: 0.7, high: 0.85))
                            DetailRow(title: "High Zone (85-100%)", content: heartRateZone(log, low: 0.85, high: 1.0))
                        }
                    }
                    
                    Section(header: Text("Achievements").font(.headline)) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                let achievements = getAchievements(log)
                                if achievements.isEmpty {
                                    Text("No achievements yet")
                                        .font(.subheadline)
                                } else {
                                    ForEach(achievements, id: \.self) { badge in
                                        HStack {
                                            Image(systemName: "rosette")
                                            Text(badge)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button("Share Workout") {
                        shareWorkout(log)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("Workout Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            dismiss()
                        }
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            fetchWorkoutDetails()
        }
    }
    
    private func fetchWorkoutDetails() {
        Task {
            do {
                guard let userId = authRepository.authState.userId else {
                    alertMessage = "Missing user ID"
                    showAlert = true
                    return
                }

                // Try parsing logId as UUID date prefix (you can adjust this based on your logId format)
                let dateFromLogId = extractDateFromLogId(workoutId) ?? Date()
                let dateString = ISO8601DateFormatter().string(from: dateFromLogId).prefix(10) // yyyy-MM-dd

                let logs = try await strapiRepository.getWorkoutLogs(userId: userId, date: String(dateString))
                guard let strapiLog = logs.data.first(where: { $0.logId == workoutId }) else {
                    alertMessage = "Workout not found."
                    showAlert = true
                    return
                }

                let startTime = ISO8601DateFormatter().date(from: strapiLog.startTime) ?? Date()
                let workoutData = try await healthService.getWorkout(date: startTime)
                let heartRate = try await healthService.getHeartRate(date: startTime)

                workoutLog = WorkoutLogEntry(
                    id: strapiLog.id,
                    documentId: strapiLog.documentId,
                    logId: strapiLog.logId,
                    workout: strapiLog.workout,
                    startTime: strapiLog.startTime,
                    endTime: strapiLog.endTime,
                    distance: workoutData.distance ?? strapiLog.distance,
                    totalTime: workoutData.duration ?? strapiLog.totalTime,
                    calories: workoutData.calories ?? strapiLog.calories,
                    heartRateAverage: (heartRate.average > 0 ? heartRate.average : strapiLog.heartRateAverage),
                    heartRateMaximum: strapiLog.heartRateMaximum,
                    heartRateMinimum: strapiLog.heartRateMinimum,
                    route: strapiLog.route,
                    completed: strapiLog.completed,
                    notes: strapiLog.notes,
                    type: workoutData.type ?? strapiLog.type
                )
            } catch {
                alertMessage = "Error fetching workout: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func extractDateFromLogId(_ logId: String) -> Date? {
        let pattern = #"wearable_(\d{4}-\d{2}-\d{2})"#  // extract date portion
        if let match = logId.range(of: pattern, options: .regularExpression) {
            let dateString = String(logId[match]).replacingOccurrences(of: "wearable_", with: "")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter.date(from: dateString)
        }
        return nil
    }


    private func shareWorkout(_ log: WorkoutLogEntry) {
        let shareText = """
🏃 FitGlide Workout Summary 🏃
Type: \(log.type ?? "Workout")
Distance: \(log.distance ?? 0) km
Calories: \(Int(log.calories ?? 0)) kcal
Duration: \(formatDuration(log.totalTime ?? 0))
Avg HR: \(log.heartRateAverage ?? 0) bpm
#FitGlide #Fitness
"""
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    let route: [CLLocationCoordinate2D]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        let polyline = MKPolyline(coordinates: route, count: route.count)
        uiView.addOverlay(polyline)
        if !route.isEmpty {
            let region = MKCoordinateRegion(polyline.boundingMapRect)
            uiView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

func parseRoute(_ route: [[String: Float]]) -> [CLLocationCoordinate2D] {
    return route.compactMap { point in
        if let lat = point["lat"], let lng = point["lng"] {
            return CLLocationCoordinate2D(latitude: Double(lat), longitude: Double(lng))
        }
        return nil
    }
}

struct DetailRow: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).fontWeight(.bold)
            Text(content).foregroundColor(.secondary)
        }
    }
}

func formatDuration(_ time: Float) -> String {
    let hours = Int(time)
    let minutes = Int((time - Float(hours)) * 60)
    let seconds = Int(((time - Float(hours)) * 60 - Float(minutes)) * 60)
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

func calculatePace(_ log: WorkoutLogEntry) -> String {
    let distance = log.distance ?? 0
    let totalTime = log.totalTime ?? 0
    if distance <= 0 || totalTime <= 0 { return "N/A" }
    let pace = totalTime / distance
    let minutes = Int(pace)
    let seconds = Int((pace - Float(minutes)) * 60)
    return String(format: "%d:%02d min/km", minutes, seconds)
}

func formatSplitTime(_ log: WorkoutLogEntry, km: Int) -> String {
    let distance = log.distance ?? 0
    let totalTime = log.totalTime ?? 0
    if distance <= 0 || totalTime <= 0 { return "N/A" }
    let splitTime = totalTime / distance
    let minutes = Int(splitTime)
    let seconds = Int((splitTime - Float(minutes)) * 60)
    return String(format: "%d:%02d min/km", minutes, seconds)
}

func heartRateZone(_ log: WorkoutLogEntry, low: Float, high: Float) -> String {
    let maxHr = Float(log.heartRateMaximum ?? 0)
    if maxHr <= 0 { return "N/A" }
    let lowBpm = Int(maxHr * low)
    let highBpm = Int(maxHr * high)
    return "\(lowBpm) - \(highBpm) bpm"
}

func getAchievements(_ log: WorkoutLogEntry) -> [String] {
    var ach: [String] = []
    if (log.distance ?? 0) >= 5 { ach.append("5K Runner 🏃") }
    if (log.distance ?? 0) >= 10 { ach.append("10K Champion 🏅") }
    if (log.calories ?? 0) >= 500 { ach.append("Calorie Crusher 🔥") }
    return ach
}
