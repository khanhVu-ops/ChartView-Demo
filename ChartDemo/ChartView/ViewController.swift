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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(chartView)
        chartView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}
