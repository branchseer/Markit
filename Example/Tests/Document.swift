import XCTest
@testable import Markit

fileprivate extension  Document.Item {
    var string: String? {
        switch self {
        case .string(let string):
            return string
        default:
            return nil
        }
    }
    
    var element: Document.Element? {
        switch self {
        case .element(let element):
            return element
        default:
            return nil
        }
    }
}

extension Document.Item: Equatable {
    
    
    public static func == (lhs: Document.Item, rhs: Document.Item) -> Bool {
        switch lhs {
        case .string(let lstr):
            if case .string(let rstr) = rhs {
                return lstr == rstr
            }
            return false
        case .element(let lele):
            if case .element(let rele) = rhs {
                return lele == rele
            }
            return false
        }
    }
}

extension Document.Property: Equatable {
    public static func == (lhs: Document.Property, rhs: Document.Property) -> Bool {
        return lhs.name == rhs.name && lhs.namespace == rhs.namespace && lhs.valueItems == rhs.valueItems
    }
}

extension Document.Element: Equatable {
    public static func == (lhs: Document.Element, rhs: Document.Element) -> Bool {
        return lhs.name == rhs.name &&
            lhs.namespace == rhs.namespace &&
            lhs.headProperties == rhs.headProperties &&
            lhs.children == rhs.children &&
            lhs.tailProperties == rhs.tailProperties
    }
}

fileprivate extension Array where Element == Document.Property {
    func item(named name: String) -> Element? {
        return self.first(where: { $0.name == name })
    }
}

class DocumentTests: XCTestCase {
    
    var element: Markit.Document.Element!
    
    override func setUp() {
        super.setUp()
        XCTAssertNoThrow(self.element = try Document(xml: .contentString("""
<NSWindow
    xmlns="https://defaultns.com"
    xmlns:x="https://x.com"
    title="Window Title" NSWindow.prefixedProp="hello" emptyProp="" NSStackView.alphaValue="1" x:id="mainWindow">
    
    <NSWindow.zipzap>Yo</NSWindow.zipzap>
    <NSWindow.complexProp>
        <NSView />str</NSWindow.complexProp>

    <AppKit.NSTextView />midchild<NSTextField stringValue="helloThere" />
    <Constraint expr="$expr" literal="$$notExpr">
        <Constraint.elementExpr>$notExpr</Constraint.elementExpr>
        <Constraint.elementLiteral>$$notExpr</Constraint.elementLiteral>
    </Constraint>

    <x:Reference expression="aTextField" />

    <NSWindow.tailProp1>Hello There</NSWindow.tailProp1>

</NSWindow>
""")).rootElement)
        
        XCTAssertNotNil(self.element)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAttributes() {
        XCTAssertEqual(self.element.name, "NSWindow")
        XCTAssertEqual(self.element.headProperties.item(named: "id")?.valueItems, [Document.Item.string("mainWindow")])
        XCTAssertEqual(self.element.headProperties.item(named: "id")?.namespace, "https://x.com")
        XCTAssertEqual(
            self.element.headProperties.item(named: "title")?.valueItems,
            [.string("Window Title")]
        )
        XCTAssertEqual(
            self.element.headProperties.item(named: "prefixedProp")?.valueItems,
            [.string("hello")]
        )
        XCTAssertEqual(
            self.element.headProperties.item(named: "emptyProp")?.valueItems,
            [.string("")]
        )
    }
//
    func testHeadProperties() {

        XCTAssertEqual(self.element.headProperties.count, 7)

        XCTAssertEqual(self.element.headProperties[5].name, "zipzap")
        XCTAssertEqual(self.element.headProperties[5].valueItems, [.string("Yo")])
//
        XCTAssertEqual(self.element.headProperties[6].name, "complexProp")
        XCTAssertEqual(self.element.headProperties[6].valueItems.count, 2)
        XCTAssertEqual(self.element.headProperties[6].valueItems[0].element?.name, "NSView")
        XCTAssertEqual(self.element.headProperties[6].valueItems[1].string, "str")
    }
    
    func testContent() {
        XCTAssertEqual(self.element.children.count, 5)
        XCTAssertEqual(self.element.children[0].element?.name, "AppKit.NSTextView")
        XCTAssertEqual(self.element.children[1].string, "midchild")
        XCTAssertEqual(self.element.children[2].element?.name, "NSTextField")
    }
    
    func testExpression() {
        let testElement = self.element.children[3].element
        XCTAssertEqual(testElement?.headProperties.item(named: "expr")?.valueItems[0].element?.name, "Reference")
        XCTAssertEqual(testElement?.headProperties.item(named: "expr")?.valueItems[0].element?.headProperties[0].valueItems[0].string, "expr")
        XCTAssertEqual(testElement?.headProperties.item(named: "literal")?.valueItems[0].string, "$notExpr")
        
        XCTAssertEqual(
            testElement?.headProperties.item(named: "elementExpr")?.valueItems[0].string,
            "$notExpr"
        )
        
        XCTAssertEqual(
            testElement?.headProperties.item(named: "elementLiteral")?.valueItems[0].string,
            "$$notExpr"
        )

//        XCTAssertEqual(self.element.children[3].element?.headProperties.item(named: "firstItem")?.valueItems[0].element?.name, kReferenceClassName)

    }
    
    func testTailProperties() {
        XCTAssertEqual(self.element.tailProperties.count, 1)

        XCTAssertEqual(self.element.tailProperties[0].name, "tailProp1")
    }
//
//
//
    func testInappropriateProperty() {
        XCTAssertThrowsError(try Document(xml: .contentString("""
<MyClass xmlns="https://wangchi.me/markit/objc">
    <MyClass.props1></MyClass.props1>
    <View />
    <MyClass.props2></MyClass.props2>
    <View />
</MyClass>
"""
        ))) { error in
            if case .inappropriatelyPositionedChildNode? = error as? Document.Error { } else {
                XCTFail()
            }
        }
    }
    
}
