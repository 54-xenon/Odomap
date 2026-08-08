//
//  SettingView.swift
//  Odomap
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("単位") {
                    settingRow("距離・速度の単位", detail: "km")
                }
                Section("計測") {
                    settingRow("精度優先モード", detail: "ナビ用（高精度）")
                    settingRow("気圧高度計を使用", detail: "オン")
                    settingRow("天気の更新間隔", detail: "10分")
                }
                Section("通知・連携") {
                    settingRow("通知", detail: "オン")
                }
                Section {
                    LabeledContent("バージョン", value: "1.0.0")
                }
            }
            .contentMargins(.bottom, 110, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(Color.odoBackground)
            .navigationTitle("設定")
        }
    }

    private func settingRow(_ title: String, detail: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(detail)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    SettingView()
}
