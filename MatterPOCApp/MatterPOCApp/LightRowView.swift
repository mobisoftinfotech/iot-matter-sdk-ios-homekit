//
//  LightRowView.swift
//  MatterPOCApp
//
//  Created by Prashant Telangi on 25/02/25.
//
import SwiftUI
import HomeKit

struct LightRowView: View {
    let light: HMAccessory
    @State private var isOn: Bool? = nil
    @State private var isUpdating = false
    
    var body: some View {
        HStack {
            Text(light.name)
            Spacer()
            if let currentState = isOn {
                Toggle("", isOn: Binding(
                    get: { currentState },
                    set: { newValue in
                        if newValue != currentState {
                            isOn = newValue
                            toggleLight()
                        }
                    }
                ))
                .disabled(isUpdating)
            }
        }
        .onAppear {
            setupLightObservation()
        }
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
    
    private func setupLightObservation() {
        guard let lightService = light.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }),
              let powerCharacteristic = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) else {
            return
        }
        
        // Get initial state without triggering a toggle
        powerCharacteristic.readValue { error in
            if let error = error {
                print("Failed to read initial value: \(error)")
                return
            }
            
            if let value = powerCharacteristic.value as? Bool {
                DispatchQueue.main.async {
                    // Set initial state
                    isOn = value
                }
            }
        }
        
        // Enable notifications for changes
        powerCharacteristic.enableNotification(true) { error in
            if let error = error {
                print("Failed to enable notifications: \(error)")
            }
        }
    }
    
    private func toggleLight() {
        guard !isUpdating else { return }
        isUpdating = true
        
        Task {
            do {
                try await MatterManager.shared.toggleLight(light)
            } catch {
                print("Failed to toggle light: \(error)")
                // Revert the toggle if failed
                if let currentState = isOn {
                    isOn = !currentState
                }
            }
            isUpdating = false
        }
    }
}
