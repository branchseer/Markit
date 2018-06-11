//
//  AppDelegate.swift
//  Markit
//
//  Created by patr0nus on 05/18/2018.
//  Copyright (c) 2018 patr0nus. All rights reserved.
//

import Cocoa
import Markit

@objc class MyView: NSView {
    
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    let window = NSWindow(contentViewController: ViewController())
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.makeKeyAndOrderFront(self)
        window.center()
        
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
}

