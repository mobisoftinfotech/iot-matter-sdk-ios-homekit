//
//  HomeRow.swift
//  MatterPOCApp
//
//  Created by Prashant Telangi on 25/02/25.
//


import SwiftUI
import HomeKit

struct HomeRowView: View {
    let home: HMHome
    @State private var accessoryCount: Int
    
    init(home: HMHome) {
        self.home = home
        // Initialize with current count
        self._accessoryCount = State(initialValue: home.accessories.count)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(home.name)
                .font(.headline)
            Text("Accessories: \(accessoryCount)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
        .onAppear {
            // Update count when view appears
            updateAccessoryCount()
        }
    }
    
    private func updateAccessoryCount() {
        accessoryCount = home.accessories.count
    }
}
