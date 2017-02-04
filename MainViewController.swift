//
//  MainViewController.swift
//  YeelightController
//
//  Created by Alessandro Pagiaro on 03/02/17.
//  Copyright © 2017 Alessandro Pagiaro. All rights reserved.
//
import Foundation
import Cocoa
import AppKit

class MainViewController: NSViewController, NSSpeechRecognizerDelegate {
    var accesa = false
    var i = 0
    let bulb = Yeelight(ip: "192.168.1.111")
    var timer = Timer()
    
    @IBOutlet var switchBtn: NSButton!
    @IBOutlet var lumBar: NSSlider!
    @IBOutlet var colorBtn: NSColorWell!
    @IBOutlet var voiceBtn: NSButton!
    
    var vc = NSSpeechRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bulb.updateProprieties()
        if(bulb.proprieties.power){
            switchBtn.title = "Spegni"
        }
        lumBar.intValue = Int32(bulb.proprieties.bright)
        let rgbNumber = UInt32(bulb.proprieties.rgb)
        let red = CGFloat(Float(rgbNumber >> 16) / 255)
        let green =  CGFloat(Float((rgbNumber >> 8) % 256) / 255)
        let blue = CGFloat(Float(rgbNumber % 256) / 255)
        let color = NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
        colorBtn.color = color
    }
    
    
    @IBAction func lumBarChanged(_ sender: Any) {
       _ = bulb.set_bright(newBright: Int(lumBar.intValue))
        
    }
    
    @IBAction func voiceBtnPressed(_ sender: Any) {
        vc?.delegate = self
        vc?.commands = ["Luce accenditi",
                        "Luce spegniti",
                        "Stop Riconoscimento Vocale",
                        "Avvio Riconoscimento Vocale"]
        vc?.startListening()
    }
    @IBAction func voiceStop(_ sender: Any) {
        vc?.stopListening()
    }
    
    var breakState = false
    func speechRecognizer(_ sender: NSSpeechRecognizer, didRecognizeCommand command: String) {
        if(command == "Stop Riconoscimento Vocale"){
            breakState = true
        }
        if(command == "Avvio Riconoscimento Vocale"){
            breakState = false
        }
        if(breakState){
            return
        }
        if(command == "Luce accenditi"){
            _ = bulb.switchOn()
        }
        if(command == "Luce spegniti"){
            _ = bulb.switchOff()
        }
    }
    
    
    @IBAction func colorChanged(_ sender: Any) {
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(lastColor(c:)), userInfo: nil, repeats: false)
    }
    
    func lastColor(c: NSColor){
        let c = colorBtn.color
        let t = CGFloat(255)
        _ = bulb.set_color(r: Int(c.redComponent*t), g: Int(c.greenComponent*t), b: Int(c.blueComponent*t))
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
