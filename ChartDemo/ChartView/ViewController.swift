//
//  ViewController.swift
//  ChartDemo
//
//  Created by Khanh Vu on 25/3/25.
//

import UIKit

class ViewController: UIViewController {
    private let chartView = ChartView()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        rotateViewLanscape()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setUpUI()
        }
    }
    
    func rotateViewLanscape() {
        let appDel = UIApplication.shared.delegate as! AppDelegate
        appDel.orientationLock = .landscape

         if #available(iOS 16.0, *) {
             DispatchQueue.main.async {
                 let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                 self.setNeedsUpdateOfSupportedInterfaceOrientations()
                 self.navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                 windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
                     print(error)
                     print(windowScene?.effectiveGeometry ?? "")
                 }
             }
         }else{
             UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
         }
    }
    
    func setUpUI() {
        view.addSubview(chartView)
        chartView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        if let chartModel = ChartModel.loadFromFile(named: "chart") {
            // Init chartView
            DispatchQueue.main.async {
                let data = chartModel.data.dataChart.sorted(by: {$0.timeStamp < $1.timeStamp})
                self.chartView.bindData(data)
            }
        } else {
            print("Failed to load chart data")
        }
    }
}
