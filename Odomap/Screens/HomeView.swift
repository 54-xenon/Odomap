//
//  HomeView.swift
//  Odomap
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    var onStart: () -> Void

    var body: some View {
        // ヘッダー -> FlutterでういうAppBar
        ZStack {
            SkyGradientBackground()
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Odomap")
                        .font(.system(size: 28, weight: .bold))
                }

                startButton
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                Spacer()
            }
            .padding(20)
        }
    }
    
    // スタートボタン -> これはそのうちUIをまとめたディレクトリの中に移動させたい
    private var startButton: some View {
        let gradient: [Color] = colorScheme == .dark
            ? [Color(hex: 0x3AA0FF), Color(hex: 0x0A64D8), Color(hex: 0x003A99)]
            : [Color(hex: 0x57B7FF), Color(hex: 0x0A84FF), Color(hex: 0x0050D8)]
        return Button(action: onStart) {
            VStack(spacing: 8) {
                BikeMark()
                    .stroke(style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
                    .frame(width: 46, height: 30)
                Text("記録開始")
                    .font(.system(size: 19, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(width: 186, height: 186)
            .background {
                Circle().fill(
                    LinearGradient(
                        stops: [
                            .init(color: gradient[0], location: 0),
                            .init(color: gradient[1], location: 0.55),
                            .init(color: gradient[2], location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                Circle()
                    .inset(by: 1)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(colorScheme == .dark ? 0.35 : 0.6), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 0.5)
            }
            .shadow(
                color: Color(hex: 0x0A84FF, alpha: colorScheme == .dark ? 0.5 : 0.35),
                radius: 25, y: 12
            )
        }
        .buttonStyle(.plain)
    }


}


