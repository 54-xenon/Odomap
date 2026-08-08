//
//  SettingView.swift
//  Odomap
//

import SwiftUI

struct SettingView: View {
    @Bindable private var settings = SettingsStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section("単位") {
                    Picker("距離・速度の単位", selection: $settings.distanceUnit) {
                        ForEach(DistanceUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                }
                Section("計測") {
                    Picker("精度優先モード", selection: $settings.accuracyMode) {
                        ForEach(AccuracyMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    Toggle("気圧高度計を使用", isOn: $settings.usesBarometricAltimeter)
                    Picker("天気の更新間隔", selection: $settings.weatherUpdateInterval) {
                        ForEach(WeatherUpdateInterval.allCases) { interval in
                            Text(interval.label).tag(interval)
                        }
                    }
                }
                Section("通知・連携") {
                    Toggle("通知", isOn: notificationBinding)
                }
                Section {
                    LabeledContent("バージョン", value: appVersion)
                }
            }
            .contentMargins(.bottom, 110, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(Color.odoBackground)
            .navigationTitle("設定")
        }
    }

    /// オン操作時のみ通知許可をリクエストし、実際に許可された場合だけオンにする
    private var notificationBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled },
            set: { newValue in
                guard newValue else {
                    settings.notificationsEnabled = false
                    return
                }
                NotificationManager.requestAuthorization { granted in
                    settings.notificationsEnabled = granted
                }
            }
        )
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

#Preview {
    SettingView()
}
