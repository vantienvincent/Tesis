//
//  IPhoneViewController.swift
//  B1BRecorder
//
//  Created by Van on 3/13/20.
//  Copyright © 2020 Hoan Hoang. All rights reserved.
//

import UIKit
import Charts
import CoreBluetooth
import CoreML
import SwiftCSV

class IPhoneViewController: UIViewController,NeblinaDelegate,CBCentralManagerDelegate, ChartViewDelegate {
    
    
    // MARK: variableg
    let homeDir : String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] + "/"
    var startDownload = Bool(false)
    var downloadRecovering = Bool(false)
    var path : String?
    @IBOutlet weak var lableprogress: UILabel!
    var fileLeft : FileHandle?
    var fileRight : FileHandle?
    var nextOffset : [UInt32] = [ 0, 0, 0 ]
    var sessionId = UInt16(0)
    var isErasedAllSession = false
    var download_progress : String?
    var device_name : String = "Default_name"
    // MARK : Neblina
    var sessions = [SessionInfo]()
    func didConnectNeblina(sender : Neblina) {
        print("didConnectNeblina")
//        let idx = getViewIdx(dev: sender)
        var label : UILabel? = nil
        
        let utime = Date().timeIntervalSince1970
        
        // Close UART
        sender.setDataPort(1, Ctrl: 0)
        // Open BLE
        sender.setDataPort(0, Ctrl: 1)
        
        sender.setUnixTime(uTime: UInt32(utime))
        
        if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
            // Found left
//            label = display[0].subviews[0] as? UILabel
            //sender.getSessionCount();
        }
        else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
//            label = display[1].subviews[0] as? UILabel
        }
        else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
//            label = display[0].subviews[0] as? UILabel
        }
        if label != nil {
//            label?.text = objects[idx].device.name! + String(format: "_%lX", objects[idx].id)
        }
//        prevTimeStamp = 0;
        
//        if idx == 0 {
//            sender.getSessionCount(); // get all the session
//        }
        
        //sender.getSystemStatus()
        sender.getFirmwareVersion()
        
        print("didConnectNeblina \(utime) \(UInt32(utime))")
        
    }
    var sessionCount = Int16(0)
    func didReceiveBatteryLevel(sender : Neblina, level : UInt8) {
        print("didReceiveBatteryLevel")
        var label : UILabel? = nil
        
        if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
            // Found left
//            label = display[0].subviews[4] as? UILabel
        }
        else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
//            label = display[1].subviews[4] as? UILabel
        }
        else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
//            label = display[0].subviews[4] as? UILabel
        }
        if label != nil {
//            label?.text = String(format: "Bat: %u%%", level)
        }
    }
    func getViewIdx(dev : Neblina) -> Int {
        for (idx, item) in objects.enumerated() {
            if item == dev {
                return idx
            }
        }
        
        return -1
    }
    func didReceiveResponsePacket(sender: Neblina, subsystem: Int32, cmdRspId: Int32, data: UnsafePointer<UInt8>, dataLen: Int) {
        print("enter didReceiveResponsePacket")
        switch (subsystem) {
        case NEBLINA_SUBSYSTEM_GENERAL:
            print("NEBLINA_SUBSYSTEM_GENERAL")
            switch (cmdRspId) {
            case NEBLINA_COMMAND_GENERAL_FIRMWARE_VERSION:
                let vers = UnsafeMutableRawPointer(mutating: data).load(as: NeblinaFirmwareVersion_t.self)
                var label:UILabel!
                
                if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
                    // Found left
//                    label = display[0].subviews[3] as! UILabel
                    
                }
                else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
//                    label = display[1].subviews[3] as! UILabel
                    
                }
                else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
//                    label = display[0].subviews[3] as! UILabel
                    
                }
                
                let b = (UInt32(vers.firmware_build.0) & 0xFF) | ((UInt32(vers.firmware_build.1) & 0xFF) << 8) | ((UInt32(vers.firmware_build.2) & 0xFF) << 16)
                
//                label.text = String(format: "Ver:%d.%d.%d-%d",
//                                    vers.firmware_major, vers.firmware_minor, vers.firmware_patch, b
//                )
                break
            case NEBLINA_COMMAND_GENERAL_RESET_TIMESTAMP:
                let label = UILabel()
                //                let idx = getViewIdx(dev: sender)
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
                let label = UILabel()//getMessageLabel(sender: sender)
                if (data[0] != 0) {
                    label.text = String(format: "Recording session %d", session)
                }
                else {
                    label.text = String(format: "Recorded session %d", session)
//                    if getViewIdx(dev: sender) == 0 {
//                        //let neb = objects[0]
//                        sessions.removeAll()
//
//                        sender.getSessionCount();
//                    }
                }
                print("NEBLINA_COMMAND_RECORDER_RECORD \(data[0]) \(data[1])")
                break
            case NEBLINA_COMMAND_RECORDER_SESSION_COUNT:
                print("NEBLINA_COMMAND_RECORDER_SESSION_COUNT \(data[0]) \(data[1]) \(dataLen)")
                sessionCount = Int16(data[0]) | (Int16(data[1]) << 8)
                if sessionCount > 0 {
                    sender.getSessionName(UInt16(sessionCount - 1))
                }
