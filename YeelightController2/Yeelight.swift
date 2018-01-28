//
//  Yeelight.swift
//  YeelightController2
//
//  Created by Alessandro Pagiaro on 27/01/2018.
//  Copyright © 2018 Alessandro Pagiaro. All rights reserved.
//

import Foundation
import Socket

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
    var i = 1; //Message ID, increase by one each message sent
    
    var  client : Socket?;
    
    init(ip:String){
        self.IP = ip;
        self.port = 55443;
        do{
            client = try Socket.create(); // It creates a inet socket, with stream type and using TCP
            try client?.connect(to: self.IP, port: Int32(self.port))
        } catch (let error){
            print(error)
            print("Error: socket cannot be created or can't connect. Is the bulb connected?")
        }
        self.updateProprieties()
    }
    
    func toggle(){
        sendCmdReply(id: getAndIncr(), method: "toggle", params: [])
        self.proprieties.power = !self.proprieties.power
    }
    func setBrightness(value: Int) {
        var bright = value;
        if(bright < 1){
            bright = 1;
        }
        if(bright > 100){
            bright = 100;
        }
        let _ = sendCmdReply(id: getAndIncr(), method: "set_bright", params: [bright, "smooth", 500])
        self.proprieties.bright = bright
    }
    
    func switchOn(){
        sendCmdReply(id: getAndIncr(), method: "set_power", params: ["on", "smooth", 500])
        proprieties.power = true
    }
    func switchOff(){
        sendCmdReply(id: getAndIncr(), method: "set_power", params: ["on", "smooth", 500])
        proprieties.power = true
    }
    
    func set_color(r : Int, g : Int, b : Int){
        if(!self.proprieties.power){
            _ = self.switchOn()
        }
        sendCmdReply(id: i, method: "set_rgb", params: [r*65536+g*256+b, "smooth", 500])
    }
    
    func closeConnection(){
        do {
            try client?.close()
        }catch(let _){
            return;
        }
    }
    
    func updateProprieties(){
        let dict = sendCmdReply(id: i, method: "get_prop", params: ["power", "bright", "ct", "rgb", "hue", "sat", "color_mode", "flowing", "delayoff", "flow_params", "music_on", "name"] )
        let res = dict["result"] as! [Any]
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
    
    func sendCmdReply(id: Int, method: String, params: [Any]) -> Dictionary<String, Any>{
        var params_string = "";
        for p in params {
            if let n = p as? Int{
                params_string = params_string + "\(n),";
            } else {
                params_string = params_string + "\"\(p)\",";
            }
        }
        if(params.count > 0){
            params_string.remove(at: params_string.index(before: params_string.endIndex)) //Remove last commad
        }
        
        let cmd = "{\"id\":\(id),\"method\":\"\(method)\",\"params\":[\(params_string)]}\r\n";
        print(cmd)
        do {
            try client?.write(from: cmd)
        } catch{
            print("Cannot communicate with the bulb. Writing on socket fails")
        }
        
        var data = Data()
         /*
         TODO:
         Here there is a problem. The bulb reply each command sent with an ack message as `{"id":2, "result":["ok"]}`
         Moreover, because the connection remains opened, the bulb send also another message that is read with the next message (i.e. when the read is called again) and this is a notification message as `{"method":"props","params":{"bright":66}}`.
         The problem is that, when the next read() reads a data, the data are like `{...}{...}` so the JSON parser fails and the nil value is returned.
         So, this code needs to integrate a method to distinguish between a correct reply message {...} and a double JSON message, where one of the two JSON is an repetition and can be ignored. 
        */
        do {
            try client?.read(into: &data);
            let s = String(data: data, encoding: String.Encoding.utf8)!
            print(s)
            let dict = convertToDictionary(text: s);
            return dict!
        } catch(let error){
            return [:]
        }
    }
    
    func getAndIncr() -> Int{
        i=i+1;
        return i;
    }
}
