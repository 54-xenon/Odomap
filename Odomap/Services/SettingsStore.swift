//
//  SettingsStore.swift
//  Odomap
//

import Foundation
import Observation

enum DistanceUnit: String, CaseIterable, Identifiable {
    case kilometers, miles
    var id: Self { self }

    var label: String { self == .kilometers ? "km" : "mi" }
    var speedLabel: String { self == .kilometers ? "km/h" : "mph" }

    private var kmToUnit: Double { self == .kilometers ? 1 : 0.621371 }

    func distanceValue(fromKm km: Double) -> Double { km * kmToUnit }
    func speedValue(fromKmh kmh: Double) -> Double { kmh * kmToUnit }

    func distanceText(fromKm km: Double) -> String {
        String(format: "%.1f \(label)", distanceValue(fromKm: km))
    }

    func speedText(fromKmh kmh: Double) -> String {
        String(format: "%.1f \(speedLabel)", speedValue(fromKmh: kmh))
    }
}

enum AccuracyMode: String, CaseIterable, Identifiable {
    case navigation, balanced
    var id: Self { self }

    var label: String { self == .navigation ? "ナビ用（高精度）" : "バランス（省電力）" }
}

/// 天気の更新間隔（分）の選択肢
enum WeatherUpdateInterval: Int, CaseIterable, Identifiable {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    var id: Self { self }

    var label: String { "\(rawValue)分" }
}

/// アプリ全体の設定（UserDefaults にローカル保存）。CloudKit 同期はしない。
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    var distanceUnit: DistanceUnit {
        didSet { defaults.set(distanceUnit.rawValue, forKey: Keys.distanceUnit) }
    }
    var accuracyMode: AccuracyMode {
        didSet { defaults.set(accuracyMode.rawValue, forKey: Keys.accuracyMode) }
    }
    var usesBarometricAltimeter: Bool {
        didSet { defaults.set(usesBarometricAltimeter, forKey: Keys.usesBarometricAltimeter) }
    }
    var weatherUpdateInterval: WeatherUpdateInterval {
        didSet { defaults.set(weatherUpdateInterval.rawValue, forKey: Keys.weatherUpdateInterval) }
    }
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        distanceUnit = DistanceUnit(rawValue: defaults.string(forKey: Keys.distanceUnit) ?? "") ?? .kilometers
        accuracyMode = AccuracyMode(rawValue: defaults.string(forKey: Keys.accuracyMode) ?? "") ?? .navigation
        usesBarometricAltimeter = defaults.object(forKey: Keys.usesBarometricAltimeter) as? Bool ?? true
        weatherUpdateInterval = WeatherUpdateInterval(rawValue: defaults.integer(forKey: Keys.weatherUpdateInterval)) ?? .tenMinutes
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? false
    }

    private enum Keys {
        static let distanceUnit = "settings.distanceUnit"
        static let accuracyMode = "settings.accuracyMode"
        static let usesBarometricAltimeter = "settings.usesBarometricAltimeter"
        static let weatherUpdateInterval = "settings.weatherUpdateInterval"
        static let notificationsEnabled = "settings.notificationsEnabled"
    }
}