//                else
//                {
//                    sessionView.reloadData();
//                }
                break
                
            case NEBLINA_COMMAND_RECORDER_SESSION_GENERAL_INFO:
                var sessionLength = UInt32(0)
                sessionLength = (UInt32(data[0]) & 0xFF) | ((UInt32(data[1]) & 0xFF) << 8) |
                    ((UInt32(data[2]) & 0xFF) << 16) | ((UInt32(data[3]) & 0xFF) << 24)
                if startDownload == true {
                    sender.sessionDownload(true, SessionId: sessionId, Len: UInt16(sessionLength & 0xFFFF), Offset: 0)
                }
                print("NEBLINA_COMMAND_RECORDER_SESSION_GENERAL_INFO \(sessionLength)")
                break
                
            case NEBLINA_COMMAND_RECORDER_SESSION_NAME:
                var sessionCount = Int16(0)
                print("\(data[0]) \(data[1]) \(data[2])")
                //let name = String(data : UnsafeBufferPointer(start: data + 1, count: dataLen - 1), encoding: .utf8)
                if dataLen > 0 {
                    let xx = Data(bytes:data, count: dataLen)
                    let str = String(data: xx, encoding: String.Encoding.utf8)
//                    let idx = getViewIdx(dev : sender)
//                    print("NEBLINA_COMMAND_RECORDER_SESSION_NAME : \(xx) \(str) \(idx)")
                    if str != nil {
                        sessionCount -= 1
                        let info = SessionInfo(id: Int(sessionCount), name: str!)
                        if info.id >= 0 && getViewIdx(dev : sender) == 0 {
                            sessions.insert(info, at: 0)
//                            sessionView.reloadData();
                            if sessionCount > 0 {
                                sender.getSessionName(UInt16(sessionCount - 1))
                            }
                        }
                    }
                    else{
                        let label = UILabel()//getMessageLabel(sender: sender)
                        label.text = "Bad flash"
                    }
                }
                break
            case NEBLINA_COMMAND_RECORDER_ERASE_ALL:
                //let idx = getViewIdx(dev: sender)
                //if idx >= 0 {
                //    let label = display[idx].subviews[2] as! UILabel
                //    label.text = "Flash erased"
                //}
                let label = UILabel()//getMessageLabel(sender: sender)
                label.text = "Flash erased"
                print("Flash erased")
                break
            case NEBLINA_COMMAND_RECORDER_SESSION_DOWNLOAD:
                let id = (UInt16(data[0]) & 0xFF) | ((UInt16(data[1]) & 0xFF) << 8)
                let label = UILabel()//getMessageLabel(sender: sender)

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
//                        file = fileLeft
                        //let label = display[1].subviews[3] as! UILabel
                        //label.text = "Download Complete"
                    }
                    file?.closeFile()
                    label.text = "Download Complete"
                    downloadRecovering = false
                    startDownload = false
//                    export(sender: sender)
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
    
    func didReceiveRSSI(sender: Neblina, rssi: NSNumber) {
        
    }
    
    func didReceiveGeneralData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : UnsafeRawPointer, dataLen : Int, errFlag : Bool) {
        switch (cmdRspId) {
        case NEBLINA_COMMAND_GENERAL_SYSTEM_STATUS:
            var myStruct = NeblinaSystemStatus_t()
            let status = withUnsafeMutablePointer(to: &myStruct) {_ in UnsafeMutableRawPointer(mutating: data)}
            print("Status \(status)")
            let d = data.load(as: NeblinaSystemStatus_t.self)// UnsafeBufferPointer<NeblinaSystemStatus_t>(data)
            print(" \(d)")
            //            updateUI(status: d)
            break
            
            break
        default:
            break
        }
    }
    
    func didReceiveFusionData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : NeblinaFusionPacket_t, errFlag : Bool) {
        
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
//            let idx = getViewIdx(dev: sender)
            var idx = -1
            if idx >= 0 {
//                let label = getStreamDataLabel(sender: sender)//display[idx].subviews[3] as! UILabel
//                label.text = String(format : "Quat - x:%.2f, y:%.2f, z:%.2f, w:%.2f", xq, yq, zq, wq)
//            }
//            if (prevTimeStamp == 0 || data.timestamp <= prevTimeStamp)
//            {
//                prevTimeStamp = data.timestamp;
            }
            else
            {
//                let tdiff = data.timestamp - prevTimeStamp;
//                if (tdiff > 49000)
//                {
//                    dropCnt += 1
//                    //                    dumpLabel.text = String("\(dropCnt) Drop : \(tdiff)")
//                }
//                prevTimeStamp = data.timestamp
            }
            
            break
        case NEBLINA_COMMAND_FUSION_EXTERNAL_FORCE_STREAM:
            break
        case NEBLINA_COMMAND_FUSION_SHOCK_SEGMENT_STREAM:
            let ax = (Int16(data.data.0) & 0xff) | (Int16(data.data.1) << 8)
            let ay = (Int16(data.data.2) & 0xff) | (Int16(data.data.3) << 8)
            let az = (Int16(data.data.4) & 0xff) | (Int16(data.data.5) << 8)
            //            label.text = String("Accel - x:\(xq), y:\(yq), z:\(zq)")
            
            
            let gx = (Int16(data.data.6) & 0xff) | (Int16(data.data.7) << 8)
            let gy = (Int16(data.data.8) & 0xff) | (Int16(data.data.9) << 8)
            let gz = (Int16(data.data.10) & 0xff) | (Int16(data.data.11) << 8)
            
            if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
//                leftAccelGraph.add(double3(Double(ax), Double(ay), Double(az)))
//                leftGyroGraph.add(double3(Double(gx), Double(gy), Double(gz)))
//                let label = getStreamDataLabel(sender: sender)//display[0].subviews[3] as! UILabel
//                label.text = String(format : "ax:%d, ay:%d, az:%d", ax, ay, az)
            }
            else if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
