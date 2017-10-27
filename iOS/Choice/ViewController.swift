//
//  ViewController.swift
//  Choice
//
//  Created by Paul Herz on 2017-10-26.
//  Copyright © 2017 Paul Herz. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
	
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
	
	var currentColor: RGB? = nil
	
	let servoOptions = ["A","B","C","D"]
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		answerPicker.delegate = self
		updateCurrentColor(nil, updateDevice: false, updateSliders: true)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func updateCurrentColor(_ color: RGB?, updateDevice: Bool, updateSliders: Bool) {
		self.currentColor = color
		var colorText: String
		var sliderValues: [Float]
		if let color = color {
			colorText = "rgb(\(color[0]),\(color[1]),\(color[2]))"
			
			let uic = color.map { CGFloat($0)/255 }
			ledColorView.backgroundColor = UIColor(
				red: uic[0], green: uic[1], blue: uic[2], alpha: 1.0
			)
			let _ = zip(self.colorLabels,color).map { $0.text = "\($1)" }
			sliderValues = color.map { return Float($0)/255.0 }
		} else {
			colorText = "—"
			ledColorView.backgroundColor = .black
			let _ = self.colorLabels.map { $0.text = "—" }
			sliderValues = [0,0,0]
		}
		ledColorLabel.text = colorText
		if updateSliders {
			let _ = zip(self.colorSliders, sliderValues).map { t in t.0.value = t.1 }
		}
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
		updateCurrentColor(color, updateDevice: true, updateSliders: false)
	}
	
	@IBAction func didChangePotentiometerKnob(_ sender: Knob) {
	}
}

