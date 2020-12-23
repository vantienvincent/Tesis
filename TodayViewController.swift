//
//  TodayViewController.swift
//  B1BRecorder
//
//  Created by Van on 5/29/20.
//  Copyright © 2020 Hoan Hoang. All rights reserved.
//

import UIKit
import Charts
class TodayViewController: UIViewController {

    var data:LineChartData?
    var lineChart =  LineChartView()
    override func viewDidLoad() {
        super.viewDidLoad()

        lineChart.frame =  CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.width)
        lineChart.center = view.center
        view.addSubview(lineChart)
        
        setUpPredictionGraph(lineChart)
        
    }
    
    func setUpPredictionGraph(_ predictionGraph: LineChartView){
        predictionGraph.data = self.data
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
