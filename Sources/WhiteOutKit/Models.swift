import Foundation
import CoreGraphics

public struct DisplaySetting: Codable, Identifiable, Equatable {
    public var id: String { String(displayID) }
    public let displayID: CGDirectDisplayID
    public let name: String
    public var reduction: Double
    public var curveExponent: Double
    public var isEnabled: Bool

    public init(displayID: CGDirectDisplayID, name: String, reduction: Double, curveExponent: Double, isEnabled: Bool) {
        self.displayID = displayID
        self.name = name
        self.reduction = reduction
        self.curveExponent = curveExponent
        self.isEnabled = isEnabled
    }
}

public struct AppRule: Codable, Identifiable, Equatable {
    public var id: String { bundleIdentifier }
    public let bundleIdentifier: String
    public let appName: String
    public var reduction: Double
    public var curveExponent: Double
    public var isEnabled: Bool

    public init(bundleIdentifier: String, appName: String, reduction: Double, curveExponent: Double, isEnabled: Bool) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.reduction = reduction
        self.curveExponent = curveExponent
        self.isEnabled = isEnabled
    }
}

public struct TimeRule: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var startHour: Int
    public var startMinute: Int
    public var endHour: Int
    public var endMinute: Int
    public var reduction: Double
    public var isEnabled: Bool

    public init(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, reduction: Double, isEnabled: Bool) {
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.reduction = reduction
        self.isEnabled = isEnabled
    }

    // Computed properties for SwiftUI DatePicker binding mapping
    public var startDate: Date {
        get {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = startHour
            components.minute = startMinute
            return calendar.date(from: components) ?? Date()
        }
        set {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: newValue)
            startHour = components.hour ?? 0
            startMinute = components.minute ?? 0
        }
    }

    public var endDate: Date {
        get {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = endHour
            components.minute = endMinute
            return calendar.date(from: components) ?? Date()
        }
        set {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: newValue)
            endHour = components.hour ?? 0
            endMinute = components.minute ?? 0
        }
    }
}
