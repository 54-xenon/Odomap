//
//  RideSummaryView.swift
//  Odomap
//

import SwiftUI
import SwiftData

/// 記録終了画面。onSave がある場合は記録直後（保存ボタン表示）、
/// nil の場合は記録一覧からの詳細表示として振る舞う。
struct RideSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var ride: Ride
    var onSave: (() -> Void)?

    @State private var renamingRide: Ride?
    @State private var editingName = ""
    @State private var deletingRide: Ride?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if onSave != nil {
                    header
                }

                RouteMapCard(ride: ride)
                    .frame(height: 260)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())],
                    spacing: 12
                ) {
                    statCard("総距離", value: ride.distanceText)
                    statCard("走行時間", value: ride.durationText)
                    statCard("平均速度", value: ride.avgSpeedText)
                    statCard("最高速度", value: ride.maxSpeedText)
                }

                HStack {
                    Text("獲得標高")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(ride.elevationText)
                        .font(.system(size: 20, weight: .bold))
                }
                .padding(16)
                .background(Color.odoCard)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, onSave != nil ? 8 : 0)
        }
        .contentMargins(.bottom, 110, for: .scrollContent)
        .background(Color.odoBackground)
        .navigationTitle(onSave == nil ? ride.name : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if onSave == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            editingName = ride.name
                            renamingRide = ride
                        } label: {
                            Label("名前を変更", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deletingRide = ride
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .rideRenameDeleteAlerts(
            renamingRide: $renamingRide,
            editingName: $editingName,
            deletingRide: $deletingRide,
            onDelete: { ride in
                modelContext.delete(ride)
                dismiss()
            }
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ride.name)
                    .font(.system(size: 22, weight: .bold))
                Text(ride.fullDateText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                onSave?()
            } label: {
                Text("保存")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.odoAccent)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
    }

    private func statCard(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 24, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.odoCard)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview("保存あり") {
    RideSummaryView(ride: Ride.samples[0]) {}
}

#Preview("詳細表示") {
    NavigationStack {
        RideSummaryView(ride: Ride.samples[0])
    }
}
