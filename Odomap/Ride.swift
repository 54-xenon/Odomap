//
//  Ride.swift
//  Odomap
//

import SwiftUI

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
}

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
            thumbnailColors: [Color(hex: 0xFF9F0A), Color(hex: 0xFF6200)]
        ),
    ]

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }
}

// MARK: - ルート表示コンポーネント

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

/// 記録終了画面のルートマップ（MapKit導入まではグリッド地図のプレースホルダ）
struct RouteMapCard: View {
    @Environment(\.colorScheme) private var colorScheme
    var ride: Ride

    var body: some View {
        let mapBackground = colorScheme == .dark ? Color(hex: 0x151821) : Color(hex: 0xE4E9F0)
        let gridColor = colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(hex: 0xB4C3D7, alpha: 0.35)
        GeometryReader { geo in
            let inset = CGRect(origin: .zero, size: geo.size).insetBy(
                dx: geo.size.width * 0.12, dy: geo.size.height * 0.14
            )
            ZStack {
                mapBackground
                Canvas { context, size in
                    let spacing: CGFloat = 26
                    var lines = Path()
                    var x: CGFloat = spacing
                    while x < size.width {
                        lines.move(to: CGPoint(x: x, y: 0))
                        lines.addLine(to: CGPoint(x: x, y: size.height))
                        x += spacing
                    }
                    var y: CGFloat = spacing
                    while y < size.height {
                        lines.move(to: CGPoint(x: 0, y: y))
                        lines.addLine(to: CGPoint(x: size.width, y: y))
                        y += spacing
                    }
                    context.stroke(lines, with: .color(gridColor), lineWidth: 1)
                }
                RouteShape(route: ride.route)
                    .path(in: inset)
                    .stroke(Color.odoAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                Circle().fill(Color(hex: 0x32D74B)).frame(width: 12, height: 12)
                    .position(point(ride.route.start, in: inset))
                Circle().fill(Color(light: Color(hex: 0xFF3B30), dark: Color(hex: 0xFF453A)))
                    .frame(width: 12, height: 12)
                    .position(point(ride.route.end, in: inset))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func point(_ p: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height)
    }
}
