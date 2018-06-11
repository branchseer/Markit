//
//  Compiler.swift
//  Markit_Tests
//
//  Created by patr0nus on 2018/5/28.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Markit

fileprivate let defaultns = "https://wangchi.me/markit/v0_1/objc"
fileprivate let xns = "https://wangchi.me/markit/v0_1"

class CompilerTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLitertalAttributes() {
        var result: MarkitObject!
        XCTAssertNoThrow(
            result = try MarkitCompiler.shared.build(fromXML: .contentString("""
<x:Markit
    xmlns="\(defaultns)"
    xmlns:x="\(xns)"
>
<NSTextField stringValue="hey" />
</x:Markit>
"""
            ))
        )
        
        let textField: NSTextField! = result.topObjects[0] as? NSTextField
        XCTAssertNotNil(textField)
        XCTAssertEqual(textField.stringValue, "hey")
    }

    func testLitertalElementAttributes() {
        var result: MarkitObject!
        XCTAssertNoThrow(
            result = try MarkitCompiler.shared.build(fromXML: .contentString("""
<x:Markit
    xmlns="\(defaultns)"
    xmlns:x="\(xns)"
>
<NSTextField>
    <NSTextField.stringValue>haha</NSTextField.stringValue>
</NSTextField>
</x:Markit>
"""
                ))
        )

        let textField: NSTextField! = result.topObjects[0] as? NSTextField
        XCTAssertNotNil(textField)
        XCTAssertEqual(textField.stringValue, "haha")
    }

    func testLitertalContentAttributes() {
        
        var result: MarkitObject!
        XCTAssertNoThrow(
            result = try MarkitCompiler.shared.build(fromXML: .contentString("""
<x:Markit
    xmlns="\(defaultns)"
    xmlns:x="\(xns)"
>
<NSTextField>yo</NSTextField>
</x:Markit>
"""
                ))
        )
        
        let textField: NSTextField! = result.topObjects[0] as? NSTextField
        XCTAssertNotNil(textField)
        XCTAssertEqual(textField.stringValue, "yo")
    }
//
    func testArrayContentAttributes() {
        
        
        var result: MarkitObject!
        XCTAssertNoThrow(
            result = try MarkitCompiler.shared.build(fromXML: .contentString("""
<x:Markit
    xmlns="\(defaultns)"
    xmlns:x="\(xns)"
>
<NSView>
    <NSTextField>hey</NSTextField>
</NSView>
</x:Markit>
"""
                ))
        )
        
        let view: NSView! = result.topObjects[0] as? NSView
        XCTAssertNotNil(view)
        XCTAssertEqual(view.subviews.count, 1)
        XCTAssertEqual((view.subviews[0] as? NSTextField)?.stringValue , "hey")
    }
//
    func testPropertyOrder() {
        var result: MarkitObject!
        XCTAssertNoThrow(
            result = try MarkitCompiler.shared.build(fromXML: .contentString("""
<x:Markit
    xmlns="\(defaultns)"
    xmlns:x="\(xns)"
>
<NSView layer.cornerRadius="0.5">
    <NSView.wantsLayer>true</NSView.wantsLayer>
    <NSTextField>hey</NSTextField>
</NSView>
</x:Markit>
"""
                ))
        )

        let view: NSView! = result.topObjects[0] as? NSView
        XCTAssertEqual(view.subviews.count, 1)
        XCTAssertEqual((view.subviews[0] as? NSTextField)?.stringValue , "hey")
        XCTAssertEqual(view.wantsLayer, true)
        XCTAssertEqual(view.layer?.cornerRadius ?? 0, 0.5, accuracy: 10e-5)
    }
    
    func testNamedObjects() {
        var result: MarkitObject!
        XCTAssertNoThrow(
            result = try MarkitCompiler.shared.build(fromXML: .contentString("""
                <x:Markit
                xmlns="\(defaultns)"
                xmlns:x="\(xns)"
                >
                <NSTextField x:name="aTextField">haha</NSTextField>
                </x:Markit>
                """
                ))
        )
        
        let textField: NSTextField! = result.objectsByName["aTextField"] as? NSTextField
        XCTAssertNotNil(textField)
        XCTAssertEqual(textField.stringValue, "haha")
    }
    
    func testIDObjects() {
        var result: MarkitObject!
        XCTAssertNoThrow(
            result = try MarkitCompiler.shared.build(fromXML: .contentString("""
                <x:Markit
                xmlns="\(kObjcNamespace)"
                xmlns:x="\(kMarkitNamespace)"
                >
                <NSTextField x:id="aTextField">haha</NSTextField>
                <NSView>
                <x:Reference x:expression="aTextField" />
                </NSView>
                </x:Markit>
                """
                ))
        )
        
        XCTAssertEqual(result.topObjects[0] as? NSTextField, (result.topObjects[1] as? NSView)?.subviews[0] as? NSTextField)
    }
    func testLiteralReference() {
        var result: MarkitObject!
        XCTAssertNoThrow(
            result = try MarkitCompiler.shared.build(fromXML: .contentString("""
                <x:Markit xmlns="\(kObjcNamespace)" xmlns:x="\(kMarkitNamespace)">
                    <NSView x:id="view" x:name="view">
                        <NSTextField x:id="aTextField">a</NSTextField>
                    </NSView>

                    <NSLayoutConstraint firstItem="$aTextField" firstAttribute="centerX" secondItem="$view" secondAttribute="centerX" active="true" />
                    <NSLayoutConstraint firstItem="$aTextField" firstAttribute="centerY" secondItem="$view" secondAttribute="centerY" active="true" />
                </x:Markit>

                
                
                """
                ))
        )
        let contraint = result.topObjects[1] as! NSLayoutConstraint
    
        XCTAssertEqual(
            ObjectIdentifier(contraint.firstItem!),
            ObjectIdentifier(result.objectsByID["aTextField"] as AnyObject)
        )
        
        XCTAssertEqual(contraint.firstAttribute, .centerX)
        
        XCTAssertEqual(
            ObjectIdentifier(contraint.secondItem!),
            ObjectIdentifier(result.objectsByID["view"] as AnyObject)
        )
        XCTAssertEqual(contraint.secondAttribute, .centerX)
        
        XCTAssertEqual(contraint.isActive, true)
    }

}
