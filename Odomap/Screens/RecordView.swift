//
//  RecordView.swift
//  Odomap
//

import SwiftUI
import Observation
import CoreLocation
import UIKit

/// 走行時間の計測
@Observable
final class RecordingSession {
    let startedAt = Date()
    private(set) var isPaused = false
    private var segmentStart = Date()
    private var accumulated: TimeInterval = 0

    func elapsed(now: Date = .now) -> TimeInterval {
        accumulated + (isPaused ? 0 : now.timeIntervalSince(segmentStart))
    }

    func togglePause() {
        if isPaused {
            segmentStart = .now
        } else {
            accumulated += Date.now.timeIntervalSince(segmentStart)
        }
        isPaused.toggle()
    }
}

struct RecordView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (Ride) -> Void

    @State private var session = RecordingSession()
    @State private var locationManager = LocationManager()
    @State private var weatherManager = WeatherManager()
    @State private var finishedRide: Ride?
    @State private var showPermissionAlert = false
    @State private var hasStartedWeatherUpdates = false

    var body: some View {
        if let finishedRide {
            RideSummaryView(ride: finishedRide) {
                onSave(finishedRide)
                dismiss()
            }
        } else {
            recordingBody
                .onAppear { attemptStart() }
                .onDisappear {
                    locationManager.stopRecording()
                    weatherManager.stop()
                }
                .onChange(of: locationManager.authorizationStatus) { _, _ in attemptStart() }
                .onChange(of: locationManager.coordinates.isEmpty) { _, isEmpty in
                    guard !isEmpty, !hasStartedWeatherUpdates else { return }
                    hasStartedWeatherUpdates = true
                    weatherManager.start { locationManager.coordinates.last }
                }
                .alert("位置情報の許可が必要です", isPresented: $showPermissionAlert) {
                    Button("設定を開く") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("キャンセル", role: .cancel) {}
                } message: {
                    Text("ツーリングを記録するには、設定アプリから位置情報の利用を許可してください。")
                }
        }
    }

    private func attemptStart() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAuthorizationIfNeeded()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysIfPossible()
            locationManager.startRecording()
        case .authorizedAlways:
            locationManager.startRecording()
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }

    private var recordingBody: some View {
        ZStack {
            SkyGradientBackground(strong: true)
            VStack(spacing: 18) {
                header

                VStack(spacing: 4) {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(formatDuration(session.elapsed(now: context.date)))
                            .font(.system(size: 60, weight: .bold))
                            .monospacedDigit()
                    }
                    Text("走行時間")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 14)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())],
                    spacing: 12
                ) {
                    metricCard("距離", value: SettingsStore.shared.distanceUnit.distanceText(fromKm: locationManager.distanceKm))
                    metricCard("現在速度", value: SettingsStore.shared.distanceUnit.speedText(fromKmh: locationManager.currentSpeedKmh))
                    weatherCard
                    metricCard("高度", value: String(format: "%.0f m", locationManager.currentAltitude))
                }

                Spacer()

                controlButtons
            }
            .padding(20)
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Text("\(session.startedAt.formatted(date: .omitted, time: .shortened)) 開始")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func metricCard(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 26, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("天気")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Image(systemName: weatherManager.symbolName)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: 0xFF9F0A))
                Text(weatherManager.temperatureText)
                    .font(.system(size: 26, weight: .bold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private var controlButtons: some View {
        HStack(spacing: 10) {
            Button {
                session.togglePause()
                locationManager.isPaused = session.isPaused
            } label: {
                Label(session.isPaused ? "再開" : "一時停止",
                      systemImage: session.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .capsule)

            Button {
                finishRecording()
            } label: {
                Text("終了")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.plain)
            .glassEffect(
                .regular.tint(Color(hex: 0xFF3B30, alpha: 0.85)).interactive(),
                in: .capsule
            )
        }
    }

    private func finishRecording() {
        locationManager.stopRecording()
        let coordinates = locationManager.coordinates
        finishedRide = Ride(
            name: "今日のツーリング",
            date: session.startedAt,
            distanceKm: locationManager.distanceKm,
            duration: session.elapsed(),
            maxSpeedKmh: locationManager.maxSpeedKmh,
            elevationGain: locationManager.elevationGainMeters,
            coordinates: coordinates,
            thumbnailColorHexes: [0x57B7FF, 0x0A84FF]
        )
    }
}

#Preview {
    RecordView { _ in }
}
