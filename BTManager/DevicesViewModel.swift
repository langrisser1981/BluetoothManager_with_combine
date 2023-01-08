//
//  DevicesViewModel.swift
//  BTManager
//
//  Created by 程信傑 on 2023/1/7.
//

import Combine
import CoreBluetooth
import Foundation

class DevicesViewModel: ObservableObject {
    @Published var state: CBManagerState = .unknown
    @Published var peripherals: [CBPeripheral] = []
    
    private var manager: BluetoothManager = .shared
    private var cancellables: Set<AnyCancellable> = .init()
    
    deinit {
        cancellables.cancel()
    }
    
    func start() {
        manager.stateSubject
            .sink { state in
                self.state = state
                if state == .poweredOn {
                    self.manager.scan()
                }
                    
            }.store(in: &cancellables)
        
        manager.peripheralSubject
            .filter { peripheral in
                self.peripherals.contains(peripheral) == false
            }
            .sink { peripheral in
                print(peripheral)
                self.peripherals.append(peripheral)
            }
            .store(in: &cancellables)
        
        manager.start()
    }
}
