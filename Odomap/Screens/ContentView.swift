//
//  ContentView.swift
//  Odomap
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ride.date, order: .reverse) private var rides: [Ride]
    @State private var selection = 0
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
                modelContext.insert(ride)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Ride.self, inMemory: true)
}
