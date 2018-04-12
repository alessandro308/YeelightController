//
//  Window.swift
//  YeelightController2
//
//  Created by Alessandro Pagiaro on 28/01/2018.
//  Copyright © 2018 Alessandro Pagiaro. All rights reserved.
//

import Cocoa

class Window: NSWindowController {
    
    var b = Yeelight()
    @IBOutlet var brightBar: NSSlider!
    @IBOutlet var colorBtn: NSColorWell!
    
    @IBAction func ToggleBtnClicked(_ sender: Any) {
       b.toggle()
    }
    
    @IBAction func brightSet(_ sender: Any) {
        b.setBrightness(value: Int(brightBar.intValue))
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        if(b.IP == ""){
            print("BULB NOT FOUND");
        }
        brightBar.intValue = Int32(b.proprieties.bright)
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func colorSet(_ sender: Any) {
        b.set_color(
            r: Int(colorBtn.color.redComponent),
            g: Int(colorBtn.color.greenComponent),
            b: Int(colorBtn.color.blueComponent));
    }
}
