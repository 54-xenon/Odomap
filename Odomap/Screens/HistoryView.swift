//
//  HistoryView.swift
//  Odomap
//

import SwiftUI

struct HistoryView: View {
    var rides: [Ride]

    var body: some View {
        NavigationStack {
            ScrollView {
                if rides.isEmpty {
                    ContentUnavailableView(
                        "記録がありません",
                        systemImage: "map",
                        description: Text("ホーム画面から記録を開始しましょう")
                    )
                    .padding(.top, 80)
                } else {
                    VStack(spacing: 0) {
                        ForEach(rides) { ride in
                            NavigationLink(value: ride) {
                                rideRow(ride, isLast: ride.id == rides.last?.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Color.odoCard)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.horizontal, 16)
                }
            }
            .contentMargins(.bottom, 110, for: .scrollContent)
            .background(Color.odoBackground)
            .navigationTitle("記録一覧")
            .navigationDestination(for: Ride.self) { ride in
                RideSummaryView(ride: ride)
            }
        }
    }

    private func rideRow(_ ride: Ride, isLast: Bool) -> some View {
        HStack(spacing: 14) {
            RouteThumbnail(ride: ride)
            VStack(alignment: .leading, spacing: 2) {
                Text(ride.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(ride.listDateText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(ride.distanceText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(ride.durationText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider().padding(.leading, 86)
            }
        }
        .contentShape(.rect)
    }
}

#Preview {
    HistoryView(rides: Ride.samples)
}
