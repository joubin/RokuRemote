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


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
//        window?.standardWindowButton(NSWindowButton.FullScreenButton)?.
       

    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }



    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}

