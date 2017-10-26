//
//  ViewController.swift
//  Choice
//
//  Created by Paul Herz on 2017-10-26.
//  Copyright © 2017 Paul Herz. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
	
	@IBOutlet weak var answerPicker: UIPickerView!
	@IBOutlet weak var servoPositionLabel: UILabel!
	@IBOutlet weak var ledColorView: UIView!
	@IBOutlet weak var ledColorLabel: UILabel!
	
	@IBOutlet weak var redLabel: UILabel!
	@IBOutlet weak var greenLabel: UILabel!
	@IBOutlet weak var blueLabel: UILabel!
	
	@IBOutlet weak var redSlider: UISlider!
	@IBOutlet weak var greenSlider: UISlider!
	@IBOutlet weak var blueSlider: UISlider!
	
	@IBOutlet weak var potentiometerKnob: Knob!
	@IBOutlet weak var potentiometerLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK UIPickerViewDelegate and UIPickerViewDataSource
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		print("WARNING STUB")
		return 0
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		print("WARNING STUB")
		return 0
	}
	
	// MARK event handling
	
	@IBAction func didChangeColorSlider(_ sender: UISlider) {
	}
	
	@IBAction func didChangePotentiometerKnob(_ sender: Knob) {
	}
}

