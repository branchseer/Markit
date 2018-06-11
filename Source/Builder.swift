//
//  Builder.swift
//  Markit
//
//  Created by patr0nus on 2018/6/8.
//

import Foundation


struct ObjectBuilder {
    let namespacesAndContextCreators: [(String, ContextCreator)]
    let objectBuildInfo: ElementObjectBuildInfo
    
    struct ElementObjectBuildInfo {
        let classNamespace: String
        let constructor: ObjectConstructor
        let constructorParameters: [(String, PropertyBuildInfo.ValueBuildInfo)]
        let objectConstructedCallback: ObjectLifecycleCallback?
        let properties: [(PropertySetterFunction, PropertyBuildInfo)]
        let objectBuiltCallback: ObjectLifecycleCallback?
        
        func build(with contextsByNamespace: [String: Context]) throws -> Object {
            let elementNamespaceContext = contextsByNamespace[self.classNamespace]
            
            let parameters = Dictionary(uniqueKeysWithValues: try constructorParameters.map {
                ($0.0, try $0.1.build(with: contextsByNamespace))
                })
            
            let object = try constructor(elementNamespaceContext, parameters)
            objectConstructedCallback?(elementNamespaceContext, object)
            
            for (propertySetter, propertyBuildInfo) in properties {
                try propertySetter(
                    contextsByNamespace[propertyBuildInfo.namespace],
                    object,
                    try propertyBuildInfo.valueBuildInfo.build(with: contextsByNamespace)
                )
            }
            
            objectBuiltCallback?(elementNamespaceContext, object)
            
            return object
        }
    }
    
    
    enum ObjectBuildInfo {
        case fromElement(_: ElementObjectBuildInfo)
        case immediateValue(_: Object)
        
        func build(with contextsByNamespace: [String: Any]) throws -> Object {
            switch self {
            case .immediateValue(let value):
                return value
            case .fromElement(let elementObjectBuildInfo):
                return try elementObjectBuildInfo.build(with: contextsByNamespace)
            }
        }
    }
    
    struct PropertyBuildInfo {
        
        enum ValueBuildInfo {
            case singleValue(_ : ObjectBuildInfo)
            case array(_: [ObjectBuildInfo])
            
            func build(with contextsByNamespace: [String: Any]) throws -> PropertyValue {
                switch self {
                case .singleValue(let buildInfo):
                    return try buildInfo.build(with: contextsByNamespace)
                case .array(let buildInfos):
                    return try buildInfos.map { try $0.build(with: contextsByNamespace) }
                }
            }
        }
        
        let namespace: String
        let valueBuildInfo: ValueBuildInfo
    }
    
    
    func build(withConnector connector: Connector) throws -> PropertyValue {
        let contextsByNamespace = Dictionary<String, Any>(uniqueKeysWithValues: namespacesAndContextCreators
            .compactMap {
                if let context = $0.1(connector) {
                    return ($0.0, context)
                }
                else {
                    return nil
                }
            }
        )
        return try objectBuildInfo.build(with: contextsByNamespace)
    }
}
