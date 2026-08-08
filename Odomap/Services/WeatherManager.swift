//
//  WeatherManager.swift
//  Odomap
//

import CoreLocation
import Observation
import WeatherKit

/// 記録中の天気をWeatherKitから取得し、設定された間隔で更新する。
/// 気温が高い場合は熱中症警告のローカル通知も送る（設定で通知がオンの時のみ）。
@Observable
final class WeatherManager {
    private let service = WeatherService.shared
    private var timer: Timer?
    private var lastHeatWarningAt: Date?

    private let heatWarningThresholdCelsius: Double = 30
    private let heatWarningCooldown: TimeInterval = 30 * 60

    private(set) var temperatureCelsius: Double?
    private(set) var symbolName = "cloud.fill"
    private(set) var isLoading = false

    var temperatureText: String {
        guard let temperatureCelsius else { return "--" }
        return String(format: "%.0f℃", temperatureCelsius)
    }

    func start(coordinateProvider: @escaping () -> CLLocationCoordinate2D?) {
        stop()
        refresh(coordinateProvider: coordinateProvider)
        let interval = TimeInterval(SettingsStore.shared.weatherUpdateInterval.rawValue * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh(coordinateProvider: coordinateProvider)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh(coordinateProvider: @escaping () -> CLLocationCoordinate2D?) {
        guard let coordinate = coordinateProvider() else { return }
        Task { [weak self] in
            await self?.fetch(at: coordinate)
        }
    }

    @MainActor
    private func fetch(at coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let current = try await service.weather(for: location, including: .current)
            temperatureCelsius = current.temperature.converted(to: .celsius).value
            symbolName = current.symbolName
            checkHeatWarning()
        } catch {
            // 取得失敗時は前回値を表示継続
        }
    }

    private func checkHeatWarning() {
        guard SettingsStore.shared.notificationsEnabled,
              let temperatureCelsius, temperatureCelsius >= heatWarningThresholdCelsius else { return }
        if let lastHeatWarningAt, Date.now.timeIntervalSince(lastHeatWarningAt) < heatWarningCooldown { return }
        lastHeatWarningAt = .now
        NotificationManager.postHeatWarning(temperatureCelsius: temperatureCelsius)
    }
}
