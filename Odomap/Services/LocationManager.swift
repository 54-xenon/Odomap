//
//  LocationManager.swift
//  Odomap
//

import CoreLocation
import Observation

/// GPSでのツーリング記録を担当。5m移動 or 3秒経過でトラックポイントを間引きしつつ、
/// 距離・速度・獲得標高はより高頻度な位置更新から計算する。
@Observable
final class LocationManager: NSObject {
    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?

    private let minDistanceMeters: CLLocationDistance = 5
    private let minTimeInterval: TimeInterval = 3
    private let minMovementForDistance: CLLocationDistance = 1
    private let maxAcceptableAccuracy: CLLocationAccuracy = 50

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
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
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
        coordinates = []
        distanceMeters = 0
        currentSpeedKmh = 0
        maxSpeedKmh = 0
        elevationGainMeters = 0
        currentAltitude = 0
        isPaused = false
        isRecording = true

        manager.allowsBackgroundLocationUpdates = authorizationStatus == .authorizedAlways
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    private func process(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy < maxAcceptableAccuracy else { return }

        currentAltitude = location.altitude
        if location.speed >= 0 {
            let speedKmh = location.speed * 3.6
            currentSpeedKmh = speedKmh
            maxSpeedKmh = max(maxSpeedKmh, speedKmh)
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
            let altitudeDelta = location.altitude - last.altitude
            if altitudeDelta > 0 {
                elevationGainMeters += altitudeDelta
            }
        }

        coordinates.append(location.coordinate)
        lastLocation = location
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRecording, !isPaused else { return }
        for location in locations {
            process(location)
        }
    }
}
