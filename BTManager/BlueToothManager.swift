//
//  BlueToothManager.swift
//  BTManager
//
//  Created by 程信傑 on 2023/1/7.
//

import Combine
import CoreBluetooth
import Foundation

final class BluetoothManager: NSObject {
    static let shared: BluetoothManager = .init()
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!

    var stateSubject = PassthroughSubject<CBManagerState, Never>()
    var peripheralSubject = PassthroughSubject<CBPeripheral, Never>()
    var serviceSubject = PassthroughSubject<[CBService], Never>()
    var characteristicsSubject = PassthroughSubject<(CBService, [CBCharacteristic]), Never>()
    var valueSubject = PassthroughSubject<UInt8, Never>()

    // 啟動，回報系統藍芽狀態
    func start() {
        centralManager = .init(delegate: self, queue: .main)
    }

    func scan() {
        // 搜尋裝置，回報找到的裝置，連線裝置，回報裝置連上，尋找服務，回報找到的服務、特性
        centralManager.scanForPeripherals(withServices: nil)
    }

    func connect(_ peripheral: CBPeripheral) {
        centralManager.stopScan()
        centralManager.connect(peripheral)
        peripheral.delegate = self
        self.peripheral = peripheral
    }

    func registerNotify(for characteristic: CBCharacteristic) {
        guard let peripheral else { return }
        peripheral.setNotifyValue(true, for: characteristic)
    }
}

// 回報裝置藍芽狀態改變、發現裝置、連上裝置
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        stateSubject.send(central.state)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        peripheralSubject.send(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
}

// 回報找到服務、特性
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services else { return }
        serviceSubject.send(service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        characteristicsSubject.send((service, characteristics))
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let buffer = [UInt8](data)
        if (buffer[0] & 0x01) == 0 {
            let value = UInt8(buffer[1])
            valueSubject.send(value)
        } else {
            return
        }
    }
}
