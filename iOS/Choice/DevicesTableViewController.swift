//
//  DevicesTableViewController.swift
//  Choice
//
//  Created by Paul Herz on 2017-10-27.
//  Copyright © 2017 Paul Herz. All rights reserved.
//

import UIKit

class DevicesTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		self.refreshControl = UIRefreshControl()
		self.refreshControl?.addTarget(self, action: #selector(self.didRefreshTable), for: .valueChanged)
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
	
	@objc func didRefreshTable() {
		print("didRefreshTable")
		let scanTime: TimeInterval = 10.0
		
		// Spin the refresh control
		// [CITE] https://stackoverflow.com/a/39950613/3592716
		self.refreshControl?.layoutIfNeeded()
		self.refreshControl?.beginRefreshing()
		Timer.scheduledTimer(withTimeInterval: scanTime, repeats: false) { timer in
			self.refreshControl?.endRefreshing()
			print(BLEManager.shared.peripherals)
		}
		// Actually scan
		do {
			try BLEManager.shared.scan(forTime: scanTime)
		} catch BLEManagerError.notPoweredOn {
			alert(title: "BLE Error", message: "Please turn on Bluetooth.")
			self.refreshControl?.endRefreshing()
		} catch let error {
			alert(title: "Unknown Error", message: String(describing: error))
			self.refreshControl?.endRefreshing()
		}
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath)

        // Configure the cell...

        return cell
    }
	

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
