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
    var IP: String;
    var port : Int;
    var i = 1; //Message ID, increase by one each message sent
    
    var  client : Socket?;
    
    init(ip:String){
        self.IP = ip;
        self.port = 55443;
        do{
            client = try Socket.create(); // It creates a inet socket, with stream type and using TCP
            try client?.connect(to: self.IP, port: Int32(self.port))
            client?.close()
        } catch (let error){
            print(error)
            print("Error: socket cannot be created or can't connect. Is the bulb connected?")
        }
        self.updateProprieties()
    }
    
    init(){
        self.IP = "";
        self.port = 0;
        let addr = discover();
        if(addr != nil){
            let parts = addr!.split(separator: ":").map(String.init)
            
            self.IP = parts.first!
            self.port = Int(parts.last!)!
            do {
                client = try Socket.create();
                try client?.connect(to: self.IP, port: Int32(self.port))
            }catch(let e){
                print("Error: socket cannot be created"+e.localizedDescription);
            }
        }
        print("Bulb found: "+self.IP+":"+String(self.port))
        if(self.IP != ""){
            self.updateProprieties()
        }
    }
    
    func discover() -> String?{
        do{
            let broadcast = try Socket.create(family: Socket.ProtocolFamily.inet, type: Socket.SocketType.datagram, proto: Socket.SocketProtocol.udp)
            try broadcast.udpBroadcast(enable: true)
            let discover_message = """
                M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1982\r\nMAN: "ssdp:discover"\r\nST: wifi_bulb
                """
            let discover_data = discover_message.data(using: String.Encoding.utf8)
            try broadcast.write(from: discover_data!, to: Socket.createAddress(for: "239.255.255.250", on: 1982)!)
            
            var data = Data()
            try broadcast.setReadTimeout(value: 1000)
            let r = try broadcast.readDatagram(into: &data);
            if(r.bytesRead > 0){
                let s = String(data: data, encoding: String.Encoding.utf8)!
                let rows = s.split(separator: "\r\n").map(String.init)
                for s in rows {
                    if(s.contains("Location")){
                        return String(s.suffix(19));
                    }
                }
                print(s)
            }else{
                print("The bulb not reply. Is it off?")
                return nil;
            }
            
        } catch(let error){
            print("Unable to create a socket: ")
            print(error)
        }
        return nil;
    }
    func toggle(){
        sendCmdReply(id: getAndIncr(), method: "toggle", params: [], hasReply: false)
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
        let _ = sendCmdReply(id: getAndIncr(), method: "set_bright", params: [bright, "smooth", 500], hasReply: false)
        self.proprieties.bright = bright
    }
    
    func switchOn(){
        let _ = sendCmdReply(id: getAndIncr(), method: "set_power", params: ["on", "smooth", 500], hasReply: false)
        proprieties.power = true
    }
    func switchOff(){
        let _ = sendCmdReply(id: getAndIncr(), method: "set_power", params: ["on", "smooth", 500], hasReply: false)
        proprieties.power = true
    }
    
    func set_color(r : Int, g : Int, b : Int){
        if(!self.proprieties.power){
            _ = self.switchOn()
        }
        let _ = sendCmdReply(id: i, method: "set_rgb", params: [r*65536+g*256+b, "smooth", 500], hasReply: false)
    }
    
    func closeConnection(){
        client?.close()
    }
    func connect(){
        do{
            try client?.connect(to: self.IP, port: Int32(self.port))
        } catch(let e){
            print("Cannot connect - "+e.localizedDescription);
        }
    }
    func updateProprieties(){
        let dict = sendCmdReply(id: i, method: "get_prop", params: ["power", "bright", "ct", "rgb", "hue", "sat", "color_mode", "flowing", "delayoff", "flow_params", "music_on", "name"], hasReply: true)
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
    
    func sendCmdReply(id: Int, method: String, params: [Any], hasReply: Bool) -> Dictionary<String, Any>{
        let params_string = joinArrayWithComma(params)
        
        let cmd = "{\"id\":\(id),\"method\":\"\(method)\",\"params\":[\(params_string)]}\r\n";
        print("SENDING: "+cmd)
        do {
            try client?.write(from: cmd)
        } catch{
            print("Cannot communicate with the bulb. Writing on socket fails")
        }
        
        if(hasReply){
            return readReply()
        } else {
            return readReply();
        }
    }
    
    func joinArrayWithComma(_ array:[Any]) -> String {
        return array.flatMap { (value) -> String? in
            return (value is Int ? "\(value)" : ("\"\(value)\""))
            }.joined(separator: ",")
    }
    
    func readReply() -> Dictionary<String, Any>{
        var data = Data()
        /*
         TODO:
         Here there is a problem. The bulb reply each command sent with an ack message as `{"id":2, "result":["ok"]}`
         Moreover, because the connection remains opened, the bulb send also another message that is read with the next message (i.e. when the read is called again) and this is a notification message as `{"method":"props","params":{"bright":66}}`.
         The problem is that, when the next read() reads a data, the data are like `{...}\r\n{...}\r\n` so the JSON parser fails and the nil value is returned.
         So, this code needs to integrate a method to distinguish between a correct reply message {...} and a double JSON message, where one of the two JSON is an repetition and can be ignored.
         */
        do {
            try client?.read(into: &data); /*Sometimes here only the "bad" JSON in read and this creates
             an error on json c function */
            let s = String(data: data, encoding: String.Encoding.utf8)!
            let cs = (s as NSString).utf8String
            print("REPLY: "+s);
            if let json_r = get_one_json(UnsafeMutablePointer<Int8>(mutating: cs), Int32(s.count)) {
                let s1 = String(cString: json_r)
                print("STRING CLEANED")
                print(s1)
                
                let d = convertToDictionary(text: s1)
                if(d == nil){
                    return [:];
                } else {
                    return d!;
                }
            } else {
                return readReply()
            }
        } catch( _){
            return [:]
        }
    }
    
    func getAndIncr() -> Int{
        i=i+1;
        return i;
    }
}
