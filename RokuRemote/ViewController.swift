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

class ViewController: NSViewController, GCDAsyncUdpSocketDelegate {

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
    @IBOutlet weak var window: NSWindow!

    static var rokuList = [String]()
    static let sharedInstance = ViewController()

    var ssdpSocket:GCDAsyncUdpSocket!
    var ssdpAddres          = "239.255.255.250"
    var ssdpPort:UInt16     = 1900
    var rokuIP = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setupConnection()

        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "getRokuList:",
            name: "getRokuList",
            object: nil)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        setViewToTheme()

        window = self.view.window
        self.view.window?.title = "Lola"
        self.view.window?.backgroundColor = NSColor.blackColor()
        preferredContentSize = self.view.fittingSize
        self.view.window!.titleVisibility = NSWindowTitleVisibility.Hidden;
        self.view.window!.titlebarAppearsTransparent = true
        self.view.window!.styleMask |= NSFullSizeContentViewWindowMask
        self.view.window!.movableByWindowBackground  = true
        self.view.window!.maxSize = self.view.frame.size
        self.view.window!.minSize = self.view.frame.size
        self.nextResponder = super.nextResponder  //insert self into the Responder chain
        
        var gradient = CAGradientLayer()
        gradient.frame = self.view.bounds
        let top: NSColor = NSColor(hexString: "#FF5E3A")!
        let bottom: NSColor = NSColor(hexString: "#FF2A68")!
        gradient.colors = [top.CGColor, bottom.CGColor]
        self.view.layer?.insertSublayer(gradient as CALayer, atIndex: 0)
    }

    func setViewToTheme(){
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .CenterTextAlignment
        
        enter.attributedTitle = NSAttributedString(string: "OK", attributes: [ NSForegroundColorAttributeName : NSColor.whiteColor(), NSParagraphStyleAttributeName : pstyle, NSFontAttributeName : NSFont.systemFontOfSize(30.0)])
    }
    
    func setupConnection(){
        //send M-Search
        let data = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: roku:ecp\r\nUSER-AGENT: iOS UPnP/1.1 TestApp/1.0\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)
    
        ssdpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        ssdpSocket.sendData(data, toHost: ssdpAddres, port: ssdpPort, withTimeout: 1, tag: 0)
        
        ssdpSocket.bindToPort(ssdpPort, error: nil)
        ssdpSocket.joinMulticastGroup(ssdpAddres, error: nil)
        ssdpSocket.beginReceiving(nil)
    }
    
    @IBAction func buttonPressed(sender: AnyObject) {
        var url:NSURL
        if sender as! NSObject == play{
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
        
        var request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"

        NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler:nil).resume()
    }

    func udpSocket(sock: GCDAsyncUdpSocket!, didConnectToAddress address: NSData!) {
        println("didConnectToAddress");
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didNotConnect error: NSError!) {
        println("didNotConnect \(error)")
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didSendDataWithTag tag: Int) {
        println("didSendDataWithTag")
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didNotSendDataWithTag tag: Int, dueToError error: NSError!) {
        println("didNotSendDataWithTag")
    }
    
    func getButten(action:String) -> NSURL{
        var str:String = self.label.stringValue + "keypress/"+action
        return NSURL(string:  str)!
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        var host: NSString?
        var port1: UInt16 = 0
        GCDAsyncUdpSocket.getHost(&host, port: &port1, fromAddress: address)
        
        let gotdata: NSString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
        
        if(gotdata.containsString("Roku")){
            var lines = (gotdata as! String).componentsSeparatedByString("\n")
            for i in lines{
                if i.rangeOfString("LOCATION") != nil{
                    var str:String =  i.componentsSeparatedByString("LOCATION:")[1].lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).stringByReplacingOccurrencesOfString("\r", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                    ViewController.rokuList.append( str)
                    if(label.stringValue == ""){
                        label.stringValue = str
                        label.alignment = NSTextAlignment.CenterTextAlignment
                    }
                    
                }
            }
           
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
    
    @IBAction func showRokus(sender: AnyObject) {
        println("showing")
    }
    
    func resize() {
        var windowFrame = self.view.window?.frame
        let oldWidth = windowFrame!.size.width
        let oldHeight = windowFrame!.size.height
        let toAdd = CGFloat(130)
        let newHeight = oldHeight + toAdd
        windowFrame!.size = NSMakeSize(oldWidth, newHeight)
            window.setFrame(windowFrame!, display: true)
    }
    

    func getRokuList() -> [String]{
        return ViewController.rokuList
    }
    
}

