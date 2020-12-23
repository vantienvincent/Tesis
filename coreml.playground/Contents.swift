import Cocoa
import CreateML
var str = "Hello, playground"
var data = try MLDataTable(contentsOf: URL(fileURLWithPath: "/Users/van/Documents/Software/source code/activity_no_activity_labeled_data/06-03-2019 (1)/test.csv"))

print(data)


import SwiftCSV
//import SwiftCSV
