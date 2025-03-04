//
//  HomeDetailView.swift
//  MatterPOCApp
//
//  Created by Prashant Telangi on 25/02/25.
//
import SwiftUI
import HomeKit

struct HomeDetailView: View {
    let home: HMHome
    @State private var lights: [HMAccessory] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section {
                Button(action: {
                    addAccessory()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Accessory")
                    }
                }
            }
            
            Section {
                ForEach(lights, id: \.uniqueIdentifier) { light in
                    LightRowView(light: light)
                }
            }
        }
        .navigationTitle(home.name)
        .onAppear {
            lights = MatterManager.shared.getLights(in: home)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func addAccessory() {
        Task {
            do {
                try await MatterManager.shared.addAccessory(to: home)
            } catch {
                showingError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}
