//
//  Compiler.swift
//  Markit
//
//  Created by patr0nus on 2018/5/20.
//

import Cocoa

enum PropertyType {
    case singleValue(className: String)
    case array(elementClassName: String?)
}

typealias Object = Any?
typealias PropertyValue = Object
typealias Context = Any
typealias ObjectConstructor = (Context?, [String: PropertyValue]) throws -> Object
typealias PropertySetterFunction = (Context?, Object, PropertyValue) throws -> Void
typealias ObjectLifecycleCallback = (Context?, Object) -> Void
typealias ContextCreator = (Connector) -> Context?

protocol NamespaceHandler {
    init(urlParams: [URLQueryItem]?)
    
    func contextCreator() -> ContextCreator
    func objectConstructor(ofClass className: String, propertyNames: Set<String>) throws -> (ObjectConstructor, propertyNamesForConstructor: Set<String>)
    func object(ofClass className: String, literal: String) throws -> Object

    func objectConstructedCallback(forClass className: String) -> ObjectLifecycleCallback?
    func type(ofProperty propertyName: String, inClass className: String) throws -> PropertyType
    func propertySetter(ofProperty propertyName: String, inClass className: String) -> PropertySetterFunction
    func property(_ lp: String, mustBeAssignedBeforeProperty rp: String) -> Bool
    
    func contentPropertyName(ofClass className: String) throws -> String?
    func objectBuiltCallback(forClass className: String) -> ObjectLifecycleCallback?
}

class Compiler {
    let namespaceHandlerTypes: [String: NamespaceHandler.Type]
    init(namespaceHandlerTypes: [String: NamespaceHandler.Type]) {
        self.namespaceHandlerTypes = namespaceHandlerTypes
    }
    
    private var cachedNamespaceHandlers = [String: NamespaceHandler]()
    private func handlerForNamespace(_ namespace: String) throws -> NamespaceHandler {
        if let handler = cachedNamespaceHandlers[namespace] {
            return handler
        }
        var handler: NamespaceHandler?
        if let HandlerType = namespaceHandlerTypes[namespace] {
            handler = HandlerType.init(urlParams: nil)
        }
        else if let urlCompoents = URLComponents(string: namespace) {
            let urlWithoutParams = String(namespace[..<(urlCompoents.rangeOfPath?.upperBound ?? namespace.endIndex)])
           
            handler = namespaceHandlerTypes[urlWithoutParams]?.init(urlParams: urlCompoents.queryItems)
        }
        
        guard let theHandler = handler else {
            throw Error.unknownNamespace(namespace)
        }
        cachedNamespaceHandlers[namespace] = theHandler
        return theHandler
    }
    
