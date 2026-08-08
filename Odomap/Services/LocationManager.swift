//
//  LocationManager.swift
//  Odomap
//

import CoreLocation
import CoreMotion
import Observation

/// GPSでのツーリング記録を担当。5m移動 or 3秒経過でトラックポイントを間引きしつつ、
/// 距離・速度・獲得標高はより高頻度な位置更新から計算する。
/// 気圧高度計が利用可能かつ設定でオンの場合、高度・獲得標高はノイズの少ないCMAltimeterの値を優先する。
@Observable
final class LocationManager: NSObject {
    private let manager = CLLocationManager()
    private let altimeter = CMAltimeter()
    private var lastLocation: CLLocation?
    private var barometerBaseAltitude: Double?
    private var lastRelativeAltitude: Double?

    private let minDistanceMeters: CLLocationDistance = 5
    private let minTimeInterval: TimeInterval = 3
    private let minMovementForDistance: CLLocationDistance = 1
    private let maxAcceptableAccuracy: CLLocationAccuracy = 50
    private let minBarometricDeltaMeters: Double = 0.05

    private var usesBarometer: Bool {
        SettingsStore.shared.usesBarometricAltimeter && CMAltimeter.isRelativeAltitudeAvailable()
    }

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var isRecording = false
    var isPaused = false

    private(set) var coordinates: [CLLocationCoordinate2D] = []
    private(set) var distanceMeters: Double = 0
    private(set) var currentSpeedKmh: Double = 0
    private(set) var maxSpeedKmh: Double = 0
    private(set) var elevationGainMeters: Double = 0
    private(set) var currentAltitude: Double = 0

    var distanceKm: Double { distanceMeters / 1000 }

    var canRecord: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestAuthorizationIfNeeded() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func requestAlwaysIfPossible() {
        if authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    func startRecording() {
        guard canRecord, !isRecording else { return }
        lastLocation = nil
        barometerBaseAltitude = nil
        lastRelativeAltitude = nil
        coordinates = []
        distanceMeters = 0
        currentSpeedKmh = 0
        maxSpeedKmh = 0
        elevationGainMeters = 0
        currentAltitude = 0
        isPaused = false
        isRecording = true

        manager.desiredAccuracy = SettingsStore.shared.accuracyMode == .navigation
            ? kCLLocationAccuracyBestForNavigation
            : kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = authorizationStatus == .authorizedAlways
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()

        if usesBarometer {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                self.handleBarometer(data)
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        altimeter.stopRelativeAltitudeUpdates()
    }

    private func handleBarometer(_ data: CMAltitudeData) {
        let relative = data.relativeAltitude.doubleValue
        defer { lastRelativeAltitude = relative }

        guard let base = barometerBaseAltitude else { return }
        if let last = lastRelativeAltitude {
            let delta = relative - last
            if delta > minBarometricDeltaMeters { elevationGainMeters += delta }
        }
        currentAltitude = base + relative
    }

    private func process(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy < maxAcceptableAccuracy else { return }

        if location.speed >= 0 {
            let speedKmh = location.speed * 3.6
            currentSpeedKmh = speedKmh
            maxSpeedKmh = max(maxSpeedKmh, speedKmh)
        }

        if usesBarometer {
            // 気圧高度計の相対値をGPSの実高度に合わせるための基準点（初回のみ）
            if barometerBaseAltitude == nil {
                barometerBaseAltitude = location.altitude - (lastRelativeAltitude ?? 0)
                currentAltitude = barometerBaseAltitude ?? location.altitude
            }
        } else {
            currentAltitude = location.altitude
        }

        guard let last = lastLocation else {
            lastLocation = location
            coordinates.append(location.coordinate)
            return
        }

        let delta = location.distance(from: last)
        let timeDelta = location.timestamp.timeIntervalSince(last.timestamp)
        guard delta >= minDistanceMeters || timeDelta >= minTimeInterval else { return }

        if delta >= minMovementForDistance {
            distanceMeters += delta
            if !usesBarometer {
                let altitudeDelta = location.altitude - last.altitude
                if altitudeDelta > 0 {
                    elevationGainMeters += altitudeDelta
                }
            }
        }

        coordinates.append(location.coordinate)
        lastLocation = location
    }
}

extension LocationManager: CLLocationManagerDelegate {
    // CoreLocationはこれらのdelegateメソッドをメインスレッド以外から呼ぶことがあるため、
    // nonisolatedにした上でMainActorへ明示的にホップする（実機でのみ発生するクラッシュ対策）。
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard self.isRecording, !self.isPaused else { return }
            for location in locations {
                self.process(location)
            }
        }
    }
}
