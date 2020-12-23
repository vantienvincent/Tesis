//
//  WeekViewController.swift
//  B1BRecorder
//
//  Created by Van on 5/29/20.
//  Copyright © 2020 Hoan Hoang. All rights reserved.
//

import UIKit
import SwiftCSV
import Charts
class WeekViewController: UIViewController {

    
    var lineView = LineChartView()
    var data:LineChartData?
    var entries: [ChartDataEntry] = Array()
    override func viewDidLoad() {
        super.viewDidLoad()

        lineView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.width)
        lineView.center = view.center
        view.addSubview(lineView)
        makeDataEntries()
        var set = LineChartDataSet(entries: self.entries)
        var data = LineChartData(dataSet: set)
        lineView.data = data
        prepareGraph(lineView)
        // Do any additional setup after loading the view.
    }
    
    
    func makeDataEntries(){
        do{
            let content = self.download_weekdata()
            let csv: CSV = try CSV(string: content)
            print(csv)
            print(csv.description)
            
            print("Print all array here")
            var entries: [ChartDataEntry] = Array()
            
            var i = 0
            try csv.enumerateAsArray {
                array in
                print(array.first!, array[1])
                entries.append(ChartDataEntry(x:Double(i) , y: (array[1] as NSString).doubleValue))
                i=i+1
                print(i)
            }
            self.entries = entries
        } catch {
            // Catch errors from trying to load files
            print("Catch errors from trying to load files")
        }
        
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
    
    func prepareGraph(_ predictionGraph: LineChartView){
        
        // download data from internet to get the time:
//        var entries: [ChartDataEntry] = Array()
        /// prefix
//        makeDataEntries()
        
        predictionGraph.notifyDataSetChanged()
        predictionGraph.chartDescription?.text = description
        
        // setting up the chart shape here
        predictionGraph.pinchZoomEnabled = true
        //        predictionGraph.legend.enabled = true
        predictionGraph.animate(xAxisDuration: 2, yAxisDuration: 2)
        predictionGraph.rightAxis.enabled = true
        predictionGraph.rightAxis.valueFormatter = ChartFormatter()
        
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
        
        predictionGraph.xAxis.labelPosition = .bottom
        
        predictionGraph.xAxis.valueFormatter = MyChartTimeFormatter()
        predictionGraph.xAxis.valueFormatter = MyChartTimeFormatterBySecond()
    }

    // download data from cloud,
    // this time is from a url:
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
