//
//  NSControlExtensions.swift
//  Markit
//
//  Created by patr0nus on 2018/6/7.
//

import Foundation


let ControlExtensions: [String: [ClassExtension]] = [
    NSControl.self.className(): [
        .contentPropertyName(#keyPath(NSControl.stringValue)),
        
        .propertySetter(.init(propertyName: #keyPath(NSControl.action)) { (_, target, propertyValue) throws in
            (target as! NSControl).action = (propertyValue as! Selector)
        })
    ]
]

