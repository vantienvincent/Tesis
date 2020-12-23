//
//  DatabaseUploading.swift
//  B1BRecorder
//
//  Created by Van on 4/8/20.
//  Copyright © 2020 Hoan Hoang. All rights reserved.
//

import Foundation


// create the file in csv and save in local memory
// upload the file to the posgresql
// table schema:
// user_id, time_id, timestamp, ax, ay, az
// table_id is the user_id
// delete the file after uploading

// need: get the timestamp

///
///
/// create schema of the table here
///

//CREATE TABLE public.sensor_data (
//    user_id int4 NOT NULL,
//    time_creat timestamptz NULL,
//    time_stamp int4 NULL,
//    ax int2 NULL,
//    ay int2 NULL,
//    az int2 NULL
//);
//INSERT INTO weather VALUES ('San Francisco', 46, 50, 0.25, '1994-11-27');
import Foundation
import PostgresClientKit
class DBUploader{
    
    
    var user_id = 0001
    var date: NSDate!
    var accWithTimestamp : [(Double,Int16, Int16, Int16)]?
    var db_host = "database-2.cbmkltrew6iu.us-east-2.rds.amazonaws.com"
    var db_user = "postgres"
    var db_port = "5432"
    var db_name = "b1b"
    var db_password = "11111111" // 8 number 1
    
    // TODO: move this one to a new struct
    init(user_id: Int, date: NSDate, accWithTimestamp : [(Double,Int16, Int16, Int16)]) {
        self.user_id = user_id
        self.date = date
        self.accWithTimestamp = accWithTimestamp
    }
    
    func query_string_builder() -> String{
        var values:String = ""
        for val in accWithTimestamp!{
            var str = "( \(user_id), '\(date!.description)', \(val.0), \(val.1), \(val.2), \(val.3) ) ,"
            
            values = values + str
        }
        let comma = values.removeLast()
        print(comma)
        return values
    }
    func insert_db(){
        do {
            var configuration = PostgresClientKit.ConnectionConfiguration()
            configuration.host = db_host
            configuration.database = db_name
            configuration.user = db_user
            configuration.credential = .md5Password(password: db_password)
            
            let connection = try PostgresClientKit.Connection(configuration: configuration)
            defer { connection.close() }
            
            let text = "INSERT INTO sensor_data (user_id,time_creat,time_stamp, ax, ay, az) VALUES \(self.query_string_builder());"
            print("start executing query")
            print(text)
            let statement = try connection.prepareStatement(text: text)
            defer { statement.close() }
//            2020-01-24 15:38:25 +0000
            
            let cursor = try statement.execute()
            
            defer { cursor.close() }
            
            print("upload data sucessfully")
//            for row in cursor {
//                let columns = try row.get().columns
//                let actor = try columns[0].int()
//                let first_name = try columns[1].string()
//                let last_name = try columns[2].string()
//                let last_update = try columns[3].timestampWithTimeZone()
//                print("\(actor), \(first_name), \(last_name), \(last_update)")
//
//            }
        } catch {
            print(error) // better error handling goes here
        }
        
    }
}

