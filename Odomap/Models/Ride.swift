//
//  Ride.swift
//  Odomap
//

import SwiftUI
import CoreLocation

// MARK: - ルートデータ（正規化座標 0-1）

struct RouteCurve {
    var control1: CGPoint
    var control2: CGPoint
    var end: CGPoint
}

struct RouteData {
    var start: CGPoint
    var curves: [RouteCurve]

    var end: CGPoint { curves.last?.end ?? start }

    private static func normalized(_ box: CGFloat, _ start: (CGFloat, CGFloat), _ curves: [((CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat))]) -> RouteData {
        func pt(_ p: (CGFloat, CGFloat)) -> CGPoint { CGPoint(x: p.0 / box, y: p.1 / box) }
        return RouteData(
            start: pt(start),
            curves: curves.map { RouteCurve(control1: pt($0.0), control2: pt($0.1), end: pt($0.2)) }
        )
    }

    static let diagonal = normalized(56, (10, 44), [((18, 40), (14, 28), (24, 26)), ((34, 24), (30, 12), (42, 10))])
    static let coastal = normalized(56, (8, 20), [((20, 22), (18, 34), (30, 32)), ((40, 30), (38, 40), (48, 38))])
    static let winding = normalized(56, (12, 42), [((24, 36), (20, 20), (34, 18)), ((42, 17), (40, 10), (46, 8))])

    /// 実GPS座標を 0-1 の緯度経度バウンディングボックスに正規化し、サムネイル用の折れ線として組み立てる
    static func fromCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> RouteData {
        guard coordinates.count >= 2 else { return .diagonal }

        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        let latSpan = max((lats.max() ?? 0) - (lats.min() ?? 0), 0.0001)
        let lonSpan = max((lons.max() ?? 0) - (lons.min() ?? 0), 0.0001)
        let minLat = lats.min() ?? 0
        let minLon = lons.min() ?? 0

        func point(_ c: CLLocationCoordinate2D) -> CGPoint {
            CGPoint(
                x: (c.longitude - minLon) / lonSpan,
                y: 1 - (c.latitude - minLat) / latSpan
            )
        }

        let points = coordinates.map(point)
        let curves = points.dropFirst().map { RouteCurve(control1: $0, control2: $0, end: $0) }
        return RouteData(start: points[0], curves: Array(curves))
    }
}

// MARK: - Ride モデル（GPS実装まではサンプル値で表示）

struct Ride: Identifiable {
    let id = UUID()
    var name: String
    var date: Date
    var distanceKm: Double
    var duration: TimeInterval
    var maxSpeedKmh: Double
    var elevationGain: Double
    var route: RouteData
    var coordinates: [CLLocationCoordinate2D] = []
    var thumbnailColors: [Color]

    var avgSpeedKmh: Double {
        duration > 0 ? distanceKm / (duration / 3600) : 0
    }

    var distanceText: String { String(format: "%.1f km", distanceKm) }
    var durationText: String { formatDuration(duration) }
    var avgSpeedText: String { String(format: "%.1f km/h", avgSpeedKmh) }
    var maxSpeedText: String { String(format: "%.1f km/h", maxSpeedKmh) }
    var elevationText: String { String(format: "%.0f m", elevationGain) }

    var shortDateText: String { Self.shortFormatter.string(from: date) }
    var listDateText: String { Self.listFormatter.string(from: date) }
    var fullDateText: String { Self.fullFormatter.string(from: date) }

    private static let shortFormatter: DateFormatter = makeFormatter("M/d")
    private static let listFormatter: DateFormatter = makeFormatter("M月d日")
    private static let fullFormatter: DateFormatter = makeFormatter("M月d日（E）")

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = format
        return f
    }
}

extension Ride: Hashable {
    static func == (lhs: Ride, rhs: Ride) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Ride {
    static let samples: [Ride] = [
        // モック用のサンプルデータ -> SwiftDateでデータの永続化ができたら消す
        Ride(
            name: "白馬ツーリング",
            date: date(2026, 7, 24),
            distanceKm: 184.2,
            duration: 3 * 3600 + 42 * 60 + 10,
            maxSpeedKmh: 98.2,
            elevationGain: 612,
            route: .diagonal,
            coordinates: sampleCoordinates,
            thumbnailColors: [Color(hex: 0xFF9F0A), Color(hex: 0xFF6200)]
        ),
    ]

    /// プレビュー・サンプル用の白馬周辺の実座標（GPS未実装時のフォールバック）
    private static let sampleCoordinates: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 36.6982, longitude: 137.8710),
        CLLocationCoordinate2D(latitude: 36.7040, longitude: 137.8790),
        CLLocationCoordinate2D(latitude: 36.7120, longitude: 137.8850),
        CLLocationCoordinate2D(latitude: 36.7200, longitude: 137.8800),
        CLLocationCoordinate2D(latitude: 36.7260, longitude: 137.8720),
        CLLocationCoordinate2D(latitude: 36.7210, longitude: 137.8650),
    ]

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }
}
