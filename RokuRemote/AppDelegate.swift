//
//  AppDelegate.swift
//  RokuRemote
//
//  Created by Joubin Jabbari on 9/2/15.
//  Copyright (c) 2015 Joubin Jabbari. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    let myNewWindow = NSWindow(contentRect: NSMakeRect(0,0,640,480), styleMask: NSBorderlessWindowMask, backing: NSBackingStoreType.Buffered, defer: false)


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        println("getting there")
        
        

    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    
    @IBAction func btnNewWindow(sender: AnyObject) {
        myNewWindow.opaque = false
        myNewWindow.movableByWindowBackground = true
        myNewWindow.backgroundColor = NSColor(hue: 0, saturation: 1, brightness: 0, alpha: 0.7)
        myNewWindow.makeKeyAndOrderFront(nil)
    }

}

