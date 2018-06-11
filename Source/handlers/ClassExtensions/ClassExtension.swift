//
//  ClassExtension.swift
//  Markit
//
//  Created by patr0nus on 2018/6/5.
//

import Foundation

enum ClassExtension {
    struct Constructor {
        let requiredArguments: Set<String>
        let optionalArguments: Set<String>
        let function: ([String: Any?]) throws -> Any
    }
    case constructor(_: Constructor)
    
    
    struct Property {
        let name: String
        let type: PropertyType
    }
    case property(_: Property)
    
    
    struct PropertySetter {
        let propertyName: String
        let function: PropertySetterFunction
    }
    case propertySetter(_: PropertySetter)
    
    typealias ContentPropertyName = String
    case contentPropertyName(_ :ContentPropertyName)

    typealias LiteralConvertor<T> = (String) throws -> T
    case literalConvertor(_: LiteralConvertor<Any?>)
}



class ClassExtensionIndex {
    private(set) var constructors = [String: [ClassExtension.Constructor]]()
    private(set) var properties = [String: [String: PropertyType]]()
    private(set) var propertySetters = [String: [String: PropertySetterFunction]]()
    private(set) var contentPropertyNames = [String: ClassExtension.ContentPropertyName]()
    private(set) var literalConvertors = [String: ClassExtension.LiteralConvertor<Any?>]()
    
    func propertyType(name: String, inClass className: String) -> PropertyType? {
        for className in className.selfAndAncestorClassNames {
            if let result = properties[className]?[name] {
                return result
            }
        }
        return nil
    }
    
    func propertySetter(_ name: String, inClass className: String) -> PropertySetterFunction? {
        for className in className.selfAndAncestorClassNames {
            if let result = propertySetters[className]?[name] {
                return result
            }
        }
        return nil
    }
    
    func contentPropertyName(ofClass className: String) -> ClassExtension.ContentPropertyName? {
        for className in className.selfAndAncestorClassNames {
            if let result = contentPropertyNames[className] {
                return result
            }
        }
        return nil
    }
    
    convenience init(extensionsByClassName: [String: [ClassExtension]]) {
        self.init()
        self.add(extensionsByClassName: extensionsByClassName)
    }
    
    func add(extensionsByClassName: [String: [ClassExtension]]) {
        for (className, extensions) in extensionsByClassName {
            self.add(className: className, extensions: extensions)
        }
    }
    
    private func add(className: String, extensions: [ClassExtension]) {
        for e in extensions {
            self.add(className: className, extension: e)
        }
    }
    
    private func add(className: String, extension: ClassExtension) {
        switch `extension` {
        case .constructor(let constructor):
            if !constructors.keys.contains(className) {
                constructors[className] = []
            }
            constructors[className]!.append(constructor)
        case .property(let property):
            if !properties.keys.contains(className) {
                properties[className] = [:]
            }
            properties[className]![property.name] = property.type
        case .propertySetter(let propertySetter):
            if !propertySetters.keys.contains(className) {
                propertySetters[className] = [:]
            }
            propertySetters[className]![propertySetter.propertyName] = propertySetter.function
        case .contentPropertyName(let contentPropertyName):
            contentPropertyNames[className] = contentPropertyName
        case .literalConvertor(let literalConvertor):
            literalConvertors[className] = literalConvertor
        }
    }
}
