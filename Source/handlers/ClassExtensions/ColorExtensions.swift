//
//  ColorExtensions.swift
//  Markit
//
//  Created by patr0nus on 2018/6/7.
//

import Foundation

//credit: https://github.com/thii/SwiftHEXColors/blob/master/Sources/SwiftHEXColors.swift

#if canImport(UIKit)
    import UIKit
    fileprivate typealias Color = UIColor
#elseif canImport(Cocoa)
    import Cocoa
    fileprivate typealias Color = NSColor
#endif

private extension Int {
    func duplicate4bits() -> Int {
        return (self << 4) + self
    }
}

fileprivate let colorCases: [String: Color] = [
    "red": .red,
    "white": .white
]

fileprivate func color(fromLiteral literal: String) throws -> Color {
    guard literal.hasPrefix("#") else {
        throw Compiler.Error.invalidLiteral(literal, className: "Color")
    }
    var hexString = literal.dropFirst()
    var alpha: Float = 1
    
    if let alphaDelimier = hexString.index(of: "@") {
        guard let alphaStartIndex = hexString.index(alphaDelimier, offsetBy: 1, limitedBy: hexString.endIndex) else {
            throw Compiler.Error.invalidLiteral(literal, className: "Color")
        }
        
        guard let theAlpha = Float(hexString[alphaStartIndex..<hexString.endIndex]) else {
            throw Compiler.Error.invalidLiteral(literal, className: "Color")
        }
        alpha = theAlpha
        hexString = hexString[..<alphaDelimier]
    }
    
    
    
    if hexString.count == 3, let hexValue = Int(hexString, radix: 16) {
        return Color(red:   CGFloat(((hexValue & 0xF00) >> 8).duplicate4bits()) / 255.0,
                     green: CGFloat(((hexValue & 0x0F0) >> 4).duplicate4bits()) / 255.0,
                     blue:  CGFloat(((hexValue & 0x00F) >> 0).duplicate4bits()) / 255.0,
                     alpha: CGFloat(alpha))
    }
    if hexString.count == 6, let hexValue = Int(hexString, radix: 16) {
        return Color(red:   CGFloat((hexValue & 0xFF0000) >> 16 ) / 255.0,
                     green: CGFloat((hexValue & 0x00FF00) >> 8  ) / 255.0,
                     blue:  CGFloat((hexValue & 0x0000FF) >> 0  ) / 255.0,
                     alpha: CGFloat(alpha))
    }
    
    throw Compiler.Error.invalidLiteral(literal, className: "Color")
}

let ColorExtensions: [String: [ClassExtension]] = [
    Color.self.className(): [
        .caseLiteralConvertor(type: Color.self, cases: colorCases, fallbackConvertor: color(fromLiteral:))
    ],
    "CGColor": [
        .caseLiteralConvertor(type: CGColor.self, cases: colorCases.mapValues { $0.cgColor }) {
            try color(fromLiteral: $0).cgColor
        }
    ]
]
