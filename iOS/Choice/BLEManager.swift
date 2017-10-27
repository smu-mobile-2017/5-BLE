//
//  BLEManager.swift
//  Choice
//
//  Created by Paul Herz on 2017-10-26.
//  Copyright © 2017 Paul Herz. All rights reserved.
//

import Foundation
import CoreBluetooth

enum BLEManagerError: Error {
	case notPoweredOn
	case notCurrentlyConnected
}

final class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
	
	typealias RSSIHandlerFunction = (Int, Error?) -> ()
	
	static let notificationPrefix = "com.paulherz.Choice.BLEManager"
	
	static let didReceiveDataNotification = Notification.Name(
		rawValue: "\(notificationPrefix).didReceiveDataNotification"
	)
	static let didConnectNotification = Notification.Name(
		rawValue: "\(notificationPrefix).didConnectNotification"
	)
	static let didDisconnectNotification = Notification.Name(
		rawValue: "\(notificationPrefix).didDisconnectNotification"
	)
	static let didChangeStateNotification = Notification.Name(
		rawValue: "\(notificationPrefix).didChangeStateNotification"
	)
	static let didDiscoverCharacteristicsNotification = Notification.Name(
		rawValue: "\(notificationPrefix).didDiscoverCharacteristics"
	)
	
	private let rbServiceUUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
	private let rbCharacteristicTXUUID = CBUUID(string: "713D0002-503E-4C75-BA94-3148F18D941E")
	private let rbCharacteristicRXUUID = CBUUID(string: "713D0003-503E-4C75-BA94-3148F18D941E")
	
	private var manager: CBCentralManager!
	private(set) var connectedPeripheral: CBPeripheral?
	private var characteristics = [String: CBCharacteristic]()
	private var data: NSMutableData? = NSMutableData()
	private(set) var peripherals = [String: CBPeripheral]()
	private var rssiHandler: RSSIHandlerFunction?
	
	var state: CBManagerState!
	
	override init() {
		super.init()
		self.manager = CBCentralManager(delegate: self, queue: nil)
		self.manager.delegate = self
		self.state = self.manager.state
	}
	
	func scan(forTime time: TimeInterval) throws {
		guard manager.state == .poweredOn else {
			throw BLEManagerError.notPoweredOn
		}
		
		Timer.scheduledTimer(withTimeInterval: time, repeats: false) { timer in
			self.manager.stopScan()
		}
		
		let services = [rbServiceUUID]
		self.manager.scanForPeripherals(withServices: services, options: nil)
	}
	
	func connect(to peripheral: CBPeripheral) throws {
		guard manager.state == .poweredOn else {
			throw BLEManagerError.notPoweredOn
		}
		
		self.manager.connect(peripheral, options: [
			CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(booleanLiteral: true)
		])
	}
	
	func disconnect(from peripheral: CBPeripheral) throws {
		guard manager.state == .poweredOn else {
			throw BLEManagerError.notPoweredOn
		}
		guard peripheral == self.connectedPeripheral else {
			throw BLEManagerError.notCurrentlyConnected
		}
		self.manager.cancelPeripheralConnection(peripheral)
	}
	
	func readRSSI(block: @escaping RSSIHandlerFunction) throws {
		self.rssiHandler = block
		self.connectedPeripheral?.readRSSI()
	}
	
	func read() {
		guard let characteristic = self.characteristics[rbCharacteristicTXUUID.uuidString] else {
			print("Could not retrieve TX characteristic")
			return
		}
		guard let connectedPeripheral = self.connectedPeripheral else {
			print("Could not get connected peripheral")
			return
		}
		connectedPeripheral.readValue(for: characteristic)
	}
	
	func write(_ data: Data) {
		guard let characteristic = self.characteristics[rbCharacteristicRXUUID.uuidString] else {
			print("Could not retrieve RX characteristic")
			print("Desired UUID: \(rbCharacteristicRXUUID.uuidString)")
			print(characteristics)
			return
		}
		guard let connectedPeripheral = self.connectedPeripheral else {
			print("Could not get connected peripheral")
			return
		}
		connectedPeripheral.writeValue(data, for: characteristic, type: .withoutResponse)
	}
	
	// MARK: CBCentralManagerDelegate implementation
	
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		// stubs
		switch central.state {
		case .unknown:
			print("CBCentralManager unknown state")
			break
		case .resetting:
			print("CBCentralManager resetting state")
			break
		case .unsupported:
			print("CBCentralManager unsupported state")
			break
		case .unauthorized:
			print("CBCentralManager unauthorized state")
			break
		case .poweredOff:
			print("CBCentralManager powered off state")
			break
		case .poweredOn:
			print("CBCentralManager powered on state")
			break
		}
		self.state = central.state
		NotificationCenter.default.post(name: BLEManager.didChangeStateNotification, object: self, userInfo: [
			"state": central.state as Any
		])
	}
	
	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
	                    advertisementData: [String : Any], rssi RSSI: NSNumber)
	{
		self.peripherals[peripheral.identifier.uuidString] = peripheral
	}
	
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		self.connectedPeripheral = peripheral
		self.connectedPeripheral?.delegate = self
		self.connectedPeripheral?.discoverServices([rbServiceUUID])
		
		NotificationCenter.default.post(name: BLEManager.didConnectNotification, object: self, userInfo: [
			"uuid": peripheral.identifier.uuidString
		])
	}
	
	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		print("centralManager:didDisconnectPeripheral:")
		if let error = error {
			print(error.localizedDescription)
		}
		
		NotificationCenter.default.post(name: BLEManager.didDisconnectNotification, object: self, userInfo: [
			"uuid": peripheral.identifier.uuidString,
			"error": error as Any
		])
		
		self.connectedPeripheral?.delegate = nil
		self.connectedPeripheral = nil
		self.characteristics = [:]
	}
	
	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		// could not connect
	}
	
	// MARK: CBPeripheralDelegate implementation
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		if let error = error {
			print(error.localizedDescription)
			return
		}
		let txAndRx = [rbCharacteristicTXUUID, rbCharacteristicRXUUID]
		for service in peripheral.services! {
			peripheral.discoverCharacteristics(txAndRx, for: service)
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		print("peripheral(_ peripheral:,didDiscoverCharacteristicsFor service:,error:)")
		if let error = error {
			print(error.localizedDescription)
			return
		}
		for characteristic in service.characteristics! {
			self.characteristics[characteristic.uuid.uuidString] = characteristic
		}
		if let characteristic = self.characteristics[rbCharacteristicTXUUID.uuidString] {
			self.connectedPeripheral?.setNotifyValue(true, for: characteristic)
		}
		
		NotificationCenter.default.post(name: BLEManager.didDiscoverCharacteristicsNotification, object: self)
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		if let error = error {
			print(error.localizedDescription)
			return
		}
		guard characteristic.uuid == rbCharacteristicTXUUID else { return }
		NotificationCenter.default.post(name: BLEManager.didReceiveDataNotification, object: self, userInfo: [
			"data": characteristic.value as Any
		])
	}
	
	func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
		rssiHandler?(RSSI.intValue, error)
	}
}