    private func compile(element: Document.Element) throws -> ObjectBuilder.ElementObjectBuildInfo {
        let elementNamespacehandler = try handlerForNamespace(element.namespace)
        
        var properties = element.headProperties
        
        if !element.children.isEmpty {
            guard let contentPropertyName = try elementNamespacehandler.contentPropertyName(ofClass: element.name) else {
                throw Error.noContentPropertyForClass(element.name)
            }
            properties.append(Document.Property(
                namespace: element.namespace,
                name: contentPropertyName, valueItems: element.children
            ))
        }
        
        
        properties.append(contentsOf: element.tailProperties)
        
        let localPropertyNames = Set<String>(properties.compactMap {
            if $0.namespace == element.namespace {
                return $0.name
            }
            else {
                return nil
            }
        })
        
        let (objectConstructor, propertyNamesForConstructor)  = try elementNamespacehandler.objectConstructor(
            ofClass: element.name,
            propertyNames: localPropertyNames
        )
        
        var propertiesForConstructor = [Document.Property]()
        var propertiesForSetter = [Document.Property]()
        
        for property in properties {
            if property.namespace == element.namespace && propertyNamesForConstructor.contains(property.name) {
                propertiesForConstructor.append(property)
            }
            else {
                propertiesForSetter.append(property)
            }
        }
        
        
        func propertyValueBuildInfo(from property: Document.Property) throws -> ObjectBuilder.PropertyBuildInfo.ValueBuildInfo {
            
            let handler = try handlerForNamespace(property.namespace)
            let propertyType = try handler.type(ofProperty: property.name, inClass: element.name)
            switch propertyType {
            case .singleValue(let className):
                guard property.valueItems.count == 1 else {
                    throw Error.invalidChildCount(property: property.name, className: element.name)
                }
                switch property.valueItems[0] {
                case .string(let stringLiteral):
                    let value = try handler.object(ofClass: className, literal: stringLiteral)
                    return .singleValue(.immediateValue(value))
                case .element(let element):
                    return .singleValue(.fromElement(try compile(element: element)))
                }
            case .array(let elementClassName):
                return .array(try property.valueItems.map {
                    switch $0 {
                    case .string(let stringLiteral):
                        if let elementClassName = elementClassName {
                            let value = try handler.object(ofClass: elementClassName, literal: stringLiteral)
                            return .immediateValue(value)
                        }
                        else {
                            return .immediateValue(stringLiteral)
                        }
                    case .element(let element):
                        return .fromElement(try compile(element: element))
                    }
                })
            }
        }
        
        let constructorParameters: [(String, ObjectBuilder.PropertyBuildInfo.ValueBuildInfo)] = try propertiesForConstructor.map {
            return ($0.name, try propertyValueBuildInfo(from: $0))
        }
        
        let sortedPropertiesForSetter = (propertiesForSetter as NSArray).sortedArray(options: .stable) {
            let lp = $0 as! Document.Property
            let rp = $1 as! Document.Property
            
            if (lp.namespace != element.namespace || rp.namespace != element.namespace) {
                return .orderedSame
            }
            
            if elementNamespacehandler.property(lp.name, mustBeAssignedBeforeProperty: rp.name) {
                return .orderedAscending
            }
            else if elementNamespacehandler.property(rp.name, mustBeAssignedBeforeProperty: lp.name) {
                return .orderedDescending
            }
            else {
                return .orderedSame
            }
        } as! [Document.Property]
        
        let settersAndProperties: [(PropertySetterFunction, ObjectBuilder.PropertyBuildInfo)] = try sortedPropertiesForSetter.map {
            let handler =  try self.handlerForNamespace($0.namespace)
            
            return (
                
                handler.propertySetter(ofProperty: $0.name, inClass: element.name),
                ObjectBuilder.PropertyBuildInfo(
                    namespace: $0.namespace,
                    valueBuildInfo:  try propertyValueBuildInfo(from: $0)
                )
            )
        }
        
        return ObjectBuilder.ElementObjectBuildInfo(
            classNamespace: element.namespace,
            constructor: objectConstructor,
            constructorParameters: constructorParameters,
            objectConstructedCallback: elementNamespacehandler.objectConstructedCallback(forClass: element.name),
            properties: settersAndProperties,
            objectBuiltCallback: elementNamespacehandler.objectBuiltCallback(forClass: element.name)
        )
    }
    
    private func compile(document: Document) throws -> ObjectBuilder {
        let namespacesAndContextCreators = try document.namespaces.map {
            ($0, try handlerForNamespace($0).contextCreator())
        }
        return ObjectBuilder(
            namespacesAndContextCreators: namespacesAndContextCreators,
            objectBuildInfo: try compile(element: document.rootElement)
        )
    }
    
    func compile(xml: XMLSource) throws -> ObjectBuilder {
        return try compile(document: try Document(xml: xml))
    }
    
    enum Error: Swift.Error {
        case unknownNamespace(_: String)
        case noContentPropertyForClass(_: String)
        case invalidChildCount(property: String, className: String)
        case emptyRootElement
        case noSuchClassName(_: String)
        case invalidLiteral(_: String, className: String)
        case propertyNotFound(name: String, className: String)
        case missingRequiredProperty(name: String, className: String)
        case noSuitableConstructorForClass(_: String, propertyNames: Set<String>)
        case unexpectedPropertyValue(_ :Any?, property: String, className: String)
    }
}


private extension Document {
    var namespaces: Set<String> {
        return rootElement.namespaces
    }
}

private extension Document.Element {
    var namespaces: Set<String> {
        var result: Set<String> = [ self.namespace ]
        result.formUnion(self.headProperties.map { $0.namespace })
        result.formUnion(self.children.flatMap { $0.namespaces })
        result.formUnion(self.tailProperties.map { $0.namespace })
        
        return result
    }
}

private extension Document.Item {
    var namespaces: Set<String> {
        switch self {
        case .string:
            return []
        case .element(let element):
            return element.namespaces
        }
    }
}
