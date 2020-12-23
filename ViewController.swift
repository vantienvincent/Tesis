//
//  ViewController.swift
//  Recorder
//
//  Created by Hoan Hoang on 2017-03-01.
//  Copyright © 2017 Motsai. All rights reserved.
//

import UIKit
import CoreBluetooth
import QuartzCore
import SceneKit

class ViewController: UIViewController, CBCentralManagerDelegate, UITextFieldDelegate, NeblinaDelegate, UITableViewDataSource {
		let max_count = Int16(15)
	var prevTimeStamp = UInt32(0)
	var cnt = Int16(15)
	var xf = Int16(0)
	var yf = Int16(0)
	var zf = Int16(0)
	var heading = Bool(false)
	//var flashEraseProgress = Bool(false)
	var PaketCnt = UInt32(0)
	var dropCnt = UInt32(0)
	var bleCentralManager : CBCentralManager!
	var objects = [Neblina]()
	var sessionCount = Int16(0)
	var sessions = [SessionInfo]()
	var scanIdx = Int(0)
	let homeDir : String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] + "/"
	var startDownload = Bool(false)
	var sessionLength = UInt32(0)
	var sessionId = UInt16(0)
	var fileLeft : FileHandle?
	var fileRight : FileHandle?
	var packetCnt = Int(0)
	var nextOffset : [UInt32] = [ 0, 0, 0 ]
	var downloadRecovering = Bool(false)
	var path : String?
	
	@IBOutlet weak var sessionView: UITableView!
	@IBOutlet weak var playerTextField : UITextField!
	@IBOutlet weak var leftAccelGraph : GraphView!
	@IBOutlet weak var leftGyroGraph : GraphView!
	@IBOutlet weak var rightAccelGraph : GraphView!
	@IBOutlet weak var rightGyroGraph : GraphView!

	@IBOutlet weak var lefRightSegmented : UISegmentedControl!
	
	@IBOutlet weak var leftStreamDataLabel : UILabel!
	@IBOutlet weak var rightStreamDataLabel : UILabel!

	@IBOutlet weak var leftMessLabel : UILabel!
	@IBOutlet weak var rightMessLabel : UILabel!

	/*
	func getCmdIdx(_ subsysId : Int32, cmdId : Int32) -> Int {
		for (idx, item) in NebCmdList.enumerated() {
			if (item.SubSysId == subsysId && item.CmdId == cmdId) {
				return idx
			}
		}
		
		return -1
	}
*/
	func getViewIdx(dev : Neblina) -> Int {
		for (idx, item) in objects.enumerated() {
			if item == dev {
				return idx
			}
		}
		
		return -1
	}
	
	func getViewIdxPeriph(dev : CBPeripheral) -> Int {
		for (idx, item) in objects.enumerated() {
			if item.device == dev {
				return idx
			}
		}
		
		return -1
	}
	
	func getMessageLabel(sender : Neblina) -> UILabel {
		var label : UILabel?
		if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
			label = display[0].subviews[2] as! UILabel
		}
		else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
			label = display[1].subviews[2] as! UILabel
		}
		else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
			label = display[0].subviews[2] as! UILabel
		}

		return label!
	}

	func getStreamDataLabel(sender : Neblina) -> UILabel {
		var label : UILabel?
		if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
			label = display[0].subviews[1] as! UILabel
		}
		else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
			label = display[1].subviews[1] as! UILabel
		}
		else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
			label = display[0].subviews[1] as! UILabel
		}

		return label!
	}

	func export(sender: AnyObject) {
		//let fileBrowser = FileBrowser()
		//self.presentViewController(fileBrowser, animated: true, completion: nil)
		
		//let fileName = "test.csv"
		//let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
/*
		var csvText = "Make,Model,Nickname\n\(currentCar.make),\(currentCar.model),\(currentCar.nickName)\n\nDate,Mileage,Gallons,Price,Price per gallon,Miles between fillups,MPG\n"
		
		currentCar.fillups.sortInPlace({ $0.date.compare($1.date) == .OrderedDescending })
		
		let count = currentCar.fillups.count
		
		if count > 0 {
			
			for fillup in currentCar.fillups {
				
				let dateFormatter = NSDateFormatter()
				dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
				let convertedDate = dateFormatter.stringFromDate(fillup.date)
				
				let newLine = "\(convertedDate),\(fillup.mileage),\(fillup.gallons),\(fillup.priceTotal),\(fillup.priceGallon),\(fillup.mileDelta),\(fillup.MPG)\n"
				
				csvText.appendContentsOf(newLine)
			}
			*/
/*
			do {
				//try csvText.writeToURL(path, atomically: true, encoding: NSUTF8StringEncoding)
				
				let vc = UIActivityViewController(activityItems: [path], applicationActivities: [])
				vc.excludedActivityTypes = [
					UIActivityType.assignToContact,
					UIActivityType.saveToCameraRoll,
					UIActivityType.postToFlickr,
					UIActivityType.postToVimeo,
					UIActivityType.postToTencentWeibo,
					UIActivityType.postToTwitter,
					UIActivityType.postToFacebook,
					UIActivityType.openInIBooks
				]
				if let popoverPresentationController = vc.popoverPresentationController {
					popoverPresentationController.barButtonItem = nil//(sender as! UIBarButtonItem)
				}
				present(vc, animated: true, completion: nil)
				
			} catch {
				
				print("Failed to create file")
				print("\(error)")
			}
			
		//}
	//else {
		//	showErrorAlert("Error", msg: "There is no data to export")
		//}*/
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		bleCentralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)

		//let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
		//homeDir = paths[0]
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
	{
		textField.resignFirstResponder()
		
/*		for item in objects {
			var tf : UITextField? = nil
			if item.name.range(of: "left", options: NSString.CompareOptions.caseInsensitive) != nil {
				tf = display[0].subviews[2] as! UITextField// == textField {
					
			//	} //as! UILabel
			}
			else if item.name.range(of: "right", options: NSString.CompareOptions.caseInsensitive) != nil {
				tf = display[1].subviews[2] as! UITextField
			}
			if tf == textField {
				
				item.streamShockSegment(true, threshold: UInt8(textField.text!)!)
			}
		}
*/
		return true;
	}

	@IBOutlet var display : [UIView] = []
	
	// MARK : UIButton pressed
	
	@IBAction func leftRightSelected(sender : UISegmentedControl) {
		let label = self.view.subviews[1] as! UILabel
		if sender.selectedSegmentIndex == 0 {
			label.text = "L_"
		}
		else {
			label.text = "R_"
		}
	}
	
	@IBAction func startButPressed(_ sender: UIButton) {
		print("\(playerTextField.text)")
		var name : String!
		
		if lefRightSegmented.selectedSegmentIndex == 0 {
			name = "L_" + playerTextField.text!
		}
		else {
			name = "R_" + playerTextField.text!
		}
		for item in objects {
            item.sessionRecord(true, info: name) // start/stop record
			item.sensorStreamAccelData(true)
            item.sensorStreamTemperatureData(true)
			//item.streamQuaternion(true)
		}
	}
	
	@IBAction func stopButPressed(_ sender: UIButton) {
		for item in objects {
			//item.disableStreaming()
			item.disableStreaming()
			item.sessionRecord(false, info: playerTextField.text!)
		}
	}
	
	@IBAction func refreshPressed(_ sender: UIButton) {
		if objects.count > 0 {
			let neb = objects[0]
			sessions.removeAll()
			neb.getSessionCount()
		}
		//neb.getSessionInfo(0, infoIdx: 0)
	}
	
	@IBAction func playbackPressed(_ sender: UIButton) {
		let idx = sessionView.indexPathForSelectedRow
		
		if idx == nil {
			return
		}
		
		//let idx = sessionView.indexPathsForSelectedRows
		for item in objects {
			item.sessionPlayback(true, sessionId: UInt16(idx!.row))
		}
	}
	
	@IBAction func downloadPressed(_ sender: UIButton) {
		let idx = sessionView.indexPathForSelectedRow
		
		if idx == nil {
			return
		}
		
		let cell = sessionView.cellForRow( at: idx!)
		let nameLabel = cell?.contentView.subviews[2] as! UILabel
		let sessionLebel = cell?.contentView.subviews[1] as! UILabel
		
		//var filePath = homeDir.appending(nameLabel.text!) //+ "/GloveLeft.dat"
		let filePathLeft = homeDir + nameLabel.text! + "_" + sessionLebel.text! + "_MR-B1B-01.dat"
		let filePathRight = homeDir + nameLabel.text! + "_" + sessionLebel.text! + "_MR-B1B-02.dat"

		path = filePathLeft
		
		print("path stuff \(filePathLeft) ")

		if FileManager.default.createFile(atPath: filePathLeft, contents: nil, attributes: nil) == true {
			print("Create File success")
		}
		else {
			print("Can't creat file Left")
		}
		
		if FileManager.default.createFile(atPath: filePathRight, contents: nil, attributes: nil) == true {
			print("Create File success")
		}
		else {
			print("Can't creat file Right")
		}

		fileLeft = FileHandle(forWritingAtPath: filePathLeft)
		fileRight = FileHandle(forWritingAtPath: filePathRight)
        print("\(fileLeft) \(fileRight)")
		print (" \(filePathLeft) \(filePathRight)")
		downloadRecovering = false
		startDownload = true
        
		sessionId = UInt16(sessionLebel.text!)!
        print("session id is \(sessionLebel.text!)")
        print("session is \(sessionId)")
		nextOffset[0] = 0
		nextOffset[1] = 0
		nextOffset[2] = 0
        print("meo den sieu cap")
		for item in objects {
			item.getSessionInfo(sessionId, idx: UInt8(NEBLINA_RECORDER_SESSION_INFO_GENERAL.rawValue))
		}
		print("Download")
	}
	
	@IBAction func eraseButPressed(_ sender: UIButton) {
		let eraseAlert = UIAlertController(title: "Erase all recordings", message: "All data recording will be erased", preferredStyle: UIAlertController.Style.alert)
		eraseAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
			for (idx, item) in self.objects.enumerated() {
				item.eraseStorage(true)
				let label = self.getMessageLabel(sender:item)// self.display[idx].subviews[3] as! UILabel
				label.text = "Erasing..."
				self.sessions.removeAll();
				self.sessionView.reloadData();

			}}))
		eraseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(eraseAlert, animated:true, completion: nil)
	}
	
	@IBAction func resetTimestampButPressed(_ sender: UIButton) {
		for (idx, item) in objects.enumerated() {
			item.resetTimeStamp(Delayed: true)
		}
		for (idx, item) in objects.enumerated() {
			let label = getMessageLabel(sender:item) //display[idx].subviews[3] as! UILabel
			label.text = "Waiting for Tap to reset timestamp"
		}
	}

	// MARK:Tableview
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		return Int(sessions.count)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cellView = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		var label = cellView.subviews[0].subviews[1] as! UILabel
		
		label.text = String(describing:sessions[(indexPath.row)].id)
		label = cellView.subviews[0].subviews[2] as! UILabel
		label.text = sessions[(indexPath.row)].name
		
		return cellView;
	}
	
	func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath?) -> Bool
	{
		return false
	}
	func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
	}

	// MARK: - Bluetooth
	func centralManager(_ central: CBCentralManager,
	                    didDiscover peripheral: CBPeripheral,
	                    advertisementData : [String : Any],
	                    rssi: NSNumber) {
        print("centralManager(_ central: CBCentralManager,--1")
		//print("PERIPHERAL NAME: \(peripheral)\n AdvertisementData: \(advertisementData)\n RSSI: \(RSSI)\n")
		
		//print("UUID DESCRIPTION: \(peripheral.identifier.uuidString)\n")
		
		//print("IDENTIFIER: \(peripheral.identifier)\n")
		print("RSSI = \(rssi.floatValue) \(peripheral.name)")
		//if rssi.decimalValue < -70 || rssi.decimalValue > 0 {
		//	return
		//}
	
		if advertisementData[CBAdvertisementDataLocalNameKey] == nil {
			return
		}
		
		if advertisementData[CBAdvertisementDataManufacturerDataKey] == nil {
			return
		}
		
		let name = peripheral.name! //advertisementData[CBAdvertisementDataLocalNameKey] as! String
		print("\(name)")
		if name.range(of: "MR-B1B-01", options: NSString.CompareOptions.caseInsensitive) == nil &&
			name.range(of: "MR-B1B-02", options: NSString.CompareOptions.caseInsensitive) == nil &&
			name.range(of: "Glove", options: NSString.CompareOptions.caseInsensitive) == nil {
			return
		}
		print("FOUND Device!!!")
		
		var id = UInt64 (0)
		(advertisementData[CBAdvertisementDataManufacturerDataKey] as! NSData).getBytes(&id, range: NSMakeRange(2, 8))
		if (id == 0) {
			return
		}
		print("\(peripheral.name) \(rssi)")
		
		for dev in objects
		{
			if (dev.id == id)
			{
				return;
			}
		}
		
		//let name : String = advertisementData[CBAdvertisementDataLocalNameKey] as! String
        print("There are \(objects.count)")
		if (objects.count > 0)
		{
			for idx in 0..<objects.count {
				if objects[idx].device.name == name {
					return;
				}
			}
		}
		let device = Neblina(devName: name, devid: id, peripheral: peripheral)
		device.delegate = self
		central.connect(device.device, options: nil)
		objects.insert(device, at: 0)
        print("finish connecting")
		if objects.count >= 2 {
			central.stopScan()
			//for idx in 0..<objects.count {
			//	objects[idx].delegate = self
			//	central.connect(objects[idx].device, options: nil)
				//let control = display[idx].subviews[0] as! UILabel// viewWithTag(1) as! UILabel
				//let control = display[0].viewWithTag(1) as! UILabel
				//if control != nil {
				//	control.text = objects[idx].device.name
				//}
			//}
		}
		
	}
	
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)")
		if objects.count >= 3 {
			central.stopScan()
		}
        print("dicovery service")
		peripheral.discoverServices(nil)
	}
	
	func centralManager(_ central: CBCentralManager,
	                    didDisconnectPeripheral peripheral: CBPeripheral,
	                    error: Error?) {
		
		print("disconnected from peripheral")
		var label:UILabel!
		var view : UIView!
		if peripheral.name?.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
			view = display[0]
		//	label = display[0].subviews[3] as! UILabel
		}
		else if peripheral.name?.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
			view = display[1]
		//	label = display[1].subviews[3] as! UILabel
		}
		else if peripheral.name?.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
			view = display[0]
		//	label = display[1].subviews[3] as! UILabel
		}
