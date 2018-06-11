//
//  CaseConvertor.swift
//  Markit
//
//  Created by patr0nus on 2018/6/6.
//

import Foundation

fileprivate let cNSButtonBezelStyle = "NSButton.BezelStyle"
fileprivate let cNSButtonType = "NSButton.ButtonType"

let NSButtonExtentions: [String: [ClassExtension]] = [
    NSButton.self.className(): [
        .contentPropertyName(#keyPath(NSButton.title)),
        .property(.init(name: #keyPath(NSButton.bezelStyle), type: .singleValue(className: cNSButtonBezelStyle))),
        
        .property(.init(name: "buttonType", type: .singleValue(className: cNSButtonType))),
        .propertySetter(.init(propertyName: "buttonType") { (_, target, propertyValue) throws in
            (target as! NSButton).setButtonType(propertyValue as! NSButton.ButtonType)
        }),
    ],
    
    cNSButtonType: [
        .caseLiteralConvertor(type: NSButton.ButtonType.self, cases: [
            "accelerator": .accelerator,
            "momentaryPushIn": .momentaryPushIn,
            "momentaryChange": .momentaryChange,
            "momentaryLight": .momentaryLight,
            "multiLevelAccelerator": .multiLevelAccelerator,
            "onOff": .onOff,
            "pushOnPushOff": .pushOnPushOff
        ])
    ],
    
    cNSButtonBezelStyle: [
        .caseRawValueLiteralConvertor(type: NSButton.BezelStyle.self, cases: [
            "roundRect": .roundRect,
            "rounded": .rounded
        ])
    ]
]
