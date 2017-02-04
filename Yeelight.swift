//
//  Yeelight.swift
//  YeelightController
//
//  Created by Alessandro Pagiaro on 04/02/17.
//  Copyright © 2017 Alessandro Pagiaro. All rights reserved.
//

import Foundation
import SwiftSocket

struct Proprieties{
    var bright : Int = 0;
    var ct : Int = 0;
    var rgb : Int = 0;
    var power : Bool = false;
    var hue : Int = 0;
    var sat : Int = 0;
    var color_mode : Int = 0;
    var flowing : Bool = false;
    var delayoff : Int = 0;
    var flow_params : [String: Any] = [:];
    var music_on : Bool = false;
    var name : String = "";
}

class Yeelight {
    
    var proprieties : Proprieties = Proprieties();
    let IP: String;
    let port : Int;
    var i = 0; //Message ID, increase by one each message sent
    
    let client : TCPClient;
    
    init() {
        // Find Yeelight in the network
        self.IP = "" //TODO Find IP
        self.port = 55443
        client = TCPClient(address: self.IP, port: Int32(self.port))
        self.updateProprieties()
    }
    
    init(ip : String) {
        // Create the object with specific IP, port is set to 55443
        self.IP = ip
        self.port = 55443
        client = TCPClient(address: self.IP, port: Int32(self.port))
        self.updateProprieties()
    }
    
    init(ip: String, port: Int){
        // Create the object with specific IP and Port
        self.IP = ip
        self.port = port
        client = TCPClient(address: self.IP, port: Int32(self.port))
        self.updateProprieties()
    }
    
    func switchOn() -> Bool{
        if(sendCmd(id: self.i, method: "set_power", params: ["on", "smooth", 500], printMessage: "Luce Accesa")){
            proprieties.power = true
            return true
        }
        return false
    }
    
    func switchOff() -> Bool{
        if(sendCmd(id: self.i, method: "set_power", params: ["off", "smooth", 500], printMessage: "Luce Spenta")){
            proprieties.power = false
            return true
        }
        return false
    }
    
    func set_bright(newBright : Int) -> Bool{
        if(newBright < 0 || newBright > 100){
            return false;
        }
        if(sendCmd(id: i, method: "set_bright", params: [newBright, "smooth", 500], printMessage: "Luminosità impostata")){
            self.proprieties.bright = newBright
            return true
        }
        return false
    }
    
    func updateProprieties(){
        let d = sendCmdReply(id: i, method: "get_prop", params: ["power", "bright", "ct", "rgb", "hue", "sat", "color_mode", "flowing", "delayoff", "flow_params", "music_on", "name"], printMessage: "getProprieties")
        let res = d["result"] as! [Any]
        if(res[0] as! String == "on"){
            proprieties.power = true
        } else {
            proprieties.power = false
        }
        proprieties.bright = Int((res[1] as! NSString).intValue)
        proprieties.ct = Int((res[2] as! NSString).intValue)
        proprieties.rgb = Int((res[3] as! NSString).intValue)
        proprieties.hue = Int((res[4] as! NSString).intValue)
        proprieties.sat = Int((res[5] as! NSString).intValue)
        proprieties.color_mode = Int((res[6] as! NSString).intValue)
        proprieties.flowing = Int((res[7] as! NSString).intValue) == 0 ? false : true
        proprieties.delayoff = Int((res[8] as! NSString).intValue)
        proprieties.music_on = Int((res[10] as! NSString).intValue) == 1 ? true : false
        proprieties.name = (res[11] as! NSString) as String
        print(proprieties)
    }
    
    func set_color(r : Int, g : Int, b : Int) -> Bool{
        if(!self.proprieties.power){
            _ = self.switchOn()
        }
        if(sendCmd(id: i, method: "set_rgb", params: [r*65536+g*256+b, "smooth", 500], printMessage: "Colore cambiato")){
            self.proprieties.rgb = r*65536+g*256+b
            return true
        }
        return false
    }
    
    func closeConnection(){
        client.close()
    }
    
    //Support function
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func sendCmd(id: Int, method: String, params : [Any], printMessage : String?) -> Bool{
        var param = ""
        for p in params {
            if let n = p as? Int{
                param = param + "\(n),"
            } else {
                 param = param + "\"\(p)\","
            }
        }
        param = param.substring(to: param.index(before: param.endIndex)) //Remove last comma
        self.closeConnection()
        switch client.connect(timeout: 2) {
        case .success:
            switch client.send(string: "{\"id\":\(id),\"method\":\"\(method)\",\"params\":[\(param)]}\r\n" ) {
            case .success:
                guard let data = client.read(1024*10) else { client.close(); return false }
                
                let response = String(bytes: data, encoding: .utf8)
                let dict = convertToDictionary(text: response!)
                
                if dict?["id"] as! Int == i{
                    let err = dict?["error"]
                    if (err != nil) {
                        print(err ?? "Errore")
                        client.close()
                        return false
                    }
                    
                    let res = dict?["result"] as! [String]
                    
                    if(res[0] == "ok"){
                        if(printMessage != nil){
                            print(printMessage ?? "Ok")
                        }
                    }
                    else{
                        client.close()
                        return false
                    }
                }
            case .failure(let error):
                print(error)
            }
            client.close()
        case .failure(let error):
            print(error)
        }
        i=i+1
        return true
    }
    
    /*Manda un messaggio di cui aspetta una risposta */
    func sendCmdReply(id: Int, method: String, params : [Any], printMessage : String?) -> Dictionary<String, Any>{
        var param = ""
        for p in params {
            if let n = p as? Int{
                param = param + "\(n),"
            } else {
                param = param + "\"\(p)\","
            }
        }
        param = param.substring(to: param.index(before: param.endIndex)) //Remove last comma
        self.closeConnection()
        switch client.connect(timeout: 2) {
        case .success:
            switch client.send(string: "{\"id\":\(id),\"method\":\"\(method)\",\"params\":[\(param)]}\r\n" ) {
            case .success:
                guard let data = client.read(1024*10) else { client.close(); return [:] }
                
                let response = String(bytes: data, encoding: .utf8)
                let dict = convertToDictionary(text: response!)
                
                if dict?["id"] as! Int == i{
                    client.close()
                    return dict!
                }
            case .failure(let error):
                print(error)
            }
            client.close()
        case .failure(let error):
            print(error)
        }
        i=i+1
        self.closeConnection()
        return [:]
    }

}
