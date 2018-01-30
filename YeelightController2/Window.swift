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
    
    @IBAction func ToggleBtnClicked(_ sender: Any) {
       b.toggle()
    }
    
    @IBAction func brightSet(_ sender: Any) {
        b.setBrightness(value: Int(brightBar.intValue))
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        brightBar.intValue = Int32(b.proprieties.bright)
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
