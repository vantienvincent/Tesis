//
//  SensorRawDataReader.swift
//  B1BRecorder
//
//  Created by Van on 3/26/20.
//  Copyright © 2020 Hoan Van. All rights reserved.
//

import Foundation
func readSensorBinaryData(_ filePath: String) -> (NSDate, [(Double,Int16, Int16, Int16)],
    [(Int16, Int16, Int16)] ){
    print("file is: \(filePath)")
    var accWithTimestamp : [(Double,Int16, Int16, Int16)] = []
        var accNoTimeStamp : [(Int16, Int16, Int16)] = []
    let data = FileManager.default.contents(atPath: filePath)
    var x = data?.subdata(in: 0..<496) // this is the header
    // at this position, y is the time the sensor data is recorded
    var timeStamp = Double(x![5-1]) + Double(x![6-1])*256 + Double(x![7-1])*pow(2,16) + Double(x![8-1])*16777216;
    let date = NSDate(timeIntervalSince1970: timeStamp) // to print the recorded date
    
    var index = 496
    // index starting from the number 496
    while index < data!.count{
        // timestamp 3 bytes + 2 bytes ax + 2 bytes ay + 2 bytes az = 9 bytes, 12 is for safety
        // missing one sampling does not harm anybody
        if index + 12 > data!.count{
            break
        }
        // read 3 control bytes
        x = data?.subdata(in: index..<index+3)
        let m = x! as NSData
        
        //convert bytes to data
        let k:Data = Data(bytes: m.bytes, count: 3)
        //print(x)
        let number: Int32 = k.withUnsafeBytes {
            (pointer: UnsafePointer<Int32>) -> Int32 in
            return pointer.pointee // reading four bytes of data
        }
        var bytes = [UInt8](x!)
        index = index + 3
        var acc_nb_packets = 0
        if bytes[0] == 13 && bytes[2] == 16 || bytes[0]==1 && bytes[2] == 31
        {
            print("here")
        }
        else if bytes[0]==13 && bytes[2] == 11{
            //x(1)==13 & x(3)==11 //gyroscope
        }
        else if bytes[0]==1 && bytes[2] == 4{
            //        elseif x(1)==1 & x(3)==4 //quaternion
            print("here")
        }
        else if bytes[0]==1 && bytes[2] == 6 {
            //        elseif x(1)==1 & x(3)==6
            print("jere")
        }
        else if bytes[0]==13 && bytes[2] == 13 {
            //x(1)==13 & x(3)==13
            print("jere")
        }
        else if bytes[0]==1 && bytes[2] == 5 {
            //        elseif x(1)==1 & x(3)==5
            print("jere")
        }
        else if bytes[0]==13 && bytes[2] == 15 {
            //                elseif x(1)==13 & x(3)==15
            print("jere")
        }
        else if bytes[0] == 13 && bytes[2] == 10{ // this is accelerometer data
            acc_nb_packets = acc_nb_packets + 1
            // get next 4 bytes for time stamp
            var x = data?.subdata(in: index..<index + 4)//timestamp
            var k:Data = Data(bytes: m.bytes, count: 4)
            timeStamp = Double(x![0]) + Double(x![1])*256 + Double(x![2])*pow(2,16) + Double(x![3])*16777216;
            index = index + 4
            x = data?.subdata(in: index..<index + 2)//ax
            var m = x! as NSData
            k = Data(bytes: m.bytes, count: 2)
            let ax: Int16 = k.withUnsafeBytes {
                (pointer: UnsafePointer<Int16>) -> Int16 in
                return pointer.pointee // reading four bytes of data
            }
            //ay
            index = index + 2
            x = data?.subdata(in: index..<index + 2)//ay
            m = x! as NSData
            k = Data(bytes: m.bytes, count: 2)
            let ay = k.withUnsafeBytes {
                (pointer: UnsafePointer<Int16>) -> Int16 in
                return pointer.pointee // reading four bytes of data
            }
            //az
            index = index + 2
            x = data?.subdata(in: index..<index + 2)//az
            m = x! as NSData
            k = Data(bytes: m.bytes, count: 2)
            let az = k.withUnsafeBytes {
                (pointer: UnsafePointer<Int16>) -> Int16 in
                return pointer.pointee // reading four bytes of data
            }
//            print("\(Int(timeStamp)),\(ax),\(ay),\(az)")
            index = index + 2
            accWithTimestamp.append((timeStamp, ax, ay, az))
            accNoTimeStamp.append((ax, ay, az))
        }
    }
    return (date, accWithTimestamp, accNoTimeStamp)
}
