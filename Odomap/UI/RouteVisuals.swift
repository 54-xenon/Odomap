//
//  RouteVisuals.swift
//  Odomap
//

import SwiftUI
import MapKit

// MARK: - ルート表示コンポーネント

struct RouteShape: Shape {
    var route: RouteData

    func path(in rect: CGRect) -> Path {
        func pt(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height)
        }
        var path = Path()
        path.move(to: pt(route.start))
        for c in route.curves {
            path.addCurve(to: pt(c.end), control1: pt(c.control1), control2: pt(c.control2))
        }
        return path
    }
}

/// 記録一覧・ホームで使う 56x56 のルートサムネイル
struct RouteThumbnail: View {
    var ride: Ride

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: ride.thumbnailColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                RouteShape(route: ride.route)
                    .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                Circle().fill(.white).frame(width: 6, height: 6)
                    .position(point(ride.route.start, in: geo.size))
                Circle().fill(.white).frame(width: 6, height: 6)
                    .position(point(ride.route.end, in: geo.size))
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func point(_ p: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: p.y * size.height)
    }
}

/// 記録終了画面のルートマップ。実GPS座標を MKPolyline として描画する。
struct RouteMapCard: View {
    var ride: Ride

    var body: some View {
        Map(initialPosition: .region(region)) {
            MapPolyline(coordinates: ride.coordinates)
                .stroke(Color.odoAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

            if let start = ride.coordinates.first {
                Marker("開始", coordinate: start)
                    .tint(Color(hex: 0x32D74B))
            }
            if ride.coordinates.count > 1, let end = ride.coordinates.last {
                Marker("終了", coordinate: end)
                    .tint(Color(hex: 0xFF3B30))
            }
        }
        .mapControlVisibility(.hidden)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var region: MKCoordinateRegion {
        guard !ride.coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        let lats = ride.coordinates.map(\.latitude)
        let lons = ride.coordinates.map(\.longitude)
        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 0
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.01)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
