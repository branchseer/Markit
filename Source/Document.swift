class Document {
    struct Property {
        let namespace: String
        let name: String
        let valueItems: [Item]
    }
    
    struct Invocation {
        let method: String
    }

    enum Item {
        case string(_: String)
        case element(_: Element)
    }
    
    struct Element {
        let namespace: String
        let name: String
        
        let headProperties: [Property]
        
        enum Content {
            case string(_: String)
            case elements(_: [Element])
        }
        
        let children: [Item]
        let tailProperties: [Property]
    }
    
    let rootElement: Element
    
    init(rootElement: Element) {
        self.rootElement = rootElement
    }
    
    enum Error: Swift.Error {
        case missingNamespace(xmlNode: XMLNode)
        case unsupportedNodeType(xmlNode: XMLNode)
        case inappropriatelyPositionedChildNode(_: XMLNode)
        case noRootElement
    }
    
    convenience init(xml: XMLSource) throws {
        let xmlDocument: XMLDocument = try {
            switch xml {
            case .fileURL(let url):
                return try XMLDocument(contentsOf: url)
            case .contentString(let xmlString):
                return try XMLDocument(xmlString: xmlString)
            }
        }()
        
        if let rootElement = xmlDocument.rootElement() {
            self.init(rootElement: try element(from: rootElement))
        }
        else {
            throw Error.noRootElement
        }
    }
}

fileprivate extension String {
    func removingPrefix(_ prefix: String) -> String? {
        if self.hasPrefix(prefix) {
            return String(self.dropFirst(prefix.count))
        }
        else {
            return nil
        }
    }
}

fileprivate func item(from xmlNode: XMLNode) throws -> Document.Item? {
    if xmlNode.kind == .text {
        return .string(xmlNode.stringValue!)
    }
    if let xmlElement = xmlNode as? XMLElement {
        return try .element(element(from: xmlElement))
    }
    if xmlNode.kind == .comment {
        return nil
    }
    throw Document.Error.unsupportedNodeType(xmlNode: xmlNode)
}

fileprivate func element(from xmlElement: XMLElement) throws -> Document.Element {
    guard let elementNamespace = xmlElement.namespace else {
        throw Document.Error.missingNamespace(xmlNode: xmlElement)
    }
    var headProperties: [Document.Property] = []
    
    let propertyElementPrefix = xmlElement.localName! + "."
    
    for attrNode in xmlElement.attributes ?? [] {
        guard let attrNamespace = xmlElement.resolveNamespace(forName: attrNode.name!)?.stringValue else {
            throw Document.Error.missingNamespace(xmlNode: attrNode)
        }
        let propertyName = attrNode.localName!.removingPrefix(propertyElementPrefix) ?? attrNode.localName!
        let valueItems: [Document.Item] = [{
            var attrStringValue = attrNode.stringValue ?? ""
            if attrStringValue.first == "$" {
                attrStringValue = String(attrStringValue.dropFirst())
                if attrStringValue.first != "$" {
                    return .element(Document.Element(
                        namespace: kMarkitNamespace,
                        name: kReferenceClassName,
                        headProperties: [
                            Document.Property(
                                namespace: kMarkitNamespace,
                                name: kReferenceExpressionName,
                                valueItems: [.string(attrStringValue)]
                            )
                        ],
                        children: [], tailProperties: [])
                    )
                }
            }
            return .string(attrStringValue)
        }()]//[.string(attrNode.stringValue ?? "")]
        headProperties.append(Document.Property(
            namespace: attrNamespace,
            name: propertyName,
            valueItems: valueItems
        ))
    }
    
    
    enum ChildReadingStatus {
        case head
        case children
        case tail
    }
    var childReadingStatus = ChildReadingStatus.head
    
    var tailProperties: [Document.Property] = []
    var children: [Document.Item] = []
    
    for childNode in xmlElement.children ?? [] {
        if let childElement = childNode as? XMLElement,
            let propertyName = childElement.localName!.removingPrefix(propertyElementPrefix) {
            guard let propertyNamespace = childElement.resolveNamespace(forName: childElement.name ?? "")?.stringValue else {
                throw Document.Error.missingNamespace(xmlNode: childNode)
            }
            
            let newProperty = Document.Property(
                namespace: propertyNamespace,
                name: propertyName,
                valueItems: try (childElement.children ?? []).compactMap(item)
            )
            switch childReadingStatus {
            case .head:
                headProperties.append(newProperty)
            case .children:
                childReadingStatus = .tail
                tailProperties.append(newProperty)
            case .tail:
                tailProperties.append(newProperty)
            }
            
        }
        else {
            guard let newChild = try item(from: childNode) else {
                continue
            }
            
            switch childReadingStatus {
            case .head:
             childReadingStatus = .children
             children.append(newChild)
            case .children:
             children.append(newChild)
            case .tail:
             throw Document.Error.inappropriatelyPositionedChildNode(childNode)
            }
        }
    }
    
    return Document.Element(
        namespace: elementNamespace,
        name: xmlElement.localName!,
        headProperties: headProperties,
        children: children,
        tailProperties: tailProperties
    )
}
