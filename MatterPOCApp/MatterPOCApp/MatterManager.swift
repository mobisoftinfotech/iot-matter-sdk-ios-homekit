//
//  MatterManager.swift
//  MatterPOCApp
//
//  Created by Prashant Telangi on 25/02/25.
//

import HomeKit
import Matter

enum MatterError: Error {
    case invalidSetupCode
    case commissioningFailed
    case unknown
}

class MatterManager: NSObject {
    static let shared = MatterManager()
    let homeManager = HMHomeManager()
    private let setupManager = HMAccessorySetupManager()
    
    var homesUpdateCallback: (() -> Void)?
    
    private override init() {
        super.init()
        homeManager.delegate = self
    }
    
    func getAvailableHomes() -> [HMHome] {
        return homeManager.homes
    }
    
    func createHome(named name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        homeManager.addHome(withName: name) { [weak self] home, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
                self?.homesUpdateCallback?()
            }
        }
    }
    
    func addAccessory(to home: HMHome) async throws {
        let setupManager = HMAccessorySetupManager()
        let request = HMAccessorySetupRequest()
        
        // Configure the request for the home
        request.homeUniqueIdentifier = home.uniqueIdentifier
        
        // Perform the setup
        do {
            let result = try await setupManager.performAccessorySetup(using: request)
            print("Accessory setup completed successfully: \(result)")
            homesUpdateCallback?()
        } catch {
            print("Failed to setup accessory: \(error)")
            throw error
        }
    }
    
    func deleteHome(_ home: HMHome, completion: @escaping (Result<Void, Error>) -> Void) {
        // Remove all accessories
        let group = DispatchGroup()
        
        for accessory in home.accessories {
            group.enter()
            home.removeAccessory(accessory) { error in
                if let error = error {
                    print("Failed to remove accessory: \(error)")
                }
                group.leave()
            }
        }
        
        // Remove the home
        group.notify(queue: .main) {
            self.homeManager.removeHome(home) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    self.homesUpdateCallback?()
                }
            }
        }
    }
    
}

// MARK: - Control Lights
extension MatterManager {
    
    func toggleLight(_ accessory: HMAccessory) async throws {
        guard let lightService = accessory.services.first(where: { service in
            service.serviceType == HMServiceTypeLightbulb
        }) else {
            throw HMError(.invalidParameter)
        }
        
        guard let powerCharacteristic = lightService.characteristics.first(where: { characteristic in
            characteristic.characteristicType == HMCharacteristicTypePowerState
        }) else {
            throw HMError(.invalidParameter)
        }
        
        // Toggle the current state
        let currentValue = powerCharacteristic.value as? Bool ?? false
        try await powerCharacteristic.writeValue(!currentValue)
    }
    
    func getLights(in home: HMHome) -> [HMAccessory] {
        return home.accessories.filter { accessory in
            accessory.services.contains { service in
                service.serviceType == HMServiceTypeLightbulb
            }
        }
    }
}

// MARK: - HMHomeManagerDelegate
extension MatterManager: HMHomeManagerDelegate {
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        print("Homes updated: \(manager.homes.count) homes available")
        DispatchQueue.main.async {
            self.homesUpdateCallback?()
        }
    }
    
    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        print("HomeManager authorization status updated: \(status)")
        DispatchQueue.main.async {
            self.homesUpdateCallback?()
        }
    }
    
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        print("New home added: \(home.name)")
    }
    
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        print("Home removed: \(home.name)")
    }
}




