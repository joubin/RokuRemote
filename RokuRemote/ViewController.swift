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
import SwiftColors

protocol CustomViewDelegate {
    func performKeyEquivalent(theEvent: NSEvent) -> Bool
    func keyDown(aEvent: NSEvent)
    func keyUp(aEvent: NSEvent)
    
}



    

class ViewController: NSViewController, CustomViewDelegate, GCDAsyncUdpSocketDelegate  {

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
        NSEvent.addLocalMonitorForEventsMatchingMask(.KeyDownMask) { (aEvent) -> NSEvent? in
            self.keyDown(aEvent)
            return aEvent
        }
        
        NSEvent.addLocalMonitorForEventsMatchingMask(.KeyUpMask) { (aEvent) -> NSEvent? in
            self.keyUp(aEvent)
            return aEvent
        }
        
        NSEvent.addLocalMonitorForEventsMatchingMask(.PeriodicMask){ (aEvent) -> NSEvent? in
            self.performKeyEquivalent(aEvent)
            return aEvent
        }
        setupConnection()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "getRokuList:",
            name: "getRokuList",
            object: nil)
    }
    
 
    override var representedObject: AnyObject? {
        didSet {
        }
    }
    
    override func performKeyEquivalent(theEvent: NSEvent) -> Bool {
        return true
    }
    
    override func keyUp(theEvent: NSEvent) {
        print("key up")
    }
    
    override func keyDown(theEvent:NSEvent) {
        print(theEvent)
        if !self.isHighLighted{
            return
        }
        let str = theEvent.characters!
        let decodedString = str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    
        setRequest(getKeyboardTypeing(decodedString!))

    }
    
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

        self.view.window?.titleVisibility = NSWindowTitleVisibility.Hidden
        self.view.window?.standardWindowButton(NSWindowButton.MiniaturizeButton)?.hidden = true
        self.view.window?.standardWindowButton(NSWindowButton.ZoomButton)?.hidden = true
        self.view.window?.title = "Lola"
        self.view.window?.backgroundColor = NSColor.blackColor()
        preferredContentSize = self.view.fittingSize
        self.view.window!.titleVisibility = NSWindowTitleVisibility.Hidden;
        self.view.window!.titlebarAppearsTransparent = true
        self.view.window!.styleMask |= NSFullSizeContentViewWindowMask
        self.view.window!.movableByWindowBackground  = true
        self.view.window!.maxSize = self.view.frame.size
        self.view.window!.minSize = self.view.frame.size