//			let idx = getViewIdxPeriph(dev: peripheral)
//		if (idx >= 0) && idx < 2 {
//			let label = display[idx].subviews[2] as! UILabel
//			label.text = "Device disconnected"
//		}
		for (idx, item) in objects.enumerated() {
			if item.device == peripheral {
				objects.remove(at: idx)
			}
		}

		label = view.subviews[2] as! UILabel
		label.text = "Device disconnected"
		label = view.subviews[0] as! UILabel
		label.text = " "
		label = view.subviews[3] as! UILabel
		label.text = " "
		label = view.subviews[4] as! UILabel
		label.text = " "
		
		bleCentralManager.scanForPeripherals(withServices: [NEB_SERVICE_UUID], options: nil)//[CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true)])
	}
	
	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		print("Failled to connect \(error)")
	}
	/*
	func scanPeripheral(_ sender: CBCentralManager)
	{
		print("Scan for peripherals")
		bleCentralManager.scanForPeripherals(withServices: nil, options: nil)
	}
	*/
	@objc func centralManagerDidUpdateState(_ central: CBCentralManager) {
		
		switch central.state {
			
		case .poweredOff:
			print("CoreBluetooth BLE hardware is powered off")
			//self.sensorData.text = "CoreBluetooth BLE hardware is powered off\n"
			break
		case .poweredOn:
			print("CoreBluetooth BLE hardware is powered on and ready")
			//self.sensorData.text = "CoreBluetooth BLE hardware is powered on and ready\n"
			// We can now call scanForBeacons
			let lastPeripherals = central.retrieveConnectedPeripherals(withServices: [NEB_SERVICE_UUID])
			
			if lastPeripherals.count > 0 {
				// let device = lastPeripherals.last as CBPeripheral;
				//connectingPeripheral = device;
				//centralManager.connectPeripheral(connectingPeripheral, options: nil)
			}
			//scanPeripheral(central)
            print("scanning line 533")
			bleCentralManager.scanForPeripherals(withServices: [NEB_SERVICE_UUID], options: nil)//[CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true)])//, options: CBCentralManagerScanOptionAllowDuplicatesKey)
			break
		case .resetting:
			print("CoreBluetooth BLE hardware is resetting")
			//self.sensorData.text = "CoreBluetooth BLE hardware is resetting\n"
			break
		case .unauthorized:
			print("CoreBluetooth BLE state is unauthorized")
			//self.sensorData.text = "CoreBluetooth BLE state is unauthorized\n"
			
			break
		case .unknown:
			print("CoreBluetooth BLE state is unknown")
			//self.sensorData.text = "CoreBluetooth BLE state is unknown\n"
			break
		case .unsupported:
			print("CoreBluetooth BLE hardware is unsupported on this platform")
			//self.sensorData.text = "CoreBluetooth BLE hardware is unsupported on this platform\n"
			break
			
		default:
			break
		}
	}
	
	// MARK : Neblina
	
	func didConnectNeblina(sender : Neblina) {
		let idx = getViewIdx(dev: sender)
		var label : UILabel? = nil

		let utime = Date().timeIntervalSince1970
		
		// Close UART
		sender.setDataPort(1, Ctrl: 0)
		// Open BLE
		sender.setDataPort(0, Ctrl: 1)
		
		sender.setUnixTime(uTime: UInt32(utime))

		if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
			// Found left
			label = display[0].subviews[0] as? UILabel
			//sender.getSessionCount();
		}
		else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
			label = display[1].subviews[0] as? UILabel
		}
		else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
			label = display[0].subviews[0] as? UILabel
		}
		if label != nil {
			label?.text = objects[idx].device.name! + String(format: "_%lX", objects[idx].id)
		}
		prevTimeStamp = 0;
		
		if idx == 0 {
            sender.getSessionCount(); // get all the session
		}
		
		//sender.getSystemStatus()
		sender.getFirmwareVersion()

		print("didConnectNeblina \(utime) \(UInt32(utime))")
		
	}
	
	func didReceiveBatteryLevel(sender : Neblina, level : UInt8) {
		var label : UILabel? = nil
		
		if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
			// Found left
			label = display[0].subviews[4] as? UILabel
		}
		else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
			label = display[1].subviews[4] as? UILabel
		}
		else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
			label = display[0].subviews[4] as? UILabel
		}
		if label != nil {
			label?.text = String(format: "Bat: %u%%", level)
		}
	}

	func didReceiveResponsePacket(sender: Neblina, subsystem: Int32, cmdRspId: Int32, data: UnsafePointer<UInt8>, dataLen: Int) {
		switch (subsystem) {
		case NEBLINA_SUBSYSTEM_GENERAL:
            print("NEBLINA_SUBSYSTEM_GENERAL")
			switch (cmdRspId) {
			case NEBLINA_COMMAND_GENERAL_FIRMWARE_VERSION:
				let vers = UnsafeMutableRawPointer(mutating: data).load(as: NeblinaFirmwareVersion_t.self)
				var label:UILabel!
				
				if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
					// Found left
					label = display[0].subviews[3] as! UILabel
					
				}
				else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
					label = display[1].subviews[3] as! UILabel
					
				}
				else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
					label = display[0].subviews[3] as! UILabel
					
				}
	/*
				let idx = getViewIdx(dev: sender)
				if idx >= 0 {
					let label = display[idx].subviews[4] as! UILabel
				
					label.text = String(format: "API:%d, FEN:%d.%d.%d", vers.apiVersion,
										vers.coreVersion.major, vers.coreVersion.minor, vers.coreVersion.build)
				}*/
				let b = (UInt32(vers.firmware_build.0) & 0xFF) | ((UInt32(vers.firmware_build.1) & 0xFF) << 8) | ((UInt32(vers.firmware_build.2) & 0xFF) << 16)

				label.text = String(format: "Ver:%d.%d.%d-%d",
									vers.firmware_major, vers.firmware_minor, vers.firmware_patch, b
				)
				break
			case NEBLINA_COMMAND_GENERAL_RESET_TIMESTAMP:
				let label = getMessageLabel(sender: sender)
