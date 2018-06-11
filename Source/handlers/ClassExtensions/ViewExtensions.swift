//
//  NSViewExtensions.swift
//  Markit
//
//  Created by patr0nus on 2018/6/7.
//

import Foundation

#if canImport(UIKit)
import UIKit
fileprivate typealias View = UIView
fileprivate typealias LayoutGuide = UILayoutGuide
#elseif canImport(Cocoa)
import Cocoa
fileprivate typealias View = NSView
fileprivate typealias LayoutGuide = NSLayoutGuide
#endif


let ViewExtentions: [String: [ClassExtension]] = [
    View.self.className(): [
        .contentPropertyName(#keyPath(View.subviews)),
        .property(.init(name: #keyPath(View.layoutGuides), type: .array(elementClassName: nil))),
        .propertySetter(.init(propertyName: #keyPath(NSView.layoutGuides)) { (_, target, propertyValue) throws in
            guard let layoutGuides = propertyValue as? [LayoutGuide] else {
                throw Compiler.Error.unexpectedPropertyValue(propertyValue, property: #keyPath(NSView.layoutGuides), className: View.self.className())
            }
            let theView = target as! View
            for layoutGuide in layoutGuides {
                theView.addLayoutGuide(layoutGuide)
            }
        }),
    ]
]
