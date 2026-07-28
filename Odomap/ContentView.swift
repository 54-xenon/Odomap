//
//  ContentView.swift
//  Odomap
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @State private var rides: [Ride] = Ride.samples
    @State private var isRecording = false

    var body: some View {
        TabView(selection: $selection) {
            HomeView(onStart: { isRecording = true })
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)

            HistoryView(rides: rides)
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }
                .tag(1)

            SettingView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .fullScreenCover(isPresented: $isRecording) {
            RecordView { ride in
                rides.insert(ride, at: 0)
            }
        }
    }
}

#Preview {
    ContentView()
}
