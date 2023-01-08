//
//  DeviceViewModel.swift
//  BTManager
//
//  Created by 程信傑 on 2023/1/7.
//

import Combine
import CoreBluetooth
import Foundation

class DeviceViewModel: ObservableObject {
    @Published var isReady = false
    @Published var value: Int?

    private enum Constants {
        static let readServiceUUID: CBUUID = .init()
        static let writeServiceUUID: CBUUID = .init()
        static let servicesUUID: [CBUUID] = [readServiceUUID, writeServiceUUID]
        static let readCharacteristicUUID: CBUUID = .init()
        static let wirteCharacteristicUUID: CBUUID = .init()
    }

    private var cancellables: Set<AnyCancellable> = .init()
    private var manager: BluetoothManager = .shared

    private let peripheral: CBPeripheral
    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }

    deinit {
        cancellables.cancel()
    }

    func connect() {
        manager.serviceSubject
            .map { services in
                services.filter { service in
                    Constants.servicesUUID.contains(service.uuid)
                }
            }
            .sink { services in
                services.forEach { service in
                    self.peripheral.discoverCharacteristics(nil, for: service)
                }
            }
            .store(in: &cancellables)

        manager.characteristicsSubject
            .filter { $0.0.uuid == Constants.readServiceUUID }
            .compactMap { $0.1.first(where: \.uuid == Constants.readCharacteristicUUID) }
            .sink { [weak self] characteristic in
                self?.readCharacteristic = characteristic
                self?.update(for: characteristic)
            }
            .store(in: &cancellables)

        manager.connect(peripheral)
    }

    private func update(for characteristic: CBCharacteristic) {
        manager.valueSubject
            .map { Int($0) }
            .assign(to: &$value)
        
        manager.registerNotify(for: characteristic)
    }

    private func write(_ data: Data) {
        guard let characteristic = writeCharacteristic else { return }
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }
}

extension Set where Element == AnyCancellable {
    func cancel() {
        forEach { $0.cancel() }
    }
}

func == <Root, Value: Equatable>(lhs: KeyPath<Root, Value>, rhs: Value) -> (Root) -> Bool {
    { $0[keyPath: lhs] == rhs }
}

func == <Root, Value: Equatable>(lhs: KeyPath<Root, Value>, rhs: Value?) -> (Root) -> Bool {
    { $0[keyPath: lhs] == rhs }
}
