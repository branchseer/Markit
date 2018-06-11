//
//  ObjcNamespaceHandler.swift
//  Markit
//
//  Created by patr0nus on 2018/5/28.
//

import Foundation

var a: [Int] = [1]

enum EncodedType: String {
    case char = "c"
    case int = "i"
    case short = "s"
    case long = "l"
    case longLong = "q"
    case unsignedChar = "C"
    case unsignedInt = "I"
    case unsignedShort = "S"
    case unsignedLong = "L"
    case unsignedLongLong = "Q"
    case float = "f"
    case double = "d"
    case bool = "B"
    case selector = ":"
}

fileprivate let literalConvertors: [String: (String) -> Any?] = [
    EncodedType.char.rawValue: { Bool($0) ?? CChar($0) },
    EncodedType.int.rawValue: { Int($0) },
    EncodedType.short.rawValue: { CShort($0) },
    EncodedType.long.rawValue: { CLong($0) },
    EncodedType.longLong.rawValue: { CLongLong($0) },
    EncodedType.unsignedInt.rawValue: { CUnsignedInt($0) },
    EncodedType.unsignedShort.rawValue: { CUnsignedShort($0) },
    EncodedType.unsignedLong.rawValue: { CUnsignedLong($0) },
    EncodedType.unsignedLongLong.rawValue: { CUnsignedLongLong($0) },
    EncodedType.float.rawValue: { Float($0) },
    EncodedType.double.rawValue: { Double($0) },
    EncodedType.bool.rawValue: { Bool($0) },
    EncodedType.selector.rawValue: { NSSelectorFromString($0) }
]

private func mergeMutilDictionary<Key, ValueItem>(_ dictionaries: [Dictionary<Key, [ValueItem]>]) -> Dictionary<Key, [ValueItem]> {
    var result = Dictionary<Key, [ValueItem]>()
    for dict in dictionaries {
        result.merge(dict, uniquingKeysWith: { $0 + $1 })
    }
    return result
}

final class ObjcNamespaceHandler: NamespaceHandler {
    private let classNamePrefix: String
    
    init(urlParams: [URLQueryItem]?) {
        var modulePrefix = ""
        if let module = urlParams?.first(where: { $0.name == "module" })?.value {
            modulePrefix = module + "."
        }

        self.classNamePrefix = modulePrefix + (urlParams?.first(where: { $0.name == "prefix" })?.value ?? "")
    }
    
    private let classExtensionIndex = ClassExtensionIndex(extensionsByClassName: mergeMutilDictionary([
        ColorExtensions,
        ViewExtentions,
        NSButtonExtentions,
        ControlExtensions,
        LayoutConstraintExtensions
    ]))
    
    private func getClassOrThrow(named className: String) throws -> NSObject.Type {
        if let theClass = NSClassFromString(className) as? NSObject.Type {
            return theClass
        }
        
        throw Compiler.Error.noSuchClassName(className)
    }
    
    func contextCreator() -> ContextCreator {
        return { _ in nil }
    }
    
    func objectConstructor(ofClass className: String, propertyNames: Set<String>) throws -> (ObjectConstructor, propertyNamesForConstructor: Set<String>) {
        let className = classNamePrefix + className
        
        let constructors = classExtensionIndex.constructors[className] ?? []
        
        if !constructors.isEmpty {
            for constructor in constructors {
                if !constructor.requiredArguments.contains(where: { !propertyNames.contains($0) }) {
                    return ({ _, args in
                        try constructor.function(args)
                    }, constructor.requiredArguments.union(constructor.optionalArguments))
                }
            }
            throw Compiler.Error.noSuitableConstructorForClass(className, propertyNames: propertyNames)
        }
        let theClass = try getClassOrThrow(named: className) //as! NSObject.Type
        return ({ _, _ in
            return theClass.init()
        },[])
    }
    
    func object(ofClass className: String, literal: String) throws -> Object {
        
        if className == NSString.className() || className == NSMutableString.className() {
            return literal
        }
        if let literalConvertor = literalConvertors[className], let value = literalConvertor(literal) {
            return value
        }
        
        if let literalConvertor = classExtensionIndex.literalConvertors[className] {
            return try literalConvertor(literal)
        }
        
        throw Compiler.Error.invalidLiteral(literal, className: className)
    }
    
    func type(ofProperty propertyName: String, inClass className: String) throws -> PropertyType {
        let className = classNamePrefix + className
        
        let pathKeys = propertyName.split(separator: ".")
        var currentTypeName = className
        for key in pathKeys {
            let keyString = String(key)
            
            if let propertyType = classExtensionIndex.propertyType(name: keyString, inClass: currentTypeName) {
                switch propertyType {
                case .array:
                    currentTypeName = NSArray.className()
                case .singleValue(let className):
                    currentTypeName = className
                }
            }
            else {
                guard let propertyTypeName = currentTypeName.typeString(ofProperty: keyString) else {
                    throw Compiler.Error.propertyNotFound(name: propertyName, className: className)
                }
                currentTypeName = propertyTypeName
            }
        }
        
        if currentTypeName == NSArray.className() {
            return .array(elementClassName: nil)
        }
        
        return .singleValue(className: currentTypeName)
        
    }
    
    func propertySetter(ofProperty propertyName: String, inClass className: String) -> PropertySetterFunction {
        let className = classNamePrefix + className
        
        if let setter = classExtensionIndex.propertySetter(propertyName, inClass: className) {
            return setter
        }
        
        return { (_, target, propertyValue) in
            (target as! NSObject).setValue(propertyValue, forKeyPath: propertyName)
        }
    }
    
    func property(_ lp: String, mustBeAssignedBeforeProperty rp: String) -> Bool {
        if lp == #keyPath(NSView.wantsLayer) && rp.hasPrefix("layer.") {
            return true
        }
        return false
    }
    
    func contentPropertyName(ofClass className: String) throws -> String? {
        let className = classNamePrefix + className

        if let contentPropertyName = classExtensionIndex.contentPropertyName(ofClass: className) {
            return contentPropertyName
        }
        return nil
    }
    
    func objectConstructedCallback(forClass className: String) -> ObjectLifecycleCallback? {
        return nil
    }
    
    func objectBuiltCallback(forClass className: String) -> ObjectLifecycleCallback? {
        return nil
    }
}
