//
//  RideEditingAlerts.swift
//  Odomap
//

import SwiftUI

extension Binding where Value == Ride? {
    var isPresented: Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { if !$0 { wrappedValue = nil } }
        )
    }
}

extension View {
    /// 記録の名前変更・削除を行う共通アラート。renamingRide / deletingRide が非 nil の間表示される。
    func rideRenameDeleteAlerts(
        renamingRide: Binding<Ride?>,
        editingName: Binding<String>,
        deletingRide: Binding<Ride?>,
        onDelete: @escaping (Ride) -> Void
    ) -> some View {
        self
            .alert("名前を変更", isPresented: renamingRide.isPresented) {
                TextField("記録の名前", text: editingName)
                Button("キャンセル", role: .cancel) {}
                Button("保存") {
                    let trimmed = editingName.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        renamingRide.wrappedValue?.name = trimmed
                    }
                }
            }
            .confirmationDialog(
                "この記録を削除しますか？",
                isPresented: deletingRide.isPresented,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    if let ride = deletingRide.wrappedValue {
                        onDelete(ride)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                if let name = deletingRide.wrappedValue?.name {
                    Text(name)
                }
            }
    }
}