//        self.nextResponder = super.nextResponder  //insert self into the Responder chain
        
        let gradient = CAGradientLayer()
        gradient.frame = self.view.bounds
        let top: NSColor = NSColor(hexString: "#C644FC")!
        let bottom: NSColor = NSColor(hexString: "#5856D6")!
        gradient.colors = [top.CGColor, bottom.CGColor]
        self.view.layer?.insertSublayer(gradient as CALayer, atIndex: 0)
        
        self.label.textColor = NSColor.whiteColor()
        
    }

    func setViewToTheme(){
        let pstyle = NSMutableParagraphStyle()
//        pstyle.alignment = NSAlignmen
        
        enter.attributedTitle = NSAttributedString(string: "OK", attributes: [ NSForegroundColorAttributeName : NSColor.whiteColor(), NSParagraphStyleAttributeName : pstyle, NSFontAttributeName : NSFont.systemFontOfSize(30.0)])
    }
    
    func setupConnection(){

        let data = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: roku:ecp\r\nUSER-AGENT: iOS UPnP/1.1 TestApp/1.0\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)
        ssdpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        ssdpSocket.sendData(data, toHost: ssdpAddres, port: ssdpPort, withTimeout: 1, tag: 0)
        do {
            try ssdpSocket.bindToPort(ssdpPort)
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
            url = getButten("Play")
        }else if sender as! NSObject == rewind{
            url = getButten("Rev")
        }else if sender as! NSObject == forward{
            url = getButten("Fwd")
        }else if sender as! NSObject == home{
            url = getButten("Home")
        }else if sender as! NSObject == down{
            url = getButten("Down")
        }else if sender as! NSObject == up{
            url = getButten("Up")
        }else if sender as! NSObject == right{
            url = getButten("Right")
        }else if sender as! NSObject == left{
            url = getButten("Left")
        }else if sender as! NSObject == back{
            url = getButten("Back")
        }else if sender as! NSObject == enter{
            url = getButten("Select")
        }else{
            return
        }
        setRequest(url)
    }
    
    func setRequest(url:NSURL){
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"

        NSURLSession.sharedSession().dataTaskWithRequest(request).resume()
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
        GCDAsyncUdpSocket.getHost(&host, port: &port1, fromAddress: address)
        
        let gotdata: NSString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
        
        if(gotdata.containsString("Roku")){
            let lines = (gotdata as String).componentsSeparatedByString("\n")
            for i in lines{
                if i.rangeOfString("LOCATION") != nil{
                    let str:String =  i.componentsSeparatedByString("LOCATION:")[1].lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).stringByReplacingOccurrencesOfString("\r", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                    ViewController.rokuList.append(str)
                }
            }
        }
        let rokuImage = NSImage(named: "roku")
        for tmpView in self.view.subviews{
            if tmpView.isKindOfClass(NSImageView) {
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
                image.action = "imageClicked"
                image.enabled = true
                image.acceptsTouchEvents = true
                
                let tapGestureRecognizer = NSGestureRecognizer(target:self, action:Selector("imageTapped:"))
                image.addGestureRecognizer(tapGestureRecognizer)
                self.view.addSubview(image)
                let keyVal:String = String(stringInterpolationSegment: image.frame.origin.x) + " " + String(stringInterpolationSegment: image.frame.origin.y)
                ViewController.rokuListRoku.updateValue(str, forKey: keyVal)
             yPosition = yPosition - 22
            }
        stopRotatingView()

        ssdpSocket.close()
    }
    
    override func mouseDown(theEvent: NSEvent) {
        _ = NSNumberFormatter()
        for (k,v) in ViewController.rokuListRoku{
            var xy = k.characters.split{$0 == " "}.map { String($0) }.map{String($0)}
            let x = xy[0]
            let y = xy[1]

            var diffX:Float = Float(theEvent.locationInWindow.x).distanceTo(Float((x as NSString).floatValue))
            var diffY:Float = Float(theEvent.locationInWindow.y).distanceTo(Float((y as NSString).floatValue))
            diffX = Float.abs(diffX)
            diffY = Float.abs(diffY)
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
        dispatch_async(dispatch_get_main_queue(), {
            if self.isHighLighted == false{
                sender.highlight(true)
                self.isHighLighted = true
                
            }else{
                sender.highlight(false)
                self.isHighLighted = false
            }
        });
    }
    
    func rotateView() {
        if refreshButton.layer!.animationForKey("rotation") == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            
            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = Float(M_PI * 2.0)
            rotationAnimation.duration = 1
            rotationAnimation.repeatCount = Float.infinity
            let width = refreshButton.frame.width
            let height = refreshButton.frame.height
            let xPoint = refreshButton.layer?.position.x
            let yPoint = refreshButton.layer?.position.y
            let xCenter = xPoint!-(width/2)
            let yCenter = yPoint!-(height/2)
            _ = CGPointMake(xCenter, yCenter)
            refreshButton.layer?.anchorPoint = CGPointMake(0.5, 0.5)
            refreshButton.layer!.addAnimation(rotationAnimation, forKey: "rotation")
        }

    }
    
    func stopRotatingView() {
        print("finish:")
        if refreshButton.layer!.animationForKey("rotation") != nil {
            refreshButton.layer!.removeAnimationForKey("rotation")     }
    }

}

