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
}

class Yeelight {
    
    var proprieties : Proprieties = Proprieties() ;
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
    
    func updateProprieties(){
        let d = sendCmdReply(id: i, method: "get_prop", params: ["power", "bright", "ct", "rgb", "hue", "sat", "color_mode", "flowing", "dalayoff", "flow_params", "music_on", "name"], printMessage: "getProprieties")
        let res = d["result"] as! [Any]
        if(res[0] as! String == "on"){
            proprieties.power = true
        } else {
            proprieties.power = false
        }
        proprieties.bright = Int((res[1] as! NSString).intValue)
        proprieties.ct = Int((res[2] as! NSString).intValue)
        proprieties.rgb = Int((res[3] as! NSString).intValue)
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
        return [:]
    }

}
/*

func spegni(){
    switch client.connect(timeout: 3) {
    case .success:
        switch client.send(string: "{\"id\":\(i),\"method\":\"set_power\",\"params\":[\"off\", \"smooth\", 500]}\r\n" ) {
        case .success:
            i=i+1
            guard let data = client.read(1024*10) else { return }
            
            if let response = String(bytes: data, encoding: .utf8) {
                print(response)
            }
        case .failure(let error):
            print(error)
        }
        client.close()
    case .failure(let error):
        print(error)
    }
}

func isPower() -> Bool {
    switch client.connect(timeout: 3) {
    case .success:
        switch client.send(string: "{\"id\":\(i),\"method\":\"get_prop\",\"params\":[\"power\"]}\r\n" ) {
        case .success:
            i=i+1
            guard let data = client.read(1024*10) else { return false;}
            
            if let response = String(bytes: data, encoding: .utf8) {
                guard let data : Data = response.data(using: .utf8) else {return false}
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                let d = json as! [String: Any]
                let p = d["result"] as! [String]
                if(p[0] == "on"){
                    return true;
                }
                else{
                    return false;
                }
            }
        case .failure(let error):
            print(error)
        }
        client.close()
    case .failure(let error):
        print(error)
    }
    return false
}

func getBright() -> Int {
    switch client.connect(timeout: 3) {
    case .success:
        switch client.send(string: "{\"id\":\(i),\"method\":\"get_prop\",\"params\":[\"bright\"]}\r\n" ) {
        case .success:
            i=i+1
            guard let data = client.read(1024*10) else { return 0}
            
            if let response = String(bytes: data, encoding: .utf8) {
                guard let data : Data = response.data(using: .utf8) else {return 0}
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                let d = json as! [String: Any]
                guard let p = d["result"] as? [Int] else {return 0}
                return p[0]
            }
        case .failure(let error):
            print(error)
        }
        client.close()
    case .failure(let error):
        print(error)
    }
    return 0
}*/
