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
        let route = ride.route
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: ride.thumbnailColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                RouteShape(route: route)
                    .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                Circle().fill(.white).frame(width: 6, height: 6)
                    .position(point(route.start, in: geo.size))
                Circle().fill(.white).frame(width: 6, height: 6)
                    .position(point(route.end, in: geo.size))
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func point(_ p: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: p.y * size.height)
    }
}

extension StrokeStyle {
    /// 記録ルート（ライブ／確定後）で共通して使う線のスタイル
    static let routeLine = StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
}

/// 記録中画面に表示するライブマップ。現在地に追従しながら、ここまでのルートを描画する。
struct LiveRouteMapCard: View {
    var coordinates: [CLLocationCoordinate2D]

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var lastCenteredCoordinate: CLLocationCoordinate2D?

    /// この距離未満の移動では再センタリングしない（GPS更新のたびにカメラが揺れるのを防ぐ）
    private static let recenterThreshold: CLLocationDistance = 8

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            if coordinates.count > 1 {
                MapPolyline(coordinates: coordinates)
                    .stroke(Color.odoAccent, style: .routeLine)
            }
            if let current = coordinates.last {
                Annotation("現在地", coordinate: current) {
                    Circle()
                        .fill(Color.odoAccent)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(radius: 3)
                }
            }
        }
        .mapControlVisibility(.hidden)
        .onChange(of: coordinates.last?.latitude) { _, _ in
            centerOnCurrentLocationIfNeeded()
        }
        .onAppear {
            centerOnCurrentLocation(animated: false)
        }
    }

    private func centerOnCurrentLocationIfNeeded() {
        guard let current = coordinates.last else { return }
        if let last = lastCenteredCoordinate {
            let moved = CLLocation(latitude: current.latitude, longitude: current.longitude)
                .distance(from: CLLocation(latitude: last.latitude, longitude: last.longitude))
            guard moved >= Self.recenterThreshold else { return }
        }
        centerOnCurrentLocation(animated: true)
    }

    private func centerOnCurrentLocation(animated: Bool) {
        guard let current = coordinates.last else { return }
        lastCenteredCoordinate = current
        let region = MKCoordinateRegion(
            center: current,
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )
        if animated {
            withAnimation { cameraPosition = .region(region) }
        } else {
            cameraPosition = .region(region)
        }
    }
}

/// 記録終了画面のルートマップ。実GPS座標を MKPolyline として描画する。
struct RouteMapCard: View {
    var ride: Ride

    var body: some View {
        Map(initialPosition: .region(region)) {
            MapPolyline(coordinates: ride.coordinates)
                .stroke(Color.odoAccent, style: .routeLine)

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