//				let idx = getViewIdx(dev: sender)
				if label != nil {
					//let label = display[idx].subviews[3] as! UILabel
					
					label.text = "Timestamp reset"
				}
				break
			default:
				break
			}
			break
		case NEBLINA_SUBSYSTEM_RECORDER:
            print("NEBLINA_SUBSYSTEM_RECORDER")
			switch (cmdRspId) {
			case NEBLINA_COMMAND_RECORDER_RECORD:
				let session = Int16(data[1]) | (Int16(data[2]) << 8)
				let label = getMessageLabel(sender: sender)
				if (data[0] != 0) {
					label.text = String(format: "Recording session %d", session)
				}
				else {
					label.text = String(format: "Recorded session %d", session)
					if getViewIdx(dev: sender) == 0 {
					//let neb = objects[0]
						sessions.removeAll()
					
						sender.getSessionCount();
					}
				}
				print("NEBLINA_COMMAND_RECORDER_RECORD \(data[0]) \(data[1])")
				break
			case NEBLINA_COMMAND_RECORDER_SESSION_COUNT:
				print("NEBLINA_COMMAND_RECORDER_SESSION_COUNT \(data[0]) \(data[1]) \(dataLen)")
				sessionCount = Int16(data[0]) | (Int16(data[1]) << 8)
				if sessionCount > 0 {
					sender.getSessionName(UInt16(sessionCount - 1))
				}
				else
				{
					sessionView.reloadData();
				}
				break
				
			case NEBLINA_COMMAND_RECORDER_SESSION_GENERAL_INFO:
				sessionLength = (UInt32(data[0]) & 0xFF) | ((UInt32(data[1]) & 0xFF) << 8) |
								((UInt32(data[2]) & 0xFF) << 16) | ((UInt32(data[3]) & 0xFF) << 24)
				if startDownload == true {
					sender.sessionDownload(true, SessionId: sessionId, Len: UInt16(sessionLength & 0xFFFF), Offset: 0)
				}
				print("NEBLINA_COMMAND_RECORDER_SESSION_GENERAL_INFO \(sessionLength)")
				break
				
			case NEBLINA_COMMAND_RECORDER_SESSION_NAME:
				
				print("\(data[0]) \(data[1]) \(data[2])")
				//let name = String(data : UnsafeBufferPointer(start: data + 1, count: dataLen - 1), encoding: .utf8)
				if dataLen > 0 {
					let xx = Data(bytes:data, count: dataLen)
					let str = String(data: xx, encoding: String.Encoding.utf8)
					let idx = getViewIdx(dev : sender)
					print("NEBLINA_COMMAND_RECORDER_SESSION_NAME : \(xx) \(str) \(idx)")
					if str != nil {
						sessionCount -= 1
						let info = SessionInfo(id: Int(sessionCount), name: str!)
						if info.id >= 0 && getViewIdx(dev : sender) == 0 {
							sessions.insert(info, at: 0)
							sessionView.reloadData();
							if sessionCount > 0 {
								sender.getSessionName(UInt16(sessionCount - 1))
							}
						}
					}
					else{
						let label = getMessageLabel(sender: sender)
						label.text = "Bad flash"
					}
				}
				break
			case NEBLINA_COMMAND_RECORDER_ERASE_ALL:
				//let idx = getViewIdx(dev: sender)
				//if idx >= 0 {
				//	let label = display[idx].subviews[2] as! UILabel
				//	label.text = "Flash erased"
				//}
				let label = getMessageLabel(sender: sender)
				label.text = "Flash erased"
				print("Flash erased")
				break
			case NEBLINA_COMMAND_RECORDER_SESSION_DOWNLOAD:
				let id = (UInt16(data[0]) & 0xFF) | ((UInt16(data[1]) & 0xFF) << 8)
				let label = getMessageLabel(sender: sender)
				
				if data[0] == 0 {
					var file : FileHandle?
					if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
						// Found left
						file = fileLeft
						//let label = display[0].subviews[3] as! UILabel
						//label.text = "Download Complete"
					}
					else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
						file = fileRight
						//let label = display[1].subviews[3] as! UILabel
						//label.text = "Download Complete"
					}
					else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
						file = fileLeft
						//let label = display[1].subviews[3] as! UILabel
						//label.text = "Download Complete"
					}
					file?.closeFile()
					label.text = "Download Complete"
					downloadRecovering = false
					startDownload = false
					export(sender: sender)
				}
				print("NEBLINA_COMMAND_RECORDER_SESSION_DOWNLOAD ID : \(data[0]) \(data[1])")
				break
			default:
				break
			}
		default:
			break
		}
	}
	
	func didReceiveRSSI(sender : Neblina, rssi : NSNumber) {
		
	}
	
	//
	// General data
	//
	func didReceiveGeneralData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : UnsafeRawPointer, dataLen : Int, errFlag : Bool) {
		switch (cmdRspId) {
		case NEBLINA_COMMAND_GENERAL_SYSTEM_STATUS:
			var myStruct = NeblinaSystemStatus_t()
			let status = withUnsafeMutablePointer(to: &myStruct) {_ in UnsafeMutableRawPointer(mutating: data)}
			print("Status \(status)")
			let d = data.load(as: NeblinaSystemStatus_t.self)// UnsafeBufferPointer<NeblinaSystemStatus_t>(data)
			print(" \(d)")
//			updateUI(status: d)
			break
			
			break
		default:
			break
		}
	}
	
	func didReceiveFusionData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : NeblinaFusionPacket_t, errFlag : Bool) {
		
		//let errflag = Bool(type.rawValue & 0x80 == 0x80)
		
		//let id = FusionId(rawValue: type.rawValue & 0x7F)! as FusionId
//		dumpLabel.text = String(format: "Total packet %u @ %0.2f pps", nebdev!.getPacketCount(), nebdev!.getDataRate())
		
		switch (cmdRspId) {
			
		case NEBLINA_COMMAND_FUSION_MOTION_STATE_STREAM:
			break
		case NEBLINA_COMMAND_FUSION_EULER_ANGLE_STREAM:
			break
		case NEBLINA_COMMAND_FUSION_QUATERNION_STREAM:
			
			//
			// Process Quaternion
			//
			//let ship = scene.rootNode.childNodeWithName("ship", recursively: true)!
			let x = (Int16(data.data.0) & 0xff) | (Int16(data.data.1) << 8)
			let xq = Float(x) / 32768.0
			let y = (Int16(data.data.2) & 0xff) | (Int16(data.data.3) << 8)
			let yq = Float(y) / 32768.0
			let z = (Int16(data.data.4) & 0xff) | (Int16(data.data.5) << 8)
			let zq = Float(z) / 32768.0
			let w = (Int16(data.data.6) & 0xff) | (Int16(data.data.7) << 8)
			let wq = Float(w) / 32768.0
			let idx = getViewIdx(dev: sender)
			if idx >= 0 {
				let label = getStreamDataLabel(sender: sender)//display[idx].subviews[3] as! UILabel
				label.text = String(format : "Quat - x:%.2f, y:%.2f, z:%.2f, w:%.2f", xq, yq, zq, wq)
			}
			if (prevTimeStamp == 0 || data.timestamp <= prevTimeStamp)
			{
				prevTimeStamp = data.timestamp;
			}
			else
			{
				let tdiff = data.timestamp - prevTimeStamp;
				if (tdiff > 49000)
				{
					dropCnt += 1
//					dumpLabel.text = String("\(dropCnt) Drop : \(tdiff)")
				}
				prevTimeStamp = data.timestamp
			}
			
			break
		case NEBLINA_COMMAND_FUSION_EXTERNAL_FORCE_STREAM:
			break
		case NEBLINA_COMMAND_FUSION_SHOCK_SEGMENT_STREAM:
			let ax = (Int16(data.data.0) & 0xff) | (Int16(data.data.1) << 8)
			let ay = (Int16(data.data.2) & 0xff) | (Int16(data.data.3) << 8)
			let az = (Int16(data.data.4) & 0xff) | (Int16(data.data.5) << 8)
			//			label.text = String("Accel - x:\(xq), y:\(yq), z:\(zq)")
			
			
			let gx = (Int16(data.data.6) & 0xff) | (Int16(data.data.7) << 8)
			let gy = (Int16(data.data.8) & 0xff) | (Int16(data.data.9) << 8)
			let gz = (Int16(data.data.10) & 0xff) | (Int16(data.data.11) << 8)
			
			if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
				leftAccelGraph.add(double3(Double(ax), Double(ay), Double(az)))
				leftGyroGraph.add(double3(Double(gx), Double(gy), Double(gz)))
				let label = getStreamDataLabel(sender: sender)//display[0].subviews[3] as! UILabel
				label.text = String(format : "ax:%d, ay:%d, az:%d", ax, ay, az)
			}
			else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
				rightAccelGraph.add(double3(Double(ax), Double(ay), Double(az)))
				rightGyroGraph.add(double3(Double(gx), Double(gy), Double(gz)))
				let label = getStreamDataLabel(sender: sender)//display[1].subviews[3] as! UILabel
				label.text = String(format : "ax:%d, ay:%d, az:%d", ax, ay, az)
			}
			else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
				leftAccelGraph.add(double3(Double(ax), Double(ay), Double(az)))
				leftGyroGraph.add(double3(Double(gx), Double(gy), Double(gz)))
				let label = getStreamDataLabel(sender: sender)//display[1].subviews[3] as! UILabel
				label.text = String(format : "ax:%d, ay:%d, az:%d", ax, ay, az)
			}
			break
		default:
			break
		}
		
		
	}
	
	func didReceivePmgntData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : UnsafePointer<UInt8>, dataLen: Int, errFlag : Bool) {
		let value = UInt16(data[0]) | (UInt16(data[1]) << 8)
		if (cmdRspId == NEBLINA_COMMAND_POWER_CHARGE_CURRENT)
		{
//			let i = getCmdIdx(NEBLINA_SUBSYSTEM_POWER,  cmdId: NEBLINA_COMMAND_POWER_CHARGE_CURRENT)
//			let cell = cmdView.cellForRow( at: IndexPath(row: i, section: 0))
//			if (cell != nil) {
//				let control = cell!.viewWithTag(3) as! UITextField
//				control.text = String(value)
//			}
		}
	}
	
	func didReceiveLedData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : UnsafePointer<UInt8>, dataLen: Int, errFlag : Bool) {
		switch (cmdRspId) {
		case NEBLINA_COMMAND_LED_STATUS:
			break
		default:
			break
		}
	}
	
	//
	// Debug
	//
	func didReceiveDebugData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : UnsafePointer<UInt8>, dataLen : Int, errFlag : Bool)
	{
		//print("Debug \(type) data \(data)")
		switch (cmdRspId) {
		case NEBLINA_COMMAND_DEBUG_DUMP_DATA:
//			dumpLabel.text = String(format: "%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x",
//			                        data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9],
//			                        data[10], data[11], data[12], data[13], data[14], data[15])
			break
		default:
			break
		}
	}
	
	func didReceiveRecorderData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : UnsafePointer<UInt8>, dataLen: Int, errFlag : Bool) {
		switch (cmdRspId) {
		case NEBLINA_COMMAND_RECORDER_SESSION_DOWNLOAD:
			let offset = (UInt32(data[0]) & 0xFF) | ((UInt32(data[1]) & 0xFF) << 8) |
				((UInt32(data[2]) & 0xFF) << 16) | ((UInt32(data[2]) & 0xFF) << 32)

			var file : FileHandle?
			let label = getMessageLabel(sender: sender)
			var loIdx = Int(0)
			
			if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
				// Found left
				file = fileLeft
				loIdx = 0
			}
			else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
				file = fileRight
				loIdx = 1
			}
			else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
				file = fileLeft
				loIdx = 0
			}

			label.text = String(format: "Dwnld : %d, offset : %d", sessionId, offset)
			
			if offset != (nextOffset[loIdx]) {
				if downloadRecovering == false {
					print("Download DROPPED \(offset) \(nextOffset[loIdx])")
					sender.sessionDownload(true, SessionId: sessionId, Len: 0, Offset: nextOffset[loIdx])
					downloadRecovering = true
				}
			}
			else {
				nextOffset[loIdx] = offset + UInt32(dataLen) - 4
				let d = Data(buffer: UnsafeBufferPointer<UInt8>(start: data + 4, count: dataLen - 4))
//                print(len(d))
				file?.write(d)
				downloadRecovering = false
//                print("\(data)")
			}
			//print("Data packet NEBLINA_COMMAND_RECORDER_SESSION_DOWNLOAD \(offset) \(file)")
			break
		default:
			break
		}
	}
	
	func didReceiveEepromData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : UnsafePointer<UInt8>, dataLen: Int, errFlag : Bool) {
		switch (cmdRspId) {
		case NEBLINA_COMMAND_EEPROM_READ:
			let pageno = UInt16(data[0]) | (UInt16(data[1]) << 8)
//			dumpLabel.text = String(format: "EEP page [%d] : %02x %02x %02x %02x %02x %02x %02x %02x",
//			                        pageno, data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9])
			break
		case NEBLINA_COMMAND_EEPROM_WRITE:
			break;
		default:
			break
		}
	}
	
	//
	// Sensor data
	//
	func didReceiveSensorData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : UnsafePointer<UInt8>, dataLen : Int, errFlag : Bool) {
		switch (cmdRspId) {
		case NEBLINA_COMMAND_SENSOR_ACCELEROMETER_STREAM:
			let x = (Int16(data[4]) & 0xff) | (Int16(data[5]) << 8)
			let xq = x
			let y = (Int16(data[6]) & 0xff) | (Int16(data[7]) << 8)
			let yq = y
			let z = (Int16(data[8]) & 0xff) | (Int16(data[9]) << 8)
			let zq = z
			let idx = getViewIdx(dev: sender)
			if idx >= 0 {
				let label = getStreamDataLabel(sender: sender)//display[idx].subviews[1] as! UILabel
				label.text = String("Accel - x:\(xq), y:\(yq), z:\(zq)")
				if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
					leftAccelGraph.add(double3(Double(xq), Double(yq), Double(zq)))
				}
				if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
					rightAccelGraph.add(double3(Double(xq), Double(yq), Double(zq)))
				}
				if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
					leftAccelGraph.add(double3(Double(xq), Double(yq), Double(zq)))
				}
			}
			//			rxCount += 1
			break
		case NEBLINA_COMMAND_SENSOR_GYROSCOPE_STREAM:
			let x = (Int16(data[4]) & 0xff) | (Int16(data[5]) << 8)
			let xq = x
			let y = (Int16(data[6]) & 0xff) | (Int16(data[7]) << 8)
			let yq = y
			let z = (Int16(data[8]) & 0xff) | (Int16(data[9]) << 8)
			let zq = z
			let idx = getViewIdx(dev: sender)
			if idx >= 0 {
				let label = getStreamDataLabel(sender: sender)//display[idx].subviews[1] as! UILabel
				label.text = String("Gyro - x:\(xq), y:\(yq), z:\(zq)")
				if idx == 0 {
					leftGyroGraph.add(double3(Double(xq), Double(yq), Double(zq)))
				}
			}
			//rxCount += 1
			break
		case NEBLINA_COMMAND_SENSOR_HUMIDITY_STREAM:
			break
		case NEBLINA_COMMAND_SENSOR_MAGNETOMETER_STREAM:
			//
			// Mag data
			//
			//let ship = scene.rootNode.childNodeWithName("ship", recursively: true)!
			let x = (Int16(data[4]) & 0xff) | (Int16(data[5]) << 8)
			let xq = x
			let y = (Int16(data[6]) & 0xff) | (Int16(data[7]) << 8)
			let yq = y
			let z = (Int16(data[8]) & 0xff) | (Int16(data[9]) << 8)
			let zq = z
			let idx = getViewIdx(dev: sender)
			if idx >= 0 {
				let label = getStreamDataLabel(sender: sender)//display[idx].subviews[1] as! UILabel
				label.text = String("Mag - x:\(xq), y:\(yq), z:\(zq)")
			}
			//rxCount += 1
			//ship.rotation = SCNVector4(Float(xq), Float(yq), 0, GLKMathDegreesToRadians(90))
			break
		case NEBLINA_COMMAND_SENSOR_PRESSURE_STREAM:
			break
		case NEBLINA_COMMAND_SENSOR_TEMPERATURE_STREAM:
			break
		case NEBLINA_COMMAND_SENSOR_ACCELEROMETER_GYROSCOPE_STREAM:
			let x = (Int16(data[4]) & 0xff) | (Int16(data[5]) << 8)
			let y = (Int16(data[6]) & 0xff) | (Int16(data[7]) << 8)
			let z = (Int16(data[8]) & 0xff) | (Int16(data[9]) << 8)

			let gx = (Int16(data[10]) & 0xff) | (Int16(data[11]) << 8)
			let gy = (Int16(data[12]) & 0xff) | (Int16(data[13]) << 8)
			let gz = (Int16(data[14]) & 0xff) | (Int16(data[15]) << 8)
/*
			let x = (Int16(data[4]) & 0xff) | (Int16(data[5]) << 8)
			let xq = x
			let y = (Int16(data[6]) & 0xff) | (Int16(data[7]) << 8)
			let yq = y
			let z = (Int16(data[8]) & 0xff) | (Int16(data[9]) << 8)
			let zq = z*/
			let idx = getViewIdx(dev: sender)
			if idx >= 0 {
				let label = getStreamDataLabel(sender: sender)//display[idx].subviews[1] as! UILabel
				label.text = String("IMU - x:\(x), y:\(y), z:\(z)")
				switch (idx) {
					case 0:
						leftAccelGraph.add(double3(Double(x), Double(y), Double(z)))
						leftGyroGraph.add(double3(Double(gx), Double(gy), Double(gz)))
						break
					case 1:
						rightAccelGraph.add(double3(Double(x), Double(y), Double(z)))
						rightGyroGraph.add(double3(Double(gx), Double(gy), Double(gz)))
						break
					default:
						break
				}
			}
			//rxCount += 1
			break
		case NEBLINA_COMMAND_SENSOR_ACCELEROMETER_MAGNETOMETER_STREAM:
			break
		default:
			break
		}
//		cmdView.setNeedsDisplay()
	}
	
	
}


