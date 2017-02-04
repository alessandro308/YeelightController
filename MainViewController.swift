//
//  MainViewController.swift
//  YeelightController
//
//  Created by Alessandro Pagiaro on 03/02/17.
//  Copyright © 2017 Alessandro Pagiaro. All rights reserved.
//
import Foundation
import Cocoa

class MainViewController: NSViewController {
    var accesa = false
    var i = 0
    let bulb = Yeelight(ip: "192.168.1.111")
    
    @IBOutlet var switchBtn: NSButton!
    @IBOutlet var lumBar: NSSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(bulb.proprieties.power){
            switchBtn.title = "Spegni"
        }
    }
    
    @IBAction func lumBarChanged(_ sender: Any) {
       

    }
    
    @IBAction func toggle(_ sender: AnyObject) {
        if(bulb.proprieties.power){
            if(bulb.switchOff()){
                switchBtn.title = "Accendi"
                self.accesa = false
            }
        }
        else{
            if(bulb.switchOn()){
                switchBtn.title = "Spegni"
                self.accesa = true
            }
        }
    }
    
    @IBAction func exitBtn(_ sender: Any) {
        bulb.closeConnection()
        NSApplication.shared().terminate(self)
    }


}
