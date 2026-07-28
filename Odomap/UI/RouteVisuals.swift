//
//  RouteVisuals.swift
//  Odomap
//

import SwiftUI

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
