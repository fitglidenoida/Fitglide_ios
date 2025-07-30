//
//  Fitglide_Watch_AppApp.swift
//  Fitglide_Watch_App Watch App
//
//  Created by Sandip Tiwari on 27/07/25.
//

import SwiftUI

@main
struct Fitglide_Watch_App_Watch_AppApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var liveCheerManager = LiveCheerManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutManager)
                .environmentObject(liveCheerManager)
                .onAppear {
                    print("🚀 FitGlide Watch App launched")
                }
        }
    }
}
