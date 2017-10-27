//
//  ControlPanelViewController.swift
//  Choice
//
//  Created by Paul Herz on 2017-10-26.
//  Copyright © 2017 Paul Herz. All rights reserved.
//

import UIKit

class ControlPanelViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
	
	typealias RGB = [Int]
	
	@IBOutlet weak var answerPicker: UIPickerView!
	@IBOutlet weak var servoPositionLabel: UILabel!
	@IBOutlet weak var ledColorView: UIView!
	@IBOutlet weak var ledColorLabel: UILabel!
	
	@IBOutlet weak var redLabel: UILabel!
	@IBOutlet weak var greenLabel: UILabel!
	@IBOutlet weak var blueLabel: UILabel!
	var colorLabels: [UILabel] {
		return [redLabel,greenLabel,blueLabel]
	}
	
	@IBOutlet weak var redSlider: UISlider!
	@IBOutlet weak var greenSlider: UISlider!
	@IBOutlet weak var blueSlider: UISlider!
	var colorSliders: [UISlider] {
		return [redSlider,greenSlider,blueSlider]
	}
	
	@IBOutlet weak var potentiometerKnob: Knob!
	@IBOutlet weak var potentiometerLabel: UILabel!
	
	var bleManager: BLEManager = (UIApplication.shared.delegate as! AppDelegate).bleManager
	var currentColor: RGB? = nil
	
	let servoOptions = ["A","B","C","D"]
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		potentiometerKnob.isUserInteractionEnabled = false
		// Do any additional setup after loading the view, typically from a nib.
		answerPicker.delegate = self
		updateCurrentColor(nil, updateDevice: true, updateSliders: true, updatePane: false)
		
		Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
			self.readDeviceState()
		}
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.didReceiveData(notification:)),
			name: BLEManager.didReceiveDataNotification,
			object: nil
		)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		if let connectedPeripheral = bleManager.connectedPeripheral {
			try? bleManager.disconnect(from: connectedPeripheral)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@objc func didReceiveData(notification: Notification) {
		//print("didReceiveData")
		guard let data = notification.userInfo?["data"] as? Data else {
			print("no data")
			return
		}
		var bytes = ContiguousArray<UInt8>(repeating: 0, count: 20)
		bytes.withUnsafeMutableBufferPointer { (pointer) -> Void in
			let _ = data.copyBytes(to: pointer)
		}
		
		let servoPosition: UInt16 = (UInt16(bytes[0]) << 8) + UInt16(bytes[1])
		let potentiometerPosition: UInt16 = (UInt16(bytes[2]) << 8) + UInt16(bytes[3])
		let color: RGB = [Int(bytes[6]),Int(bytes[7]),Int(bytes[8])]
		
//		print("Servo: \(servoPosition)")
//		print("Poten: \(potentiometerPosition)")
//		print("Color: \(color)")
		
		updateCurrentColor(color, updateDevice: false, updateSliders: false, updatePane: true)
		updatePotentiometerDisplay(to: potentiometerPosition)
		updateServoDisplay(to: servoPosition)
	}
	
	func updateCurrentColor(_ color: RGB?, updateDevice: Bool, updateSliders: Bool, updatePane: Bool) {
		self.currentColor = color
		var colorText: String
		var sliderValues: [Float]
		if let color = color {
			colorText = "rgb(\(color[0]),\(color[1]),\(color[2]))"
			
			let uic = color.map { CGFloat($0)/255 }
			if updatePane {
				ledColorView.backgroundColor = UIColor(
					red: uic[0], green: uic[1], blue: uic[2], alpha: 1.0
				)
			}
			let _ = zip(self.colorLabels,color).map { $0.text = "\($1)" }
			sliderValues = color.map { return Float($0)/255.0 }
		} else {
			colorText = "—"
			if updatePane {
				ledColorView.backgroundColor = .black
			}
			let _ = self.colorLabels.map { $0.text = "—" }
			sliderValues = [0,0,0]
		}
		if updatePane {
			ledColorLabel.text = colorText
		}
		if updateSliders {
			let _ = zip(self.colorSliders, sliderValues).map { t in t.0.value = t.1 }
		}
		if updateDevice {
			setDeviceLED(color: color)
		}
	}
	
	func updatePotentiometerDisplay(to x: UInt16) {
		potentiometerLabel.text = "Potentiometer: \(x)"
		potentiometerKnob.value = Double(x)/4095.0*2.0*Double.pi
	}
	
	func updateServoDisplay(to x: UInt16) {
		servoPositionLabel.text = "\(x) deg"
	}
	
	func setDeviceLED(color: RGB?) {
		let c = color ?? [0,0,0]
		let msg = "l \(c[0]) \(c[1]) \(c[2])"
		send(message: msg)
	}
	
	func readDeviceState() {
		send(message: "r")
	}
	
	func send(message: String) {
		var data = message.data(using: .ascii)!
		var value: Int8 = 0x0
		data.append(UnsafeBufferPointer(start: &value, count: 1))
		bleManager.write(data)
	}
	
	// MARK UIPickerViewDelegate and UIPickerViewDataSource
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return servoOptions.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return servoOptions[row]
	}
	
	// MARK event handling
	
	@IBAction func didChangeColorSlider(_ sender: UISlider) {
		let color = colorSliders.map { Int($0.value * 255) }
		updateCurrentColor(color, updateDevice: true, updateSliders: false, updatePane: false)
	}
	
	@IBAction func didChangePotentiometerKnob(_ sender: Knob) {
	}
}

