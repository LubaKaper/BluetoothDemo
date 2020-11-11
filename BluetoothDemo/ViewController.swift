//
//  ViewController.swift
//  BluetoothDemo
//
//  Created by Liubov Kaper  on 11/10/20.
//  Copyright © 2020 Luba Kaper. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    // central device(iphone)
    var centralManager: CBCentralManager!
    
    // make a device both Central and Peripheral to send a recieve data?..
    var periferalManager: CBPeripheralManager!
    
    // peripheral device(mac)
    var myPeripheral: CBPeripheral!
    
    let serviceUUID = CBUUID(string: "7CFC30B7-3856-4566-85A1-FF908C7B2C35") // FAA5BE26-97B7-516B-8900-5F4E977CF915
    let WR_UUID = CBUUID(string: "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX")
    let WR_PROPERTIES: CBCharacteristicProperties = .write
    let WR_PERMISSIONS: CBAttributePermissions = .writeable
    
    
    let characteristicsUUID = CBUUID(string: "BAA2")
    
    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager()
        centralManager.delegate = self
        
        periferalManager = CBPeripheralManager()
        periferalManager.delegate = self
    }


}

extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - CentralManager delegate
    
    // This method keeps track of the state the the bluetooth is in
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            print("BLE powered on")
            self.centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
            //centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
            // turned on
        } else {
            print("something wrong with BLE")
        }
        
       // central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    // Connect to device when discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        centralManager.stopScan()
        
        myPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
//        if let pname = peripheral.name {
//            print(pname)
//        }
    }
    
    /* We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
             */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
               
        
        print("Peripheral Connected")

        peripheral.delegate = self
        peripheral.discoverServices(nil) //[serviceUUID]
        
    }
    
    // MARK: - Peripheral delegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        if let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) {
//            peripheral.discoverCharacteristics([characteristicsUUID], for: service)
//        }
        
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        
//        if let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicsUUID }) {
//            peripheral.setNotifyValue(true, for: characteristic)
//        }
        
        for characteristic in service.characteristics! {
            let characteristic = characteristic as CBCharacteristic
            if characteristic.uuid.isEqual(WR_UUID) {
                if let messageText = label.text { // change label to textfield
                    let data = messageText.data(using: .utf8)
                    peripheral.writeValue(data!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                    
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            let digits: Int = data.withUnsafeBytes { $0.pointee }
            label.text = String(digits)
        }
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            
            let serialService = CBMutableService(type: serviceUUID, primary: true)
            let writeCharacteristics = CBMutableCharacteristic(type: WR_UUID, properties: WR_PROPERTIES, value: nil, permissions: WR_PERMISSIONS)
            serialService.characteristics = [writeCharacteristics]
            
            periferalManager.add(serialService)
            
            
            let advertisementData = String(format: "%@|%d|%d")
            periferalManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[serviceUUID],CBAdvertisementDataLocalNameKey: advertisementData])
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let value = request.value {
                let text = String(data: value, encoding: String.Encoding.utf8) as String?
            }
            self.periferalManager.respond(to: request, withResult: .success)
        }
    }
    
    
}
