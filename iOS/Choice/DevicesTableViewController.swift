//
//  DevicesTableViewController.swift
//  Choice
//
//  Created by Paul Herz on 2017-10-27.
//  Copyright © 2017 Paul Herz. All rights reserved.
//

import UIKit
import CoreBluetooth

class DevicesTableViewController: UITableViewController {
	
	var readyToScan = false
	var needsInitialTableLoad = true
	let bleManager = (UIApplication.shared.delegate as! AppDelegate).bleManager
	var connectedPeripheral: CBPeripheral?
	
	var peripherals: [CBPeripheral] = [] {
		didSet {
//			self.tableView.reloadData()
			CATransaction.setDisableActions(true)
			self.tableView.reloadSections(IndexSet(integer: 0), with: .top)
			CATransaction.setDisableActions(false)
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.refreshControl = UIRefreshControl()
		self.refreshControl?.addTarget(self, action: #selector(self.didPullRefresh), for: .valueChanged)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.bleDidChangeState(notification:)),
			name: BLEManager.didChangeStateNotification,
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.bleDidConnect(notification:)),
			name: BLEManager.didConnectNotification,
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.bleDidDiscoverCharacteristics(notification:)),
			name: BLEManager.didDiscoverCharacteristicsNotification,
			object: nil
		)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	private func alert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(
			title: NSLocalizedString("OK", comment: "Default action"),
			style: .default,
			handler: nil
		))
		self.present(alert, animated: true, completion: nil)
	}
	
	@objc func didPullRefresh() {
		let scanTime: TimeInterval = 2.0
		
		// Spin the refresh control
		self.refreshControl?.beginRefreshing()
		let scrollView = self.tableView as UIScrollView
		scrollView.setContentOffset(
			CGPoint(x: 0.0, y: scrollView.contentOffset.y - self.refreshControl!.frame.size.height),
			animated: true
		)
		
		needsInitialTableLoad = false
		
		Timer.scheduledTimer(withTimeInterval: scanTime, repeats: false) { timer in
			self.refreshControl?.endRefreshing()
			// [CITE] https://stackoverflow.com/a/27673136/3592716
			// must delay table reloading until after endRefreshing finishes
			// animation
			Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { timer in
				self.peripherals = Array(self.bleManager.peripherals.values)
			}
		}
		// Actually scan
		do {
			try bleManager.scan(forTime: scanTime)
		} catch BLEManagerError.notPoweredOn {
			alert(title: "BLE Error", message: "Please turn on Bluetooth.")
			self.refreshControl?.endRefreshing()
		} catch let error {
			alert(title: "Unknown Error", message: String(describing: error))
			self.refreshControl?.endRefreshing()
		}
	}
	
	@objc func bleDidChangeState(notification: Notification) {
		if bleManager.state == .poweredOn && needsInitialTableLoad {
			didPullRefresh()
		} else {
			print(bleManager.state == .poweredOn)
			print(needsInitialTableLoad)
		}
	}
	
	@objc func bleDidConnect(notification: Notification) {
		// nothing
	}
	
	@objc func bleDidDiscoverCharacteristics(notification: Notification) {
		performSegue(withIdentifier: "openControlPanel", sender: self)
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return peripherals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath)
		
		let peripheral = peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name
		cell.detailTextLabel?.text = peripheral.identifier.uuidString

        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let peripheral = peripherals[indexPath.row]
		do {
			try bleManager.connect(to: peripheral)
			// the discover characteristics event handler performs segue
		} catch BLEManagerError.notPoweredOn {
			print("Not powered on")
		} catch let error {
			print(String(describing: error))
		}
		self.connectedPeripheral = peripheral
	}

	
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
//		if let controlPanel = segue.destination as? ControlPanelViewController {
//			controlPanel.peripheral
//		}
    }


}