//                rightAccelGraph.add(double3(Double(ax), Double(ay), Double(az)))
//                rightGyroGraph.add(double3(Double(gx), Double(gy), Double(gz)))
//                let label = getStreamDataLabel(sender: sender)//display[1].subviews[3] as! UILabel
//                label.text = String(format : "ax:%d, ay:%d, az:%d", ax, ay, az)
            }
            else if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
//                leftAccelGraph.add(double3(Double(ax), Double(ay), Double(az)))
//                leftGyroGraph.add(double3(Double(gx), Double(gy), Double(gz)))
//                let label = getStreamDataLabel(sender: sender)//display[1].subviews[3] as! UILabel
//                label.text = String(format : "ax:%d, ay:%d, az:%d", ax, ay, az)
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
    
    func didReceiveDebugData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : UnsafePointer<UInt8>, dataLen : Int, errFlag : Bool)
    {
        //print("Debug \(type) data \(data)")
        switch (cmdRspId) {
        case NEBLINA_COMMAND_DEBUG_DUMP_DATA:
            var txt = String(format: "%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x",
                                                data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9],
                                                data[10], data[11], data[12], data[13], data[14], data[15])
            print("Receive data is \(txt)")
            break
        default:
            break
        }
    }
    
    func didReceiveRecorderData(sender: Neblina, respType: Int32, cmdRspId: Int32, data: UnsafePointer<UInt8>, dataLen: Int, errFlag: Bool) {
        switch (cmdRspId) {
            case NEBLINA_COMMAND_RECORDER_SESSION_DOWNLOAD:
                let offset = (UInt32(data[0]) & 0xFF) | ((UInt32(data[1]) & 0xFF) << 8) |
                    ((UInt32(data[2]) & 0xFF) << 16) | ((UInt32(data[2]) & 0xFF) << 32)
                
                var file : FileHandle?
//                let label = getMessageLabel(sender: sender)
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
                
                download_progress = String(format: "Dwnld : %d, offset : %d", sessionId, offset)
//                print(download_progress)
                lableprogress.text = download_progress
                
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
    
    func didReceiveEepromData(sender: Neblina, respType: Int32, cmdRspId: Int32, data: UnsafePointer<UInt8>, dataLen: Int, errFlag: Bool) {
        switch (cmdRspId) {
            case NEBLINA_COMMAND_EEPROM_READ:
                let pageno = UInt16(data[0]) | (UInt16(data[1]) << 8)
                //            dumpLabel.text = String(format: "EEP page [%d] : %02x %02x %02x %02x %02x %02x %02x %02x",
                //                                    pageno, data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9])
                break
            case NEBLINA_COMMAND_EEPROM_WRITE:
                break;
            default:
                break
        }
    }
    var visitors: [(x: Double,y: Double,z: Double)] = []
    var real_time_data: (x: Double,y: Double,z: Double)?
    
    private func updateChart() {
        var chartEntry = [ChartDataEntry]()
        
        for i in 0..<visitors.count {
            let value = ChartDataEntry(x: Double(i), y: visitors[i].x)
            chartEntry.append(value)
        }
        
        let line = LineChartDataSet(entries: chartEntry, label: "Visitor")
        line.colors = [UIColor.green]
        
        let data = LineChartData()
        data.addDataSet(line)
        realtimePrediction.data = data
        realtimePrediction.chartDescription?.text = "real time x data"
//        chartView.data = data
//        chartView.chartDescription?.text = "Visitors Count"
    }
    func updateChartView(with newDataEntry: ChartDataEntry,
                         dataEntries: inout [ChartDataEntry]) {
        if let oldEntry = dataEntries.first {
            dataEntries.removeFirst()
            realtimePrediction.data?.removeEntry(oldEntry, dataSetIndex: 0)
        }
        // 2
        dataEntries.append(newDataEntry)
        realtimePrediction.data?.addEntry(newDataEntry, dataSetIndex: 0)
        
        // 3
        realtimePrediction.notifyDataSetChanged()
        realtimePrediction.moveViewToX(newDataEntry.x)
    }
    override func viewDidAppear(_ animated: Bool) {
        //super.viewDidAppear(animated)
//        Timer.scheduledTimer(timeInterval:
//            1, target: self, selector: #selector(didUpdatedChartView), userInfo: nil, repeats: true)
    }
    var xValue = 0.0
    var dataEntries = [ChartDataEntry]()
    @objc func didUpdatedChartView() {
        // this is the place to enter new data point
        // cap nhat lai cai graph
        let newDataEntry = ChartDataEntry(x: xValue,
                                          y: Double.random(in: 0...50))
        updateChartView(with: newDataEntry, dataEntries: &dataEntries)
        xValue += 1
    }
    

    func didReceiveSensorData(sender : Neblina, respType : Int32, cmdRspId : Int32, data : UnsafePointer<UInt8>, dataLen : Int, errFlag : Bool) {
//        print("receiving data")
        switch (cmdRspId) {
        case NEBLINA_COMMAND_SENSOR_ACCELEROMETER_STREAM:
//            print("NEBLINA_COMMAND_SENSOR_ACCELEROMETER_STREAM")
            let x = (Int16(data[4]) & 0xff) | (Int16(data[5]) << 8)
            let xq = x
            let y = (Int16(data[6]) & 0xff) | (Int16(data[7]) << 8)
            let yq = y
            let z = (Int16(data[8]) & 0xff) | (Int16(data[9]) << 8)
            let zq = z
//            print((Double(x), Double(y), Double(z)))
//            visitors.append((Double(x), Double(y), Double(z)))
            real_time_data = (Double(x), Double(y), Double(z))
//            print("+++++++++")
//            let idx = getViewIdx(dev: sender)
//            if idx >= 0 {
//                let label = getStreamDataLabel(sender: sender)//display[idx].subviews[1] as! UILabel
//                label.text = String("Accel - x:\(xq), y:\(yq), z:\(zq)")
//                if sender.name.range(of: "01", options: NSString.CompareOptions.caseInsensitive) != nil {
//                    leftAccelGraph.add(double3(Double(xq), Double(yq), Double(zq)))
//                }
//                if sender.name.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
//                    rightAccelGraph.add(double3(Double(xq), Double(yq), Double(zq)))
//                }
//                if sender.name.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
//                    leftAccelGraph.add(double3(Double(xq), Double(yq), Double(zq)))
//                }
//            }
            //            rxCount += 1
            break
        case NEBLINA_COMMAND_SENSOR_GYROSCOPE_STREAM:
            let x = (Int16(data[4]) & 0xff) | (Int16(data[5]) << 8)
            let xq = x
            let y = (Int16(data[6]) & 0xff) | (Int16(data[7]) << 8)
            let yq = y
            let z = (Int16(data[8]) & 0xff) | (Int16(data[9]) << 8)
            let zq = z
            print((Double(x), Double(y), Double(z)))
            print("xxxxxx")
//            let idx = getViewIdx(dev: sender)
//            if idx >= 0 {
//                let label = getStreamDataLabel(sender: sender)//display[idx].subviews[1] as! UILabel
//                label.text = String("Gyro - x:\(xq), y:\(yq), z:\(zq)")
//                if idx == 0 {
//                    leftGyroGraph.add(double3(Double(xq), Double(yq), Double(zq)))
//                }
//            }
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
//            let idx = getViewIdx(dev: sender)
            var idx = -1
            print((Double(x), Double(y), Double(z)))
            print("AAAAAAA")
            if idx >= 0 {
//                let label = getStreamDataLabel(sender: sender)//display[idx].subviews[1] as! UILabel
//                label.text = String("Mag - x:\(xq), y:\(yq), z:\(zq)")
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
            print((Double(x), Double(y), Double(z)))
            print("-------")
            /*
             let x = (Int16(data[4]) & 0xff) | (Int16(data[5]) << 8)
             let xq = x
             let y = (Int16(data[6]) & 0xff) | (Int16(data[7]) << 8)
             let yq = y
             let z = (Int16(data[8]) & 0xff) | (Int16(data[9]) << 8)
             let zq = z*/
//            let idx = getViewIdx(dev: sender)
//            if idx >= 0 {
//                let label = getStreamDataLabel(sender: sender)//display[idx].subviews[1] as! UILabel
//                label.text = String("IMU - x:\(x), y:\(y), z:\(z)")
//                switch (idx) {
//                case 0:
//                    leftAccelGraph.add(double3(Double(x), Double(y), Double(z)))
//                    leftGyroGraph.add(double3(Double(gx), Double(gy), Double(gz)))
//                    break
//                case 1:
//                    rightAccelGraph.add(double3(Double(x), Double(y), Double(z)))
//                    rightGyroGraph.add(double3(Double(gx), Double(gy), Double(gz)))
//                    break
//                default:
//                    break
//                }
//            }
            //rxCount += 1
            break
        case NEBLINA_COMMAND_SENSOR_ACCELEROMETER_MAGNETOMETER_STREAM:
            break
        default:
            break
        }
        //        cmdView.setNeedsDisplay()
    }
    
    // MARK: - Bluetooth
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData : [String : Any],
                        rssi: NSNumber) {
        print("centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,")
//        print("PERIPHERAL NAME: \(peripheral)\n AdvertisementData: \(advertisementData)\n RSSI: \(rssi)\n")
        
//        print("UUID DESCRIPTION: \(peripheral.identifier.uuidString)\n")
        
        print("IDENTIFIER: \(peripheral.identifier)\n")
//        print("RSSI = \(rssi.floatValue) \(peripheral.name)")
        //if rssi.decimalValue < -70 || rssi.decimalValue > 0 {
        //    return
        //}
        
        if advertisementData[CBAdvertisementDataLocalNameKey] == nil {
            print("512")
            return
        }
        
        if advertisementData[CBAdvertisementDataManufacturerDataKey] == nil {
            print("517")
            return
        }
        
        let name = peripheral.name! //advertisementData[CBAdvertisementDataLocalNameKey] as! String
        
        print("Device name is: \(name)")
        if name.range(of: "MR-B1B-01", options: NSString.CompareOptions.caseInsensitive) == nil &&
            name.range(of: "MR-B1B-02", options: NSString.CompareOptions.caseInsensitive) == nil &&
            name.range(of: "Glove", options: NSString.CompareOptions.caseInsensitive) == nil {
            return
        }
        device_name = peripheral.name!
        print("FOUND Device!!!")
        
        var id = UInt64 (0)
        (advertisementData[CBAdvertisementDataManufacturerDataKey] as! NSData).getBytes(&id, range: NSMakeRange(2, 8))
        if (id == 0) {
            return
        }
        print("\(peripheral.name!) \(rssi)")
        
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
        print("start connecting")
        let device = Neblina(devName: name, devid: id, peripheral: peripheral)
        device.delegate = self
        central.connect(device.device, options: nil)
        objects.insert(device, at: 0)
        print("There are \(objects.count)")
        print("finish connecting")
        if objects.count >= 2 {
            central.stopScan()
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
//            view = display[0]

        }
        else if peripheral.name?.range(of: "02", options: NSString.CompareOptions.caseInsensitive) != nil {
//            view = display[1]

        }
        else if peripheral.name?.range(of: "Left", options: NSString.CompareOptions.caseInsensitive) != nil {
//            view = display[0]

        }
        for (idx, item) in objects.enumerated() {
            if item.device == peripheral {
                objects.remove(at: idx)
            }
        }
        
//        label = view.subviews[2] as! UILabel
//        label.text = "Device disconnected"
//        label = view.subviews[0] as! UILabel
//        label.text = " "
//        label = view.subviews[3] as! UILabel
//        label.text = " "
//        label = view.subviews[4] as! UILabel
//        label.text = " "
        print("Device disconnected")
        
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
        print("enter this function")
        print(central.state.rawValue)
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
//                 let device = lastPeripherals.last as CBPeripheral;
                //connectingPeripheral = device;
                //centralManager.connectPeripheral(connectingPeripheral, options: nil)
            }
            //scanPeripheral(central)
            print("scanning line 699")
            bleCentralManager.scanForPeripherals(withServices: [NEB_SERVICE_UUID], options: nil)//[CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true)])//, options: CBCentralManagerScanOptionAllowDuplicatesKey)
            print("finish here")
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
            print("enter this function 2")
            break
        }
    }

    var bleCentralManager : CBCentralManager!
    
    @IBOutlet weak var realtimePrediction: LineChartView!
    @IBOutlet weak var predictionGraph: LineChartView!
    @IBOutlet weak var realtimeLabel: UILabel!
    
    
    var objects = [Neblina]()
    
    
    func readCSV() -> [svm_modelInput]{
        
        var inputData: [svm_modelInput] = []
        
        do {
            
            // From a file inside the app bundle, with a custom delimiter, errors, and custom encoding
            let resource: CSV? = try CSV(
                name: "test",
                extension: "csv",
                bundle: .main,
                delimiter: ",",
                encoding: .utf8)
            
            // read each line of the csv files
            try resource!.enumerateAsArray { array in
//                print(array.first!, array[1], array[2], array[3])
                var svmData: svm_modelInput = svm_modelInput(ax: Double(array[0]) as! Double,
                                                             ay: Double(array[1]) as! Double,
                                                             az: Double(array[2]) as! Double)
//                print(svmData)
                inputData.append(svmData)
            }
        } catch is CSVParseError {
            // Catch errors from parsing invalid formed CSV
            print("CSV format not valid")
        } catch {
            // Catch errors from trying to load files
            print("Cannot load csv file")
        }
        return inputData
    }
    func drawPredictionGraph() {
        // draw the graph of the prediction in line graph
    }
    override func viewDidLoad() {
        bleCentralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        super.viewDidLoad()
        
//        do{
//            let content = self.download_weekdata()
//            let csv: CSV = try CSV(string: content)
//            print(csv)
//            print(csv.description)
//            
//            print("Print all array here")
//            try csv.enumerateAsArray {
//                array in
//                                print(array.first!, array[1])
//            }
//        } catch {
//            // Catch errors from trying to load files
//            print("Catch errors from trying to load files")
//        }
//        var input_data = readCSV()
//        return
//        setUpPredictionGraph(predictionGraph,
//                             input_data, "Historical activities summary", bySecond: false)
//        print("loading csv \(csv)")
        
        

    }
    
    func download_weekdata() -> String{
        var url_str = "https://raw.githubusercontent.com/vinbrule/data/master/week.csv"
        var contents: String = "id,name,age\n1,Alice,18"
        if let url = URL(string: url_str) {
            do {
                contents = try String(contentsOf: url)
                print(contents)
            } catch {
                // contents could not be loaded
                print("content is not loaded")
            }
        } else {
            // the URL was bad!
            print("the url is not correct")
        }
        return contents
    }
    
    func setUpPredictionGraph(_ predictionGraph: LineChartView, _ input_data: [svm_modelInput],
                              _ description: String, bySecond: Bool){
        predictionGraph.data = setChartDataMinimize(bySecond: bySecond, input_data)
        predictionGraph.notifyDataSetChanged()
        predictionGraph.chartDescription?.text = description
        
        // setting up the chart shape here
        predictionGraph.pinchZoomEnabled = true
//        predictionGraph.legend.enabled = true
        predictionGraph.animate(xAxisDuration: 2, yAxisDuration: 2)
        predictionGraph.rightAxis.enabled = true
        predictionGraph.rightAxis.valueFormatter = ChartFormatter()
        //        predictionGraph.xAxis.label
        let leftAxis = predictionGraph.leftAxis
        leftAxis.axisMinimum  = 0
        leftAxis.axisMaximum = 1
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawGridLinesEnabled = false
        leftAxis.drawZeroLineEnabled = true
        leftAxis.valueFormatter = ChartFormatter()
        
        leftAxis.labelCount = 2
        leftAxis.granularity = 1.0
        leftAxis.yOffset = 9
//        realtimeLabel.text="Status"
        print("Finish loading bluetooth")
        
        // xaxis
        predictionGraph.xAxis.labelPosition = .bottom
        
        predictionGraph.xAxis.valueFormatter = MyChartTimeFormatter()
        if bySecond == true{
        predictionGraph.xAxis.valueFormatter = MyChartTimeFormatterBySecond()
        }
        predictionGraph.xAxis.centerAxisLabelsEnabled = true
    }
    func setChartData() {
        print("start drawing chart")
        let input_svm_data = readCSV()
        print("There are \(input_svm_data.count)")
        let model = svm_model()
        var entries: [ChartDataEntry] = Array()
        for (i, input_data) in input_svm_data.enumerated(){
            guard let predicted_results = try? model.prediction(input: input_data) else{
                fatalError("unexpected error")
            }
            let data_entry = BarChartDataEntry(x: Double(i),
                                               yValues: [predicted_results.classProbability[0]!,predicted_results.classProbability[1]!])
            entries.append(data_entry)
        }
                
        let set = BarChartDataSet(entries: entries, label: "Moving probalities")
        set.drawIconsEnabled = false
        set.colors = [ ChartColorTemplates.colorful()[1], UIColor(red: 67/255, green: 67/255, blue: 72/255, alpha: 1)]
        set.stackLabels = ["Stationary", "Moving"]
        let data = BarChartData(dataSet: set)
        predictionGraph.data = data
    }
    // each second is one point in data
    
    let SAMPLING_RATE = 50
    
    func setChartDataMinimize( bySecond: Bool, _ input_svm_data: [svm_modelInput]) -> LineChartData{
        print("start drawing chart")
//        let input_svm_data = readCSV()
        print("There are \(input_svm_data.count)")
        let model = svm_model()
        
        var entries: [ChartDataEntry] = Array()
        
        let seconds = input_svm_data.count/SAMPLING_RATE
        let minutes = input_svm_data.count/SAMPLING_RATE/60
        var interval = seconds
        if bySecond == false{
           interval = minutes
        }
        
        for index in 0...interval-1{
            var hasMoving = false
            for  j in 0..<SAMPLING_RATE{ //50hz so it is 50
                guard let predicted_results = try? model.prediction(input: input_svm_data[index*SAMPLING_RATE + j]) else{
                    fatalError("unexpected error")
                }
                if predicted_results.moving == 1{
                    let data_entry = ChartDataEntry(x: Double(index), y: Double(predicted_results.moving))
                    entries.append(data_entry)
                    hasMoving = true
                    break
                }
            }
            // this is when moving == 0
            if hasMoving == false{
                let data_entry = ChartDataEntry(x: Double(index), y: 0.0) 
                entries.append(data_entry)
            }
        }
        
        //draw the graph
        print("size of the data set")
        let set = LineChartDataSet(entries: entries)//, label: "Moving"
        set.drawIconsEnabled = false
        set.mode = .horizontalBezier
        set.axisDependency = .right
        set.drawCirclesEnabled = false
        set.drawFilledEnabled = true
        set.drawValuesEnabled = false
        set.fillAlpha = 0.4
        let data = LineChartData(dataSet: set)
//        predictionGraph.data = data
//        predictionGraph.notifyDataSetChanged()
//        predictionGraph.chartDescription?.text = "Activities summary"
        return data
        
    }
    @IBAction func realtimePrediction(_ sender: UIButton) {
        
        // get the values from the collar
        // put the values inside the prediction model
        // if ... else
        
        
        var entries: ChartDataEntry?
//real_time_data
        if real_time_data == nil{
            print("no realtime date here")
            return
        }
        
//        guard let predicted_results = try? model.prediction(ax: real_time_data!.x, ay: real_time_data!.y, az: real_time_data!.z) else{
//            fatalError("unexpected error")
//        }
//        if predicted_results.moving == 1{
//            realtimeLabel.text = "Moving"
//        }else{
//            realtimeLabel.text = "Stay"
//        }
        
        let timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(fire), userInfo: nil, repeats: true)
    }
    
    let model = svm_model()
   
    
    @objc func fire()
    {
        
        if real_time_data == nil{
            print("no realtime date here")
            return
        }
        print(real_time_data)
        guard let predicted_results = try? model.prediction(ax: real_time_data!.x, ay: real_time_data!.y, az: real_time_data!.z) else{
            fatalError("unexpected error")
        }
        print(predicted_results.moving)
        if predicted_results.moving == 0{
            realtimeLabel.text = "Stay"
            
        }else{
            realtimeLabel.text = "Moving"
        }
    }
    
    func setChartDateOnlyPrediction(){
//        var entry
        print("start drawing chart")
        let input_svm_data = readCSV()
        print("There are \(input_svm_data.count)")
        let model = svm_model()
        var entries: [ChartDataEntry] = Array()
        for (i, input_data) in input_svm_data.enumerated(){
            guard let predicted_results = try? model.prediction(input: input_data) else{
                fatalError("unexpected error")
            }
            let data_entry = ChartDataEntry(x: Double(i), y: Double(predicted_results.moving))
            entries.append(data_entry)
            if i == 500{
                break
            }
        }
        
        let set = LineChartDataSet(entries: entries, label: "Moving probalities")
        set.drawIconsEnabled = false
        let data = LineChartData(dataSet: set)

        predictionGraph.data = data
        
    }

    
    func eraseAllSession(){
            
            for (idx, item) in self.objects.enumerated() {
                item.eraseStorage(true)
            }
        isErasedAllSession = true
    }
    
    @IBAction func btnStartPressed(_ sender: Any) {
        print("click me")
        // delete all previous session before executing
        // the others
        
        var name : String = "Collar"
        print(objects.count)
        if objects == nil{
            print("it is nil")
        }
        else{
        print("Number of object is \(objects.count)")
        }
        for item in objects {
            item.sessionRecord(true, info: name) // start/stop record
            item.sensorStreamAccelData(true)
        }
        isErasedAllSession = false
        
    }
    @IBAction func stopButtonPressed(_ sender: Any) {
        // after stopping, upload all data to the cloud
        print("Stop")
        print(objects.count)
        for item in objects {
            //item.disableStreaming()
            item.disableStreaming()
//            item.sessionRecord(false, info: playerTextField.text!)
            print("Stop done")
        }
        
        // downloading data from the collar
//        downloadDataFromCollar()
        
        // upload data to the cloud
//        uploadtoCloud()
        
    }
    @IBAction func btnErasePressed(_ sender: UIButton) {
        eraseAllSession()
        print("Done")
    }
    func sessionRecord(_ Enable:Bool, info : String) {
        var param = [UInt8](repeating: 0, count: 1)
        
        if Enable == true
        {
            param[0] = 1
        }
        else
        {
            param[0] = 0
        }
        print("\(info)")
        param += info.utf8
        print("\(param)")
        
            }
    
    
     func downloadDataFromCollar() {
        //        let cell = sessionView.cellForRow( at: idx!)
        //        let nameLabel = cell?.contentView.subviews[2] as! UILabel
        //        let sessionLebel = cell?.contentView.subviews[1] as! UILabel
        // get the date time as the uniq string for file name
        
        if isErasedAllSession == true{
            print("No session to download")
            return
        }
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        
        var t = dateFormatter.string(from: currentDate) // 21/7/2019, 9:41 AM
        
        t = t.replacingOccurrences(of: ":", with: "_")
        t = t.replacingOccurrences(of: "/", with: "_")
        t = t.replacingOccurrences(of: ",", with: "_")
        print(t)
        
        let filePathLeft = homeDir + "ABCDEFGHIJKLM_" + t + "_MR-B1B-01.dat"
        let filePathRight = homeDir + "ABCDEFGHIJKLM_" + t + "_MR-B1B-02.dat"
        
        path = filePathRight
        
        print("path stuff left \(filePathLeft) ")
        print("path stuff right \(filePathRight) ")
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
        print("debug: \(fileLeft) \(fileRight)")
        //
        downloadRecovering = false
        startDownload = true
        //        sessionId = UInt16(sessionLebel.text!)!
        sessionId = 0 // because there is only 1 session allow, download the first session
        print("session is \(sessionId)")
        nextOffset[0] = 0
        nextOffset[1] = 0
        nextOffset[2] = 0
        print("meo den sieu cap")
        for item in objects {
            item.getSessionInfo(sessionId, idx: UInt8(NEBLINA_RECORDER_SESSION_INFO_GENERAL.rawValue))
        }
        print("Download")
//        print("uploading to cloud")
//        uploadtoCloud()
    }
    
    /// download the first session
    /// there is only one session allowed in the device
    
    
    @IBAction func btnDownloadFirstSession(_ sender: Any) {
        downloadDataFromCollar()
    }

    func downloadData(){
        if isErasedAllSession == true{
            print("No session to download")
            return
        }
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        
        var t = dateFormatter.string(from: currentDate) // 21/7/2019, 9:41 AM
        
        t = t.replacingOccurrences(of: ":", with: "_")
        t = t.replacingOccurrences(of: "/", with: "_")
        t = t.replacingOccurrences(of: ",", with: "_")
        print(t)
        
        let filePathLeft = homeDir + "ABCDEFGHIJKLM_" + t + "_MR-B1B-01.dat"
        let filePathRight = homeDir + "ABCDEFGHIJKLM_" + t + "_MR-B1B-02.dat"
        
        path = filePathRight
        
        print("path stuff left \(filePathLeft) ")
        print("path stuff right \(filePathRight) ")
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
        print("debug: \(fileLeft) \(fileRight)")
        //
        downloadRecovering = false
        startDownload = true
//        sessionId = UInt16(sessionLebel.text!)!
        sessionId = 0 // because there is only 1 session allow, download the first session
        print("session is \(sessionId)")
        nextOffset[0] = 0
        nextOffset[1] = 0
        nextOffset[2] = 0
        for item in objects {
            item.getSessionInfo(sessionId, idx: UInt8(NEBLINA_RECORDER_SESSION_INFO_GENERAL.rawValue))
        }
        print("Download")
    }
    func readAccelerometerData() -> (NSDate,[(Double,Int16, Int16, Int16)],
                                            [(Int16, Int16, Int16)]){
                                                
        //todo: add default file path for testing purpose
        let filePath = path!
        print("file is: \(filePath)")
        var acc : [(Int16, Int16, Int16)] = [] // no timpstamp
        var date: NSDate
        var accWithTimestamp : [(Double,Int16, Int16, Int16)] = []
//        var accWithTime : [(Double, Int16, Int16, Int16)] = []
        (date, accWithTimestamp, acc) = readSensorBinaryData(filePath)
        
        // upload to the cloud here
        
        return (date, accWithTimestamp, acc)
    }
        
    @IBOutlet weak var predictionGraphBelow: LineChartView!
    func convertAccelerometerToSVMInput(_ accelerometer: [(Int16, Int16, Int16)]) -> [svm_modelInput]{
        
        var inputData: [svm_modelInput] = []
        
        for data in accelerometer{
            let svmData: svm_modelInput = svm_modelInput(ax: Double(data.0) ,
                                                         ay: Double(data.1) ,
                                                         az: Double(data.2) )
            inputData.append(svmData)
        }
        return inputData
    }
    
    @IBOutlet weak var pieChartView: PieChartView!
    
    override func viewDidLayoutSubviews() {
        
        var set = PieChartDataSet(entries: [
        PieChartDataEntry(value: 60, label: "Happy"),
        PieChartDataEntry(value: 40, label: "Resting"),
        ], label: "Activity Health")
        // this data is fake:
        
        var pieData = PieChartData(dataSet: set)
        set.colors = ChartColorTemplates.joyful()
        self.pieChartView.data = pieData
        pieChartView.sizeToFit()
    }
    
    func preprocessAccData() -> [svm_modelInput]{
        var accData : [(Int16, Int16, Int16)] = []
        (_, _, accData) = readAccelerometerData()
        return convertAccelerometerToSVMInput(accData)
    }
    
    @IBAction func btnUploadtoCloudPressed(_ sender: UIButton) {
        ///var/mobile/Containers/Data/Application/0B253B0B-9028-46CC-A9D7-9EE1CECC4F85/Documents/ABCDEFGHIJKLM_4_9_20_ 14_12_MR-B1B-02.dat
        var (date, accWithTimestamp, acc) = readAccelerometerData()
        var db = DBUploader(user_id: 0001, date: date, accWithTimestamp: accWithTimestamp)
        db.insert_db()
        
    }

    func uploadtoCloud(){
        var (date, accWithTimestamp, acc) = readAccelerometerData()
        var db = DBUploader(user_id: 0001, date: date, accWithTimestamp: accWithTimestamp)
        db.insert_db()
    }
    @IBAction func btnProcessPressed(_ sender: UIButton) {
        //press this button after start and download the file
        // create the line view
        // load the data like in the prediction
        let input_data = preprocessAccData()
        setUpPredictionGraph(predictionGraphBelow,
                             input_data,
                             "Downloaded recent activities", bySecond: true)
    }
    
    
    var dataToday:LineChartData?
    
    @IBAction func btnTodayPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "today", sender: self )
    }
    
    @IBAction func btnWeekPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "week", sender: self)
    }
    
    
    //todo:
    // setting data for view 1 and view 2
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "today"{
            var des = segue.destination as! TodayViewController
            let input_data = preprocessAccData()
            self.dataToday =  setChartDataMinimize(bySecond: true, input_data)
            des.data = self.dataToday
        }
        else if segue.identifier == "week"{
            var desVC = segue.destination as! WeekViewController
            
        }
    }

    
    @IBOutlet weak var demoMode: UIButton!
    
    @IBAction func btnDemoModePressed(_ sender: Any) {
        self.demoMode.titleLabel?.text = "Setting Up"
        // run the function of start and stop button
        // automatically stop after 5 seconds? anyway 
        // 
    }
}

//@objc(BarChartFormatter)
class ChartFormatter:NSObject,IAxisValueFormatter{
    
    var months: [String]! = ["Active","Stay"]
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value == 1{
            return "Active"
        }
        if value == 0{
        return "Stay"
        }
        return ""
    }
   
}

class MyChartTimeFormatter:NSObject,IAxisValueFormatter{
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value == 0{
            return "0 Minute"
        }
        return "\(Int(value))"
    }
}

class MyChartTimeFormatterBySecond:NSObject,IAxisValueFormatter{
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value == 0{
            return "0 Second"
        }
        return "\(Int(value))"
    }
}

