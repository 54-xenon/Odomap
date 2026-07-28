//
//  Theme.swift
//  Odomap
//

import SwiftUI
import UIKit

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    /// アプリのアクセントブルー（ライト #0A84FF / ダーク #3AA0FF）
    static let odoAccent = Color(light: Color(hex: 0x0A84FF), dark: Color(hex: 0x3AA0FF))

    /// 画面のベース背景（ライト #F2F2F7 / ダーク #000）
    static let odoBackground = Color(light: Color(hex: 0xF2F2F7), dark: .black)

    /// カード背景（ライト #FFF / ダーク #1C1C1E）
    static let odoCard = Color(light: .white, dark: Color(hex: 0x1C1C1E))
}

/// ホーム・記録中画面の背景グラデーション（上部にうっすら青）
struct SkyGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var strong = false

    var body: some View {
        let top: Color = colorScheme == .dark
            ? Color(hex: 0x0A1A2E)
            : Color(hex: strong ? 0xDCEBFF : 0xEAF4FF)
        let base: Color = colorScheme == .dark ? .black : Color(hex: 0xF2F2F7)
        LinearGradient(
            stops: [
                .init(color: top, location: 0),
                .init(color: base, location: colorScheme == .dark ? 0.55 : 0.45),
                .init(color: base, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// ブランドマーク（バイクのラインアート、viewBox 64x40）
struct BikeMark: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 64
        let sy = rect.height / 40
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var p = Path()
        p.addEllipse(in: CGRect(x: rect.minX + 4 * sx, y: rect.minY + 18 * sy, width: 20 * sx, height: 20 * sy))
        p.addEllipse(in: CGRect(x: rect.minX + 40 * sx, y: rect.minY + 18 * sy, width: 20 * sx, height: 20 * sy))
        p.move(to: pt(14, 28))
        p.addLine(to: pt(26, 14))
        p.addLine(to: pt(38, 14))
        p.addLine(to: pt(50, 28))
        p.move(to: pt(26, 14))
        p.addLine(to: pt(31, 28))
        p.move(to: pt(20, 28))
        p.addLine(to: pt(44, 28))
        p.move(to: pt(38, 14))
        p.addLine(to: pt(44, 6))
        return p
    }
}

func formatDuration(_ interval: TimeInterval) -> String {
    let s = max(0, Int(interval))
    return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
}
