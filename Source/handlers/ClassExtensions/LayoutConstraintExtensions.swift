//
//  NSLayoutExtensions.swift
//  Markit
//
//  Created by patr0nus on 2018/6/7.
//

import Foundation

fileprivate let cNSLayoutAttribute = "NSLayoutConstraint.Attribute"
fileprivate let cNSLayoutRelation = "NSLayoutConstraint.Relation"


let LayoutConstraintExtensions: [String: [ClassExtension]] = [
    NSLayoutConstraint.self.className(): [
        .property(.init(name: #keyPath(NSLayoutConstraint.firstAttribute), type: .singleValue(className: cNSLayoutAttribute))),
        .property(.init(name: #keyPath(NSLayoutConstraint.secondAttribute), type: .singleValue(className: cNSLayoutAttribute))),
        .property(.init(name: #keyPath(NSLayoutConstraint.relation), type: .singleValue(className: cNSLayoutRelation))),
        .constructor(.init(
            requiredArguments: [
                #keyPath(NSLayoutConstraint.firstItem),
                #keyPath(NSLayoutConstraint.firstAttribute)
            ],
            optionalArguments: [
                #keyPath(NSLayoutConstraint.relation),
                #keyPath(NSLayoutConstraint.secondItem),
                #keyPath(NSLayoutConstraint.secondAttribute),
                #keyPath(NSLayoutConstraint.multiplier),
                #keyPath(NSLayoutConstraint.constant)
            ],
            function: {
                let result = NSLayoutConstraint(
                    item: $0[#keyPath(NSLayoutConstraint.firstItem)]!!,
                    attribute: $0[#keyPath(NSLayoutConstraint.firstAttribute)] as! NSLayoutConstraint.Attribute,
                    relatedBy: $0[#keyPath(NSLayoutConstraint.relation)] as? NSLayoutConstraint.Relation ?? .equal,
                    toItem: $0[#keyPath(NSLayoutConstraint.secondItem)] ?? nil,
                    attribute: $0[#keyPath(NSLayoutConstraint.secondAttribute)] as? NSLayoutConstraint.Attribute ?? .notAnAttribute,
                    multiplier: CGFloat($0[#keyPath(NSLayoutConstraint.multiplier)] as? Double ?? 1),
                    constant: CGFloat($0[#keyPath(NSLayoutConstraint.constant)] as? Double ?? 0)
                )
        
                ($0[#keyPath(NSLayoutConstraint.firstItem)] as? NSView)?.translatesAutoresizingMaskIntoConstraints = false
                ($0[#keyPath(NSLayoutConstraint.secondItem)] as? NSView)?.translatesAutoresizingMaskIntoConstraints = false
        
                return result
            }
        ))
    ],
    cNSLayoutAttribute: [
        .caseLiteralConvertor(type: NSLayoutConstraint.Attribute.self, cases: [
            "left": .left,
            "right": .right,
            "top": .top,
            "bottom": .bottom,
            "leading": .leading,
            "trailing": .trailing,
            "width": .width,
            "height": .height,
            "centerX": .centerX,
            "centerY": .centerY,
            "lastBaseline": .lastBaseline,
            "notAnAttribute": .notAnAttribute
        ])
    ],
    cNSLayoutRelation: [
        .caseLiteralConvertor(type: NSLayoutConstraint.Relation.self, cases: [
            "equal": .equal,
            "lessThanOrEqual": .lessThanOrEqual,
            "greaterThanOrEqual": .greaterThanOrEqual
        ])
    ]
]
