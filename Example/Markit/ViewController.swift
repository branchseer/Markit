//
//  ViewController.swift
//  Markit
//
//  Created by patr0nus on 05/18/2018.
//  Copyright (c) 2018 patr0nus. All rights reserved.
//

import Cocoa
import Markit

class ViewController: NSViewController {

    private static let builder = try! MarkitCompiler.shared.compile(xml: .resource("TestView")!)
    
    @objc dynamic private var label: NSTextField!
    @objc dynamic private var aButton: NSButton!

    @objc dynamic private let texts: [String: String] = [
        "labelText": "Greetings from ViewController"
    ]
    
    var i = 0
    @objc private func buttonClicked() {
        label.stringValue = String(i)
        i += 1
    }

    override func loadView() {
        try! ViewController.builder.build(withOwner: self)
        view.frame.size = NSSize(width: 200, height: 200)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    }
}

