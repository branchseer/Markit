//
//  Markit.swift
//  Markit
//
//  Created by patr0nus on 2018/5/29.
//

import Foundation

let kMarkitNamespace = "https://wangchi.me/markit/v0_1"
let kObjcNamespace = "https://wangchi.me/markit/v0_1/objc"



public class MarkitObject {
    enum OutputObject {
        case dictionary(_: NSMutableDictionary)
        case kvc(_: NSObject)
    }
    
    public internal(set) var topObjects: [Any] = []
    let connector: Connector
    let objectsByID = NSMutableDictionary()
    
    init(connector: Connector) {
        self.connector = connector
    }
}

public enum XMLSource {
    case fileURL(_: URL)
    case contentString(_: String)
    
    public static func resource(_ resourceName: String) -> XMLSource? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "xml") else {
            return nil
        }
        return .fileURL(url)
    }
}

public class MarkitObjectBuilder {
    private let objectBuilder: ObjectBuilder
    fileprivate init(objectBuilder: ObjectBuilder) {
        self.objectBuilder = objectBuilder
    }
    
    @discardableResult
    public func build(withOwner owner: NSObject? = nil) throws -> [Any] {
        return (try objectBuilder.build(withConnector: OnwerConnector(owner: owner)) as! MarkitObject).topObjects
    }
}

public class MarkitCompiler {
    private let compiler: Compiler
    private init(compiler: Compiler) {
        self.compiler = compiler
    }
    
    public static let shared = MarkitCompiler(compiler: Compiler(namespaceHandlerTypes: [
        "https://wangchi.me/markit/v0_1": MarkitNamespaceHandler.self,
        "https://wangchi.me/markit/v0_1/objc": ObjcNamespaceHandler.self,
    ]))
    
    public func compile(xml: XMLSource) throws -> MarkitObjectBuilder {
        return MarkitObjectBuilder(objectBuilder: try compiler.compile(xml: xml))
    }
    
    @discardableResult
    public func build(fromXML xml: XMLSource, owner: NSObject? = nil) throws -> [Any] {
        return try compile(xml: xml).build(withOwner: owner)
    }
}

public enum BuildError: Error {
    case noObjectForInputing
    case noObjectForOutputing
}
