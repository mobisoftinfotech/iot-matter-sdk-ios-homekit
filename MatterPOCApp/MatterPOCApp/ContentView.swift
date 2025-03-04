//
//  ContentView.swift
//  MatterPOCApp
//
//  Created by Prashant Telangi on 21/02/25.
//

import SwiftUI
import HomeKit

struct ContentView: View {
    @State private var homes: [HMHome] = []
    @State private var showingAddHomeAlert = false
    @State private var newHomeName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteConfirmation = false
    @State private var homeToDelete: HMHome?
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        showingAddHomeAlert = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Home")
                        }
                    }
                }
                
                Section {
                    ForEach(homes, id: \.uniqueIdentifier) { home in
                        NavigationLink(destination: HomeDetailView(home: home)) {
                            HomeRowView(home: home)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                homeToDelete = home
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Homes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        forceRefresh()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                }
            }
            .onAppear {
                setupHomeUpdates()
                refreshHomes()
            }
            .alert("Add New Home", isPresented: $showingAddHomeAlert) {
                TextField("Home Name", text: $newHomeName)
                Button("Cancel", role: .cancel) {
                    newHomeName = ""
                }
                Button("Add") {
                    addNewHome()
                }
            }
            .alert("Delete Home", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    homeToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let home = homeToDelete {
                        deleteHome(home)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this home?")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func setupHomeUpdates() {
        MatterManager.shared.homesUpdateCallback = {
            refreshHomes()
        }
    }
    
    private func forceRefresh() {
        isRefreshing = true
        
        // Force a reload of homes from HomeKit
        Task {
            // Small dealy to ensure the animation is visible
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Refresh on main thread
            DispatchQueue.main.async {
                // Force reload of homes and accessories
                refreshHomes()
                isRefreshing = false
            }
        }
    }
    
    private func refreshHomes() {
        DispatchQueue.main.async {
            // Get fresh data from HomeKit
            homes = MatterManager.shared.getAvailableHomes().map { home in
                // This forces HomeKit to reload the home's data
                _ = home.accessories
                return home
            }
        }
    }
    
    private func addNewHome() {
        guard !newHomeName.isEmpty else { return }
        
        MatterManager.shared.createHome(named: newHomeName) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    newHomeName = ""
                    refreshHomes()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func deleteHome(_ home: HMHome) {
        Task {
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    MatterManager.shared.deleteHome(home) { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                // Success
                DispatchQueue.main.async {
                    homeToDelete = nil
                    refreshHomes()
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}



#Preview {
    ContentView()
}
