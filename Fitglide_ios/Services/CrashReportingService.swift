//
//  CrashReportingService.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 25/01/25.
//

import Foundation
import OSLog
import UIKit

class CrashReportingService {
    static let shared = CrashReportingService()
    private let logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: "CrashReporting")
    
    // Store crash logs locally
    private let crashLogFile = "crash_logs.txt"
    private let maxLogEntries = 100
    
    private init() {
        setupCrashHandling()
    }
    
    func configure() {
        logger.info("Native crash reporting service configured")
    }
    
    private func setupCrashHandling() {
        // Set up uncaught exception handler
        NSSetUncaughtExceptionHandler { exception in
            CrashReportingService.shared.handleUncaughtException(exception)
        }
        
        // Set up signal handler for crashes
        signal(SIGABRT) { _ in
            CrashReportingService.shared.handleSignal("SIGABRT")
        }
        signal(SIGSEGV) { _ in
            CrashReportingService.shared.handleSignal("SIGSEGV")
        }
        signal(SIGBUS) { _ in
            CrashReportingService.shared.handleSignal("SIGBUS")
        }
    }
    
    func logError(_ error: Error, context: String? = nil) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let errorMessage = """
        [ERROR] \(timestamp)
        Error: \(error.localizedDescription)
        Context: \(context ?? "none")
        Stack: \(Thread.callStackSymbols.joined(separator: "\n"))
        
        """
        
        writeToLog(errorMessage)
        logger.error("Error logged: \(error.localizedDescription), context: \(context ?? "none")")
    }
    
    func logMessage(_ message: String, level: String = "info") {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(level.uppercased())] \(timestamp): \(message)\n"
        
        writeToLog(logMessage)
        logger.info("Message logged: \(message)")
    }
    
    func setUserProperty(_ value: String, forKey key: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[USER_PROPERTY] \(timestamp): \(key) = \(value)\n"
        
        writeToLog(logMessage)
        logger.debug("User property set: \(key) = \(value)")
    }
    
    func setUserID(_ userID: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[USER_ID] \(timestamp): \(userID)\n"
        
        writeToLog(logMessage)
        logger.info("User ID set: \(userID)")
    }
    
    func recordNonFatalError(_ error: Error, context: String? = nil) {
        logError(error, context: context)
    }
    
    private func handleUncaughtException(_ exception: NSException) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let crashMessage = """
        [CRASH] \(timestamp)
        Exception: \(exception.name.rawValue)
        Reason: \(exception.reason ?? "none")
        Stack: \(exception.callStackSymbols.joined(separator: "\n"))
        
        """
        
        writeToLog(crashMessage)
        logger.error("Uncaught exception: \(exception.name.rawValue)")
    }
    
    private func handleSignal(_ signal: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let crashMessage = """
        [CRASH] \(timestamp)
        Signal: \(signal)
        Stack: \(Thread.callStackSymbols.joined(separator: "\n"))
        
        """
        
        writeToLog(crashMessage)
        logger.error("Signal crash: \(signal)")
    }
    
    private func writeToLog(_ message: String) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFileURL = documentsPath.appendingPathComponent(crashLogFile)
        
        do {
            // Read existing logs
            var existingLogs = ""
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                existingLogs = try String(contentsOf: logFileURL, encoding: .utf8)
            }
            
            // Add new log entry
            let newLogs = existingLogs + message
            
            // Keep only the last maxLogEntries lines
            let lines = newLogs.components(separatedBy: .newlines)
            let trimmedLogs = lines.suffix(maxLogEntries).joined(separator: "\n")
            
            // Write back to file
            try trimmedLogs.write(to: logFileURL, atomically: true, encoding: .utf8)
        } catch {
            logger.error("Failed to write to crash log: \(error.localizedDescription)")
        }
    }
    
    func getCrashLogs() -> String {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return "No logs available"
        }
        
        let logFileURL = documentsPath.appendingPathComponent(crashLogFile)
        
        do {
            return try String(contentsOf: logFileURL, encoding: .utf8)
        } catch {
            return "No logs available"
        }
    }
    
    func clearLogs() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFileURL = documentsPath.appendingPathComponent(crashLogFile)
        
        do {
            try FileManager.default.removeItem(at: logFileURL)
            logger.info("Crash logs cleared")
        } catch {
            logger.error("Failed to clear crash logs: \(error.localizedDescription)")
        }
    }
}

// Date formatter for logs
extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
} 