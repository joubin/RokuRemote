//
//  ViewController.swift
//  RokuRemote
//
//  Created by Joubin Jabbari on 9/2/15.
//  Copyright (c) 2015 Joubin Jabbari. All rights reserved.
//

import CocoaAsyncSocket
import Cocoa
import Foundation





class ViewController: NSViewController, GCDAsyncUdpSocketDelegate  {
    
    var yPosition:Int = 215
    var xPosition:Int = 220
    var positionDefault:Int = 215
    
    
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var keyboard: NSButton!
    @IBOutlet weak var left: NSButton!
    @IBOutlet weak var right: NSButton!
    @IBOutlet weak var up: NSButton!
    @IBOutlet weak var down: NSButton!
    @IBOutlet weak var play: NSButton!
    @IBOutlet weak var forward: NSButton!
    @IBOutlet weak var rewind: NSButton!
    @IBOutlet weak var home: NSButton!
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var back: NSButton!
    @IBOutlet weak var enter: NSButton!
    
    var isHighLighted = false
    static var rokuList = [String]()
    static var rokuListRoku = Dictionary<String, String>()
    static let sharedInstance = ViewController()
    
    var ssdpSocket:GCDAsyncUdpSocket!
    var ssdpAddres          = "239.255.255.250"
    var ssdpPort:UInt16     = 1900
    var rokuIP = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (aEvent) -> NSEvent? in
            self.keyDown(with: aEvent)
            return aEvent
        }
        
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (aEvent) -> NSEvent? in
            self.keyUp(with: aEvent)
            return aEvent
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (aEvent) -> NSEvent? in
            self.performKeyEquivalent(with: aEvent)
            return aEvent
        }
        setupConnection()
        NotificationCenter.default.addObserver(
            self,
            selector: Selector(("getRokuList:")),
            name: NSNotification.Name(rawValue: "getRokuList"),
            object: nil)
    }
    
    
    override var representedObject: Any? {
        didSet {
        }
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        return true
    }
    
    
    
    override func keyDown(with theEvent: NSEvent) {
        print(theEvent)
        if !self.isHighLighted{
            return
        }
        let str = theEvent.characters!
        let nsstr = str as NSString
        let decodedString = nsstr.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlHostAllowed)
        
        
        setRequest(url: getKeyboardTypeing(action: decodedString!))
        
    }
    //
    //    override func keyUp(theEvent: NSEvent) {
    //        print("key up")
    //    }
    //
    //    override func keyDown(theEvent:NSEvent) {
    //        print(theEvent)
    //        if !self.isHighLighted{
    //            return
    //        }
    //        let str = theEvent.characters!
    //        let decodedString = str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    //
    //        setRequest(getKeyboardTypeing(decodedString!))
    //
    //    }
    //
    override func becomeFirstResponder() -> Bool {
        return true;
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        setViewToTheme()
        self.becomeFirstResponder()
        
        self.view.window?.titleVisibility = NSWindow.TitleVisibility.hidden
        self.view.window?.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden = true
        self.view.window?.standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
        self.view.window?.title = "Lola"
        self.view.window?.backgroundColor = NSColor.black
        preferredContentSize = self.view.fittingSize
        self.view.window!.titleVisibility = NSWindow.TitleVisibility.hidden;
        self.view.window!.titlebarAppearsTransparent = true
        self.view.window?.styleMask.insert(.fullSizeContentView)
        self.view.window!.isMovableByWindowBackground  = true
        self.view.window!.maxSize = self.view.frame.size
        self.view.window!.minSize = self.view.frame.size
        //        self.nextResponder = super.nextResponder  //insert self into the Responder chain
        
        let gradient = CAGradientLayer()
        gradient.frame = self.view.bounds
        
        let top: NSColor = NSColor(hexString: "#C644FC")
        let bottom: NSColor = NSColor(hexString: "#5856D6")
        gradient.colors = [top.cgColor, bottom.cgColor]
        self.view.layer?.insertSublayer(gradient as CALayer, at: 0)
        
        self.label.textColor = NSColor.white
        
    }
    
    func setViewToTheme(){
        let pstyle = NSMutableParagraphStyle()
        //        pstyle.alignment = NSAlignmen
        
        enter.attributedTitle = NSAttributedString(string: "OK", attributes: [ kCTForegroundColorAttributeName as NSAttributedStringKey : NSColor.white, kCTParagraphStyleAttributeName as NSAttributedStringKey : pstyle, kCTFontAttributeName as NSAttributedStringKey : NSFont.systemFont(ofSize: 30.0)])
    }
    
    func setupConnection(){
        
        let data = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: roku:ecp\r\nUSER-AGENT: iOS UPnP/1.1 TestApp/1.0\r\n\r\n".data(using: String.Encoding.utf8)
        ssdpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        ssdpSocket.send(data!, toHost: ssdpAddres, port: ssdpPort, withTimeout: 1, tag: 0)
        do {
            try ssdpSocket.bind(toPort: ssdpPort)
        } catch _ {
        }
        do {
            try ssdpSocket.joinMulticastGroup(ssdpAddres)
        } catch _ {
        }
        do {
            try ssdpSocket.beginReceiving()
        } catch _ {
        }
    }
    
    @IBAction func buttonPressed(sender: AnyObject) {
        var url:NSURL
        if self.isHighLighted{
            return
        }else if sender as! NSObject == play{
            url = getButten(action: "Play")
        }else if sender as! NSObject == rewind{
            url = getButten(action: "Rev")
        }else if sender as! NSObject == forward{
            url = getButten(action: "Fwd")
        }else if sender as! NSObject == home{
            url = getButten(action: "Home")
        }else if sender as! NSObject == down{
            url = getButten(action: "Down")
        }else if sender as! NSObject == up{
            url = getButten(action: "Up")
        }else if sender as! NSObject == right{
            url = getButten(action: "Right")
        }else if sender as! NSObject == left{
            url = getButten(action: "Left")
        }else if sender as! NSObject == back{
            url = getButten(action: "Back")
        }else if sender as! NSObject == enter{
            url = getButten(action: "Select")
        }else{
            return
        }
        setRequest(url: url)
    }
    
    func setRequest(url:NSURL){
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request as URLRequest).resume()
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didConnectToAddress address: NSData!) {
        
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didNotConnect error: NSError!) {
        
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didSendDataWithTag tag: Int) {
        
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didNotSendDataWithTag tag: Int, dueToError error: NSError!) {
        
    }
    
    func getButten(action:String) -> NSURL{
        let str:String = self.label.stringValue + "keypress/"+action
        return NSURL(string:  str)!
    }
    
    func getKeyboardTypeing(action:String)-> NSURL{
        let myAction:String
        if action == "%7F"{
            myAction = "keypress/Backspace"
        }else{
            myAction = "keypress/Lit_"+action
        }
        let str:String = self.label.stringValue + myAction
        return NSURL(string:  str)!
    }
    
    @IBAction func refreshRokuList(sender: AnyObject) {
        setupConnection()
        rotateView()
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        var host: NSString?
        var port1: UInt16 = 0
        GCDAsyncUdpSocket.getHost(&host, port: &port1, fromAddress: address as Data)
        
        let gotdata: NSString = NSString(data: data! as Data, encoding: String.Encoding.utf8.rawValue)!
        
        if(gotdata.contains("Roku")){
            let lines = (gotdata as String).components(separatedBy: "\n")
            for i in lines{
                if i.range(of: "LOCATION") != nil{
                    let str:String = i.components(separatedBy: "LOCATION:")[1].lowercased().trimmingCharacters(in: NSCharacterSet.whitespaces).replacingOccurrences(of: "\r", with: "", options: NSString.CompareOptions.literal, range: nil)
                    ViewController.rokuList.append(str)
                }
            }
        }
        let rokuImage = NSImage(named: NSImage.Name(rawValue: "roku"))
        for tmpView in self.view.subviews{
            if tmpView.isKind(of: NSImageView.self){
                let rokuImageView = tmpView as! NSImageView
                if rokuImageView.image == rokuImage{
                    tmpView.removeFromSuperview()
                }
            }
        }
        yPosition = positionDefault
        for str in ViewController.rokuList{
            let image:NSImageView = NSImageView(frame: NSRect(origin: CGPoint(x: xPosition, y: yPosition), size: CGSize(width: 20, height: 20)))
            image.image = rokuImage
            
            image.toolTip = str
            image.action = Selector(("imageClicked"))
            image.isEnabled = true
            image.acceptsTouchEvents = true
            
            let tapGestureRecognizer = NSGestureRecognizer(target:self, action:Selector(("imageTapped:")))
            image.addGestureRecognizer(tapGestureRecognizer)
            self.view.addSubview(image)
            let keyVal:String = String(stringInterpolationSegment: image.frame.origin.x) + " " + String(stringInterpolationSegment: image.frame.origin.y)
            ViewController.rokuListRoku.updateValue(str, forKey: keyVal)
            yPosition = yPosition - 22
        }
        ssdpSocket.close()
        
        stopRotatingView()
        
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        _ = NumberFormatter()
        for (k,v) in ViewController.rokuListRoku{
            var xy = k.characters.split{$0 == " "}.map { String($0) }.map{String($0)}
            let x = xy[0]
            let y = xy[1]
            
            var diffX:Float = Float(theEvent.locationInWindow.x).distance(to: Float((x as NSString).floatValue))
            var diffY:Float = Float(theEvent.locationInWindow.y).distance(to: Float((y as NSString).floatValue))
            diffX = abs(diffX)
            diffY = abs(diffY)
            if diffX <= 20 && diffX >= 0 && diffY <= 20 && diffY >= 0 {
                self.label.stringValue = v
            }else{
                
            }
        }
    }
    
    func imageTapped(img: AnyObject){
        
    }
    
    func getRokuList() -> [String]{
        return ViewController.rokuList
    }
    
    @IBAction func keyBoardPressed(sender: AnyObject) {
        DispatchQueue.main.async {
            if self.isHighLighted == false{
                sender.highlight(true)
                self.isHighLighted = true
                
            }else{
                sender.highlight(false)
                self.isHighLighted = false
            }
        }
    }
    
    func rotateView() {
        if refreshButton.layer!.animation(forKey: "rotation") == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            
            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = Float(Double.pi * 2.0)
            rotationAnimation.duration = 1
            rotationAnimation.repeatCount = Float.infinity
            let width = refreshButton.frame.width
            let height = refreshButton.frame.height
            let xPoint = refreshButton.layer?.position.x
            let yPoint = refreshButton.layer?.position.y
            let xCenter = xPoint!-(width/2)
            let yCenter = yPoint!-(height/2)
            _ = CGPoint(x: xCenter, y: yCenter)
            
            //Use above later
            refreshButton.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            refreshButton.layer!.add(rotationAnimation, forKey: "rotation")
        }
        
    }
    
    func stopRotatingView() {
        print("finish:")
        if refreshButton.layer!.animation(forKey: "rotation") != nil {
            refreshButton.layer!.removeAnimation(forKey: "rotation")     }
    }
    
}

extension NSColor {
    convenience init(hexString: String) {
        var hex = hexString.hasPrefix("#") ? String(hexString.characters.dropFirst()) : hexString
        
        guard hex.characters.count == 3 || hex.characters.count == 6 else {
            self.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
            return
        }
        
        if hex.characters.count == 3 {
            for (index, char) in hex.characters.enumerated() {
                hex.insert(char, at: hex.characters.index(hex.startIndex, offsetBy: index * 2))
            }
        }
        
        let number = Int(hex, radix: 16)!
        let red = CGFloat((number >> 16) & 0xFF) / 255.0
        let green = CGFloat((number >> 8) & 0xFF) / 255.0
        let blue = CGFloat(number & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
